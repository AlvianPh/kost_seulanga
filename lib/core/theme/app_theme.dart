import 'package:flutter/material.dart';

extension StatusColorsExtension on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>() ?? AppTheme.statusColors;
}

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color active;
  final Color upcomingDue;
  final Color overdue;
  final Color inactive;

  const StatusColors({
    required this.active,
    required this.upcomingDue,
    required this.overdue,
    required this.inactive,
  });

  @override
  StatusColors copyWith({
    Color? active,
    Color? upcomingDue,
    Color? overdue,
    Color? inactive,
  }) {
    return StatusColors(
      active: active ?? this.active,
      upcomingDue: upcomingDue ?? this.upcomingDue,
      overdue: overdue ?? this.overdue,
      inactive: inactive ?? this.inactive,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      active: Color.lerp(active, other.active, t)!,
      upcomingDue: Color.lerp(upcomingDue, other.upcomingDue, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
    );
  }
}

class AppTheme {
  static const Color _seedColor = Color(0xFF0F766E);

  static const statusColors = StatusColors(
    active: Color(0xFF0D9488),      // Teal-green (Paid / Available / Active)
    upcomingDue: Color(0xFFD97706), // Amber (Upcoming Due)
    overdue: Color(0xFFDC2626),     // Crimson Red (Overdue)
    inactive: Color(0xFF64748B),    // Slate Gray (Inactive)
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      extensions: const [
        statusColors,
      ],
    );
  }
}

