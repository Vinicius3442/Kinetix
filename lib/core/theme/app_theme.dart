import 'package:flutter/material.dart';

import 'tokens.dart';

const kxSans = 'PlusJakartaSans';
const kxMono = 'JetBrainsMono';

/// Tipografia híbrida: Plus Jakarta Sans (interface) + JetBrains Mono (dados).
abstract final class KxText {
  static TextStyle get h1 => const TextStyle(fontFamily: kxSans, fontSize: 28, fontWeight: FontWeight.w700, color: KxColors.textDisplay, height: 1.15);
  static TextStyle get h2 => const TextStyle(fontFamily: kxSans, fontSize: 20, fontWeight: FontWeight.w600, color: KxColors.textSection, height: 1.25);
  static TextStyle get h3 => const TextStyle(fontFamily: kxSans, fontSize: 16, fontWeight: FontWeight.w600, color: KxColors.textDisplay, height: 1.3);
  static TextStyle get body => const TextStyle(fontFamily: kxSans, fontSize: 14, fontWeight: FontWeight.w400, color: KxColors.textBody, height: 1.45);
  static TextStyle get label => const TextStyle(fontFamily: kxSans, fontSize: 12, fontWeight: FontWeight.w600, color: KxColors.textBody, letterSpacing: 0.6);

  static TextStyle metric([Color color = KxColors.cyberCyan]) =>
      TextStyle(fontFamily: kxMono, fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.1);
  static TextStyle get unit => const TextStyle(fontFamily: kxMono, fontSize: 12, color: KxColors.textBody);
  static TextStyle get log => const TextStyle(fontFamily: kxMono, fontSize: 12, color: KxColors.textLog);
}

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true, fontFamily: kxSans);
  final text = base.textTheme.apply(fontFamily: kxSans).apply(
    bodyColor: KxColors.textSection,
    displayColor: KxColors.textDisplay,
  );
  const scheme = ColorScheme.dark(
    primary: KxColors.talpaLava,
    onPrimary: Colors.white,
    secondary: KxColors.cyberCyan,
    onSecondary: KxColors.obsidianPitch,
    surface: KxColors.charcoalSolid,
    onSurface: KxColors.textSection,
    error: KxColors.talpaLava,
    outline: KxColors.borderSlate,
    outlineVariant: KxColors.borderSlate,
  );
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(KxRadius.input),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: KxColors.obsidianPitch,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: KxColors.obsidianPitch,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: KxText.h3.copyWith(fontSize: 18),
    ),
    dividerTheme: const DividerThemeData(color: KxColors.borderSlate, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KxColors.charcoalGlass,
      labelStyle: KxText.body,
      floatingLabelStyle: KxText.body.copyWith(color: KxColors.cyberCyan),
      hintStyle: KxText.body.copyWith(color: KxColors.textLog),
      helperStyle: KxText.log,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(KxColors.borderSlate),
      enabledBorder: border(KxColors.borderSlate),
      focusedBorder: border(KxColors.cyberCyan, 1.5),
      errorBorder: border(KxColors.talpaLava),
      focusedErrorBorder: border(KxColors.talpaLava, 1.5),
      errorStyle: KxText.body.copyWith(color: KxColors.talpaLava, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KxColors.talpaLava,
        foregroundColor: Colors.white,
        disabledBackgroundColor: KxColors.borderSlate,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KxRadius.input)),
        textStyle: const TextStyle(fontFamily: kxSans, fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KxColors.textDisplay,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: KxColors.borderSlate),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KxRadius.input)),
        textStyle: const TextStyle(fontFamily: kxSans, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KxColors.cyberCyan,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontFamily: kxSans, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KxColors.charcoalSolid,
      indicatorColor: KxColors.cyberCyan.withValues(alpha: 0.14),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontFamily: kxSans, 
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? KxColors.cyberCyan : KxColors.textBody,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? KxColors.cyberCyan : KxColors.textBody,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: KxColors.charcoalSolid,
      indicatorColor: KxColors.cyberCyan.withValues(alpha: 0.14),
      selectedIconTheme: const IconThemeData(color: KxColors.cyberCyan),
      unselectedIconTheme: const IconThemeData(color: KxColors.textBody),
      selectedLabelTextStyle: const TextStyle(fontFamily: kxSans, fontSize: 12, fontWeight: FontWeight.w700, color: KxColors.cyberCyan),
      unselectedLabelTextStyle: const TextStyle(fontFamily: kxSans, fontSize: 12, color: KxColors.textBody),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KxColors.charcoalSolid,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KxColors.charcoalSolid,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KxColors.borderSlate),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: KxColors.charcoalGlass,
      contentTextStyle: KxText.body.copyWith(color: KxColors.textDisplay),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KxRadius.input),
        side: const BorderSide(color: KxColors.borderSlate),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: KxColors.charcoalGlass,
      selectedColor: KxColors.cyberCyan.withValues(alpha: 0.16),
      side: const BorderSide(color: KxColors.borderSlate),
      labelStyle: KxText.body.copyWith(color: KxColors.textSection),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KxRadius.chip)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: KxColors.cyberCyan,
      unselectedLabelColor: KxColors.textBody,
      indicatorColor: KxColors.cyberCyan,
      dividerColor: KxColors.borderSlate,
      labelStyle: TextStyle(fontFamily: kxSans, fontWeight: FontWeight.w700, fontSize: 14),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: KxColors.cyberCyan),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: KxColors.charcoalSolid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KxColors.borderSlate),
      ),
      textStyle: KxText.body.copyWith(color: KxColors.textDisplay, fontSize: 12),
    ),
  );
}
