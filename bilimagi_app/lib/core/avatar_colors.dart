import 'package:flutter/material.dart';
import 'theme.dart';

/// Consistent avatar color palette based on user ID
const List<Color> avatarColors = [
  AppTheme.primaryColor,
  AppTheme.secondaryColor,
  Color(0xFF9B59B6), // Purple
  Color(0xFF3498DB), // Blue
  Color(0xFFE74C3C), // Red
  Color(0xFF2ECC71), // Green
  Color(0xFFF39C12), // Orange
  Color(0xFF1ABC9C), // Turquoise
];

/// Get a consistent avatar color based on user ID
Color getAvatarColor(String uid) {
  return avatarColors[uid.hashCode.abs() % avatarColors.length];
}

/// Get avatar color index for a user ID
int getAvatarColorIndex(String uid) {
  return uid.hashCode.abs() % avatarColors.length;
}
