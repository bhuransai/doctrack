import 'package:flutter/material.dart';
import '../models/document.dart';

/// Rounded icon tile used on document cards, reminder rows and the detail
/// header — tinted with the document's status colour.
class DocIconTile extends StatelessWidget {
  final DocType type;
  final Color tint;
  final Color strong;
  final double size;
  final double iconSize;
  final double radius;

  const DocIconTile({
    super.key,
    required this.type,
    required this.tint,
    required this.strong,
    this.size = 42,
    this.iconSize = 21,
    this.radius = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(type.icon, color: strong, size: iconSize),
    );
  }
}
