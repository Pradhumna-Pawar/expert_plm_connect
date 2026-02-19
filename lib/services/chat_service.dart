import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser!.uid;

  // ── Deterministic chat ID — same for both participants ──
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ── Create or fetch a chat document ──
  Future<String> getOrCreateChat({
    required String otherUid,
    required String otherName,
    required String otherRole,
    required String myName,
    required String myRole,
  }) async {
    final chatId = getChatId(_currentUid, otherUid);
    final chatRef = _db.collection('chats').doc(chatId);
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'participants': [_currentUid, otherUid],
        'participantNames': {
          _currentUid: myName,
          otherUid: otherName,
        },
        'participantRoles': {
          _currentUid: myRole,
          otherUid: otherRole,
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {_currentUid: 0, otherUid: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  // ── Send a message ──
  Future<void> sendMessage(String chatId, String text) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    // Get other participant uid
    final chatDoc = await chatRef.get();
    final data = chatDoc.data()!;
    final participants = List<String>.from(data['participants'] as List);
    final otherUid = participants.firstWhere((uid) => uid != _currentUid);

    final batch = _db.batch();

    // Add message
    final msgRef = messagesRef.doc();
    batch.set(msgRef, {
      'senderId': _currentUid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update chat preview
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.$otherUid': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ── Stream of messages for a chat ──
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ChatMessage.fromDoc(doc)).toList());
  }

  // ── Mark messages as read ──
  Future<void> markAsRead(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCount.$_currentUid': 0,
    });
  }

  // ── Stream of chat previews for the current user ──
  Stream<List<ChatPreview>> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _currentUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] as List);
        final otherUid =
            participants.firstWhere((uid) => uid != _currentUid);
        final names =
            Map<String, dynamic>.from(data['participantNames'] as Map);
        final roles =
            Map<String, dynamic>.from(data['participantRoles'] as Map);
        final unread =
            Map<String, dynamic>.from(data['unreadCount'] as Map);

        return ChatPreview(
          chatId: doc.id,
          otherUserId: otherUid,
          otherUserName: names[otherUid] as String? ?? 'Unknown',
          otherUserRole: roles[otherUid] as String? ?? '',
          lastMessage: data['lastMessage'] as String? ?? '',
          lastMessageTime:
              (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
          unreadCount: unread[_currentUid] as int? ?? 0,
        );
      }).toList();
    });
  }

  // ── Get all users the current user can chat with ──
  Future<List<Map<String, dynamic>>> getDiscoverableUsers(
      String currentRole) async {
    // Return users of the opposite role
    final targetRole =
        currentRole == 'jobseeker' ? 'recruiter' : 'jobseeker';
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: targetRole)
        .limit(30)
        .get();
    return snap.docs
        .map((d) => {'uid': d.id, ...d.data()})
        .toList();
  }

  // ── Save user profile to Firestore (call after login) ──
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? company,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      if (company != null) 'company': company,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
