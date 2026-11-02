import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DocTrackBottomBar extends StatelessWidget {
  final int currentIndex; // 0 = Documents, 1 = Reminders, 2 = Vault, 3 = You
  final int reminderCount;
  final VoidCallback onHome;
  final VoidCallback onReminders;
  final VoidCallback onVault;
  final VoidCallback onYou;
  final VoidCallback onAdd;

  const DocTrackBottomBar({
    super.key,
    required this.currentIndex,
    required this.reminderCount,
    required this.onHome,
    required this.onReminders,
    required this.onVault,
    required this.onYou,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final homeColor = currentIndex == 0 ? AppColors.ink : AppColors.textDisabled;
    final remindersColor = currentIndex == 1 ? AppColors.ink : AppColors.textDisabled;
    final vaultColor = currentIndex == 2 ? AppColors.ink : AppColors.textDisabled;
    final youColor = currentIndex == 3 ? AppColors.ink : AppColors.textDisabled;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: AppColors.navBarBg,
            border: Border(top: BorderSide(color: AppColors.borderCard)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _NavItem(icon: Icons.description_outlined, label: 'Documents', color: homeColor, onTap: onHome),
              _NavItem(
                icon: Icons.notifications_none_rounded,
                label: 'Reminders',
                color: remindersColor,
                onTap: onReminders,
                badgeCount: reminderCount,
              ),
              _AddButton(onTap: onAdd),
              _NavItem(icon: Icons.folder_outlined, label: 'Vault', color: vaultColor, onTap: onVault),
              _NavItem(icon: Icons.person_outline_rounded, label: 'You', color: youColor, onTap: onYou),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(color: AppColors.badgeRed, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: AppText.mono(size: 9.5, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: AppText.sans(size: 9.5, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -22),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.inkStrong,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0x42101728), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
