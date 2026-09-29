import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum StyleTheme { dark, light, vibrant, rose }

class ThemePreferences {
  static final selected = ValueNotifier<StyleTheme>(StyleTheme.dark);
  static late Box _box;
  static Future<void> init() async {
    _box = await Hive.openBox('style_theme');
    final name = _box.get('theme');
    selected.value = StyleTheme.values.firstWhere(
      (t) => t.name == name,
      orElse: () => StyleTheme.dark,
    );
  }

  static Future<void> setTheme(StyleTheme theme) async {
    final previous = selected.value;
    selected.value = theme;
    try {
      await _box.put('theme', theme.name);
    } catch (_) {
      selected.value = previous;
      rethrow;
    }
  }

  static ThemeData data(StyleTheme theme) {
    final rose = theme == StyleTheme.rose;
    final light = theme == StyleTheme.light || rose;
    final vibrant = theme == StyleTheme.vibrant;
    final background = Color(
      rose
          ? 0xFFFFF0F5
          : light
          ? 0xFFF4F0EA
          : vibrant
          ? 0xFF180E2C
          : 0xFF080A10,
    );
    final surface = Color(
      rose
          ? 0xFFFFFAFC
          : light
          ? 0xFFFFFCF7
          : vibrant
          ? 0xFF291B42
          : 0xFF151923,
    );
    final accent = Color(
      rose
          ? 0xFFA82D60
          : light
          ? 0xFFAE402C
          : vibrant
          ? 0xFFDFADFF
          : 0xFFFF8B75,
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: light ? Brightness.light : Brightness.dark,
    ).copyWith(primary: accent, surface: surface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
