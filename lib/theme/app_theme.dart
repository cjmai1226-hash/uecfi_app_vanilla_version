import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextStyle _getFontStyle(
    String fontStyle, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final style = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
    switch (fontStyle) {
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: style);
      case 'Open Sans':
        return GoogleFonts.openSans(textStyle: style);
      case 'System':
        return style;
      case 'Inter':
      default:
        return GoogleFonts.inter(textStyle: style);
    }
  }

  static TextTheme _getTextTheme(String fontStyle, TextTheme baseTheme) {
    switch (fontStyle) {
      case 'Roboto':
        return GoogleFonts.robotoTextTheme(baseTheme);
      case 'Open Sans':
        return GoogleFonts.openSansTextTheme(baseTheme);
      case 'System':
        return baseTheme;
      case 'Inter':
      default:
        return GoogleFonts.interTextTheme(baseTheme);
    }
  }

  static ThemeData themeData({
    bool isDarkMode = false,
    Color seedColor = Colors.blueAccent,
    String fontStyle = 'Inter',
  }) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    final backgroundColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);
    final surfaceColor = isDarkMode ? Colors.black : Colors.white;
    final onSurfaceColor = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black87;

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        brightness: brightness,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
      ),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: _getFontStyle(
          fontStyle,
          color: onSurfaceColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: IconThemeData(color: seedColor),
        unselectedIconTheme: IconThemeData(color: iconColor),
        selectedLabelTextStyle: _getFontStyle(
          fontStyle,
          color: seedColor,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: _getFontStyle(fontStyle, color: iconColor),
        indicatorColor: seedColor.withValues(alpha: 0.1),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: seedColor.withValues(alpha: 0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: seedColor);
          }
          return IconThemeData(color: iconColor);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _getFontStyle(
              fontStyle,
              color: seedColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return _getFontStyle(fontStyle, color: iconColor, fontSize: 12);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: surfaceColor,
        foregroundColor: seedColor,
        elevation: 2,
      ),
      textTheme: _getTextTheme(fontStyle, baseTheme.textTheme),
    );
  }
}
