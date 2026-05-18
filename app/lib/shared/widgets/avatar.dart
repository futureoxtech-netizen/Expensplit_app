import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.imageUrl, this.size = 40});

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final color = _colorFromName(name);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  static Color _colorFromName(String name) {
    const palette = [
      AppColors.primary,
      AppColors.accent,
      Color(0xFFFF9F43),
      Color(0xFFE17055),
      Color(0xFF74B9FF),
      Color(0xFF55EFC4),
      Color(0xFFFD79A8),
      Color(0xFFA29BFE),
    ];
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}
