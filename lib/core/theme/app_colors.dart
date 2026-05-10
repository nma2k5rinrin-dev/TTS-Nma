import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - deep navy dark theme like reference
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF1C2333);
  static const Color surfaceCard = Color(0xFF21283B);
  static const Color surfaceBorder = Color(0xFF30363D);

  // Accent colors
  static const Color primary = Color(0xFF4A90FF);
  static const Color primaryLight = Color(0xFF6CA6FF);
  static const Color primaryDark = Color(0xFF2E6FDB);

  // Feature colors
  static const Color ttsGreen = Color(0xFF2EA043);
  static const Color ttsGreenLight = Color(0xFF3FB950);
  static const Color cloneOrange = Color(0xFFE3832D);
  static const Color cloneOrangeLight = Color(0xFFF0A04B);
  static const Color sttPurple = Color(0xFF8B5CF6);
  static const Color sttPurpleLight = Color(0xFFA78BFA);

  // Status colors
  static const Color success = Color(0xFF2EA043);
  static const Color warning = Color(0xFFE3B341);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Text colors
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);
  static const Color textLink = Color(0xFF58A6FF);

  // Credit/coin color
  static const Color coinGold = Color(0xFFFFD700);
  static const Color coinGoldLight = Color(0xFFFFE44D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A90FF), Color(0xFF6C5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ttsGradient = LinearGradient(
    colors: [Color(0xFF2EA043), Color(0xFF40C463)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cloneGradient = LinearGradient(
    colors: [Color(0xFFE3832D), Color(0xFFF0A04B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sttGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
