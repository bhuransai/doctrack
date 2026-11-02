import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final int count;
  final String label;
  final Color fg;
  final Color bg;
  final Color line;
  final VoidCallback? onTap;
  final bool active;

  const SummaryCard({
    super.key,
    required this.count,
    required this.label,
    required this.fg,
    required this.bg,
    required this.line,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: active ? fg : line, width: active ? 1.6 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$count', style: AppText.mono(size: 19, weight: FontWeight.w700, color: fg)),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppText.sans(size: 10, weight: FontWeight.w600, color: fg, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
