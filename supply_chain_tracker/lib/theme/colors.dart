import 'package:flutter/material.dart';

// Simple color constants for the app
class AppColors {
  // Brand colors
  static const Color unfiGreen = Color(0xFF6DB144);
  static const Color sunriseOrange = Color(0xFFFF8C42);
  static const Color goldenHarvest = Color(0xFFD4A574);

  // Status colors
  static const Color statusInTransit = Color(0xFFE67E22);
  static const Color statusAtDC = Color(0xFF6DB144);
  static const Color statusAtDock = Color(0xFF5DADE2);
  static const Color statusDelivered = Color(0xFF52BE80);

  // Card colors
  static const Color darkCard = Color(0xFF234D2A);
  static const Color darkCardElevated = Color(0xFF2D5A35);
  static const Color lightCard = Color(0xFFFAF8F3);

  // Border colors
  static const Color darkBorder = Color(0xFF3D5A42);
  static const Color lightBorder = Color(0xFFD4C9B8);

  // Text colors
  static const Color darkTextSecondary = Color(0xFFB8B5A8);
  static const Color lightTextSecondary = Color(0xFF6B7055);

  // Metric change indicators (work in both light and dark mode)
  static const Color positiveChange = Color(0xFF10B981); // Bright green
  static const Color negativeChange = Color(0xFFEF4444); // Bright red

  // Risk level indicators (high contrast for light mode, visible in dark mode)
  static const Color riskLow = Color(0xFF10B981); // Bright green
  static const Color riskMedium = Color(0xFFF59E0B); // Bright amber
  static const Color riskHigh = Color(0xFFEF4444); // Bright red
  static const Color riskDefault = Color(0xFF6B7280); // Medium gray

  // Gradients
  static LinearGradient get sunriseGradient => const LinearGradient(
        colors: [Color(0xFFFF8C42), Color(0xFFFFB366)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get forestGradient => const LinearGradient(
        colors: [Color(0xFF6DB144), Color(0xFF4A9132)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration leafBadge({Color? color}) => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color ?? unfiGreen,
            (color ?? unfiGreen).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (color ?? unfiGreen).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
