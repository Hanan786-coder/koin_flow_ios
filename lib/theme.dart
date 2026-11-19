import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Koin Flow — "Brass ledger" palette.
/// Banker's-green leather, brass coins, parchment pages.
class K {
  K._();

  static const ledger = Color(0xFF0C1A16); // app background
  static const felt = Color(0xFF13261F); // cards
  static const feltHigh = Color(0xFF1B3229); // inputs, raised
  static const seam = Color(0xFF26443A); // hairlines, tracks
  static const brass = Color(0xFFE8B95A); // brand + primary action
  static const brassDeep = Color(0xFF3A2A06); // text on brass
  static const parchment = Color(0xFFF1EADA); // primary text
  static const sage = Color(0xFF9DB3A8); // secondary text
  static const mint = Color(0xFF84E2B8); // money in / healthy
  static const rose = Color(0xFFF2848F); // money out / over budget

  static const rHero = 30.0;
  static const rCard = 22.0;
  static const rTile = 18.0;
  static const rInput = 16.0;

  static const categories = [
    'Food',
    'Transport',
    'Home',
    'Shopping',
    'Health',
    'Bills',
    'Other',
  ];

  static Color categoryColor(String category) => switch (category) {
    'Food' => const Color(0xFFE8B95A),
    'Transport' => const Color(0xFF8FC7E8),
    'Home' => const Color(0xFF84E2B8),
    'Shopping' => const Color(0xFFF2848F),
    'Health' => const Color(0xFFC6A8F0),
    'Bills' => const Color(0xFFF0A86B),
    _ => const Color(0xFF9DB3A8),
  };

  static IconData categoryIcon(String category) => switch (category) {
    'Food' => Icons.restaurant_rounded,
    'Transport' => Icons.directions_car_filled_rounded,
    'Home' => Icons.cottage_rounded,
    'Shopping' => Icons.shopping_bag_rounded,
    'Health' => Icons.favorite_rounded,
    'Bills' => Icons.receipt_long_rounded,
    _ => Icons.blur_on_rounded,
  };

  /// Display face — headings and every amount.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = parchment,
    double? height,
    double spacing = -0.4,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Body face.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = parchment,
    double? height,
  }) => GoogleFonts.figtree(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static Duration motion(BuildContext context, int ms) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true
      ? Duration.zero
      : Duration(milliseconds: ms);

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    final text = GoogleFonts.figtreeTextTheme(base.textTheme)
        .apply(bodyColor: parchment, displayColor: parchment);
    return base.copyWith(
      // iOS scrolling, page transitions and text behaviour everywhere,
      // so the preview behaves like the phone.
      platform: TargetPlatform.iOS,
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: brass,
        scaffoldBackgroundColor: ledger,
        barBackgroundColor: ledger,
      ),
      scaffoldBackgroundColor: ledger,
      canvasColor: ledger,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        surface: ledger,
        surfaceContainerHigh: feltHigh,
        primary: brass,
        onPrimary: brassDeep,
        secondary: mint,
        tertiary: brass,
        error: rose,
        onSurface: parchment,
        onSurfaceVariant: sage,
        outline: seam,
      ),
      textTheme: text,
      dialogTheme: DialogThemeData(
        backgroundColor: felt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
        ),
        titleTextStyle: display(21, spacing: -0.3),
        contentTextStyle: body(15, color: sage, height: 1.45),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: felt,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: seam,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(rHero)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: felt,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: feltHigh,
        headerForegroundColor: parchment,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brass,
          foregroundColor: brassDeep,
          minimumSize: const Size.fromHeight(54),
          textStyle: body(16, weight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rInput),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brass,
          textStyle: body(14, weight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brassDeep : sage,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brass : feltHigh,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: brass,
        inactiveTrackColor: seam,
        thumbColor: brass,
        overlayColor: Color(0x22E8B95A),
        trackHeight: 6,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: brass,
        selectionColor: Color(0x55E8B95A),
        selectionHandleColor: brass,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: feltHigh,
        hintStyle: body(15, color: sage.withValues(alpha: .7)),
        labelStyle: body(15, color: sage),
        floatingLabelStyle: body(14, color: brass, weight: FontWeight.w600),
        prefixIconColor: sage,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rInput),
          borderSide: const BorderSide(color: brass, width: 1.4),
        ),
      ),
    );
  }
}
