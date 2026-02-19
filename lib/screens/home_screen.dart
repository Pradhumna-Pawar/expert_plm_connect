import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../services/chat_service.dart';
import 'chat_list_screen.dart';

class JobSeekerHomeScreen extends StatefulWidget {
  final String userName;
  const JobSeekerHomeScreen({super.key, required this.userName});

  @override
  State<JobSeekerHomeScreen> createState() => _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends State<JobSeekerHomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _PlaceholderTab(
        icon: Icons.work_outline_rounded,
        label: 'Jobs',
        color: AppColors.primary,
      ),
      ChatListScreen(
        currentUserName: widget.userName,
        currentUserRole: 'jobseeker',
      ),
      _PlaceholderTab(
        icon: Icons.description_outlined,
        label: 'Applied',
        color: AppColors.primary,
      ),
      _ProfileTab(userName: widget.userName),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          _NavItem(icon: Icons.work_outline_rounded, label: 'Jobs'),
          _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
          _NavItem(icon: Icons.description_outlined, label: 'Applied'),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
        accentColor: AppColors.primary,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Recruiter Home
// ─────────────────────────────────────────────
class RecruiterHomeScreen extends StatefulWidget {
  final String userName;
  const RecruiterHomeScreen({super.key, required this.userName});

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen> {
  int _selectedIndex = 0;
  static const _recruiterAccent = Color(0xFF5B9BD5);

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _PlaceholderTab(
        icon: Icons.people_outline_rounded,
        label: 'Candidates',
        color: _recruiterAccent,
      ),
      ChatListScreen(
        currentUserName: widget.userName,
        currentUserRole: 'recruiter',
      ),
      _PlaceholderTab(
        icon: Icons.view_kanban_outlined,
        label: 'Pipeline',
        color: _recruiterAccent,
      ),
      _ProfileTab(userName: widget.userName),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          _NavItem(icon: Icons.people_outline_rounded, label: 'Candidates'),
          _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
          _NavItem(icon: Icons.view_kanban_outlined, label: 'Pipeline'),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
        accentColor: _recruiterAccent,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared bottom nav
// ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  final Color accentColor;
  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? accentColor : AppColors.textHint,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? accentColor : AppColors.textHint,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Placeholder tabs
// ─────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PlaceholderTab(
      {required this.icon, required this.label, required this.color});

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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coming soon',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile tab
// ─────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String userName;
  const _ProfileTab({required this.userName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (route) => false);
                }
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE74C3C).withValues(alpha: 0.4)),
                ),
                child: const Center(
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
