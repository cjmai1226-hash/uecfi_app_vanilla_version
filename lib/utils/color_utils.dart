import 'package:flutter/material.dart';

class ColorUtils {
  static const List<Color> avatarColors = [
    Color(0xFF4285F4), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFFBBC05), // Google Yellow
    Color(0xFFEA4335), // Google Red
    Color(0xFF673AB7), // Deep Purple
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF009688), // Teal
    Color(0xFF3F51B5), // Indigo
    Color(0xFFE91E63), // Pink
  ];

  static Color getAvatarColor(String name) {
    if (name.isEmpty) return const Color(0xFF9E9E9E); // Grey
    final int hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return avatarColors[hash % avatarColors.length];
  }
}
