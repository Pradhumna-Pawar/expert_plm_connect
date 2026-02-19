import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserName;
  final String currentUserRole; // 'jobseeker' or 'recruiter'

  const ChatListScreen({
    super.key,
    required this.currentUserName,
    required this.currentUserRole,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  String _activeFilter = 'All';
  String _searchQuery = '';

  final _filters = ['All', 'Unread', 'Recruiters', 'Archived'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.day}/${time.month}';
  }

  List<ChatPreview> _applyFilters(List<ChatPreview> chats) {
    var filtered = chats;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.otherUserName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_activeFilter == 'Unread') {
      filtered = filtered.where((c) => c.unreadCount > 0).toList();
    } else if (_activeFilter == 'Recruiters') {
      filtered =
          filtered.where((c) => c.otherUserRole == 'recruiter').toList();
    }

    return filtered;
  }

  Future<void> _showNewChatDialog() async {
    try {
      final users = await _chatService
          .getDiscoverableUsers(widget.currentUserRole);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _NewChatSheet(
          users: users,
          onUserSelected: (user) async {
            Navigator.pop(context);
            final chatId = await _chatService.getOrCreateChat(
              otherUid: user['uid'] as String,
              otherName: user['name'] as String,
              otherRole: user['role'] as String,
              myName: widget.currentUserName,
              myRole: widget.currentUserRole,
            );
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  chatId: chatId,
                  otherUserName: user['name'] as String,
                  otherUserRole: user['role'] as String,
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load users: $e'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showNewChatDialog,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_square,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search contacts or companies',
                  hintStyle: const TextStyle(
                      color: AppColors.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textHint, size: 20),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filters ──
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final filter = _filters[i];
                  final isActive = filter == _activeFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _activeFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── Chat List ──
            Expanded(
              child: StreamBuilder<List<ChatPreview>>(
                stream: _chatService.getUserChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    );
                  }

                  final chats = _applyFilters(snapshot.data ?? []);

                  if (chats.isEmpty) {
                    return _EmptyState(
                      onNewChat: _showNewChatDialog,
                      role: widget.currentUserRole,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chats.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                      indent: 80,
                    ),
                    itemBuilder: (_, i) => _ChatTile(
                      chat: chats[i],
                      timeLabel: _formatTime(chats[i].lastMessageTime),
                      onTap: () {
                        _chatService.markAsRead(chats[i].chatId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: chats[i].chatId,
                              otherUserName: chats[i].otherUserName,
                              otherUserRole: chats[i].otherUserRole,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Chat tile
// ─────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final ChatPreview chat;
  final String timeLabel;
  final VoidCallback onTap;
  const _ChatTile(
      {required this.chat, required this.timeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.cardBackground,
                  child: Text(
                    chat.otherUserName.isNotEmpty
                        ? chat.otherUserName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: chat.otherUserRole == 'recruiter'
                          ? const Color(0xFF5B9BD5)
                          : AppColors.primary,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.scaffoldBackground, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.otherUserName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage.isEmpty
                              ? 'Say hello! 👋'
                              : chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  final String role;
  const _EmptyState({required this.onNewChat, required this.role});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('No conversations yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            role == 'jobseeker'
                ? 'Connect with recruiters to get started'
                : 'Reach out to job seekers to get started',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onNewChat,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Start a conversation',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// New chat bottom sheet
// ─────────────────────────────────────────────
class _NewChatSheet extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final void Function(Map<String, dynamic> user) onUserSelected;
  const _NewChatSheet({required this.users, required this.onUserSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Start New Chat',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(height: 8),
        if (users.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('No users available yet.',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final user = users[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.jobSeekerIconBg,
                  child: Text(
                    (user['name'] as String? ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user['name'] as String? ?? 'Unknown',
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                  user['role'] as String? ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () => onUserSelected(user),
              );
            },
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
