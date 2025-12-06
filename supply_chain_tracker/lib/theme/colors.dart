import 'package:flutter/material.dart';

// Databricks brand color palette
class AppColors {
  // Primary Colors
  static const Color lava600 = Color(0xFFFF3621); // Primary accent
  static const Color lava500 = Color(0xFFFF5F46); // Lighter lava
  static const Color navy800 = Color(0xFF1B3139); // Primary text/dark
  static const Color navy900 = Color(0xFF0B2026); // Darkest navy

  // Background Colors
  static const Color oatLight = Color(0xFFF9F7F4); // Light background
  static const Color oatMedium = Color(0xFFEEEDE9); // Medium background

  // Secondary Colors
  static const Color maroon600 = Color(0xFF98102A); // Alerts, warnings
  static const Color yellow600 = Color(0xFFFFAB00); // Warnings
  static const Color green600 = Color(0xFF00A972); // Positive/success
  static const Color blue600 = Color(0xFF2272B4); // Neutral/info

  // Legacy mappings for compatibility
  static const Color unfiGreen = green600;
  static const Color sunriseOrange = lava600;
  static const Color goldenHarvest = yellow600;

  // Status colors (using Databricks palette)
  static const Color statusInTransit = blue600; // Neutral - in progress
  static const Color statusAtDC = yellow600; // Warning - waiting
  static const Color statusAtDock = lava500; // Attention needed
  static const Color statusDelivered = green600; // Positive - completed

  // Card colors
  static const Color darkCard = navy800;
  static const Color darkCardElevated = Color(0xFF243D45); // Lighter navy
  static const Color lightCard = oatLight;

  // Border colors
  static const Color darkBorder = Color(0xFF3D5A62); // Navy-tinted border
  static const Color lightBorder = oatMedium;

  // Text colors
  static const Color darkTextPrimary = oatLight;
  static const Color darkTextSecondary = Color(0xFFB8C4C8); // Muted light
  static const Color lightTextPrimary = navy800;
  static const Color lightTextSecondary = Color(0xFF5A6B70); // Muted navy

  // Metric change indicators
  static const Color positiveChange = green600;
  static const Color negativeChange = lava600;

  // Risk level indicators
  static const Color riskLow = green600;
  static const Color riskMedium = yellow600;
  static const Color riskHigh = maroon600;
  static const Color riskDefault = Color(0xFF6B7280); // Medium gray

  // Gradients
  static LinearGradient get sunriseGradient => const LinearGradient(
        colors: [lava600, lava500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get forestGradient => const LinearGradient(
        colors: [green600, Color(0xFF008A5D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get navyGradient => const LinearGradient(
        colors: [navy800, navy900],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration leafBadge({Color? color}) => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color ?? green600,
            (color ?? green600).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (color ?? green600).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
