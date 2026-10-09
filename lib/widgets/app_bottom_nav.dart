import 'package:flutter/material.dart';

import '../History.dart';
import '../chatbot.dart';
import '../scan_page.dart';
import '../settings/settings_page.dart';
import '../theme/app_colors.dart';

enum NavTab { home, chatbot, scan, history, settings }

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.current,
    this.onHomeTap,
    this.onChatbotTap,
    this.onFrameTap,
    this.onHistoryTap,
    this.onSettingsTap,
  });

  final NavTab current;
  // Optional: if a page does not pass its own action, the default
  // navigation below (_goTo) is used for that tab.
  final VoidCallback? onHomeTap;
  final VoidCallback? onChatbotTap;
  final VoidCallback? onFrameTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onSettingsTap;

  /// Shared navigation for every page: go back to Home (the first page),
  /// then open the chosen tab on top of it. Back from any tab returns Home.
  void _goTo(BuildContext context, NavTab tab) {
    if (tab == current) return;
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    final Widget? page = switch (tab) {
      NavTab.home => null,
      NavTab.chatbot => const ChatbotScreen(),
      NavTab.scan => const ScanPage(),
      NavTab.history => const HistoryScreen(),
      NavTab.settings => const SettingsPage(),
    };
    if (page != null) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
          child: SizedBox(
            height: 60,
            child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  isSelected: current == NavTab.home,
                  onTap: onHomeTap ?? (() => _goTo(context, NavTab.home)),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.forum,
                  label: 'Chatbot',
                  isSelected: current == NavTab.chatbot,
                  onTap: onChatbotTap ?? (() => _goTo(context, NavTab.chatbot)),
                ),
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: onFrameTap ?? (() => _goTo(context, NavTab.scan)),
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/scan_button.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.history,
                  label: 'History',
                  isSelected: current == NavTab.history,
                  onTap: onHistoryTap ?? (() => _goTo(context, NavTab.history)),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: current == NavTab.settings,
                  onTap: onSettingsTap ?? (() => _goTo(context, NavTab.settings)),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.forest : AppColors.navInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27, color: color),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
