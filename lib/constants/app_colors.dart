import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const primary = Color(0xFF4F46E5);
  static const primaryColor = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const secondaryColor = Color(0xFF7C3AED);
  static const accentColor = Color(0xFF06B6D4);
  
  // Background Colors
  static const background = gray50;
  
  // Status Colors
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);
  static const infoColor = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
  
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  
  // Priority Colors
  static const priorityCritical = Color(0xFF9C27B0);
  static const priorityHigh = errorColor;
  static const priorityMedium = warningColor;
  static const priorityLow = successColor;
  static const priorityLowest = infoColor;
  
  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const infoGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}