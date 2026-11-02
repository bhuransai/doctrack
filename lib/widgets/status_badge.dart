import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final StatusPalette palette;
  final bool solid;

  const StatusBadge({super.key, required this.palette, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? palette.strong : palette.tint,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        palette.label,
        style: AppText.sans(
          size: 10,
          weight: FontWeight.w700,
          color: solid ? Colors.white : palette.fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
