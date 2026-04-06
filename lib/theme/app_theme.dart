import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color googleBlue = Color(0xFF1a73e8);

  static TextStyle _getFontStyle(
    String fontStyle, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    final style = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
    switch (fontStyle) {
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: style);
      case 'Open Sans':
        return GoogleFonts.openSans(textStyle: style);
      case 'System':
        return style;
      case 'Outfit':
      default:
        return GoogleFonts.outfit(textStyle: style);
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
      case 'Outfit':
      default:
        return GoogleFonts.outfitTextTheme(baseTheme);
    }
  }

  static ThemeData themeData({
    bool isDarkMode = false,
    Color seedColor = googleBlue,
    String fontStyle = 'Outfit',
  }) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final surfaceColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
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
        backgroundColor: backgroundColor,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: _getFontStyle(
          fontStyle,
          color: onSurfaceColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: backgroundColor,
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
        backgroundColor: backgroundColor,
        elevation: 0,
        indicatorColor: seedColor.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: seedColor, size: 28);
          }
          return IconThemeData(color: iconColor, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _getFontStyle(
              fontStyle,
              color: seedColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            );
          }
          return _getFontStyle(
            fontStyle,
            color: iconColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      textTheme: _getTextTheme(fontStyle, baseTheme.textTheme),
      dividerTheme: DividerThemeData(
        color: onSurfaceColor.withValues(alpha: 0.05),
        thickness: 1,
      ),
    );
  }
}
