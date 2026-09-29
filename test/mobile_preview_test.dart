import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:outfit/providers/wardrobe_provider.dart';
import 'package:outfit/services/avatar_preferences.dart';
import 'package:outfit/theme/theme_preferences.dart';
import 'package:outfit/ui/screens/dashboard_screen.dart';

void main() {
  testWidgets('Render actual mobile screens for review', (tester) async {
    final output = Platform.environment['STYLO_REVIEW_DIR'];
    if (output == null) return;
    await tester.runAsync(() async {
      final loader = FontLoader('ReviewFont');
      loader.addFont(
        File(
          'C:/Windows/Fonts/segoeui.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          'D:/Flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        ).readAsBytes().then(ByteData.sublistView),
      );
      await icons.load();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final theme in [StyleTheme.dark, StyleTheme.rose]) {
      AvatarPreferences.selectedProfile.value = theme == StyleTheme.rose
          ? 'Feminin'
          : 'Masculin';
      final key = GlobalKey();
      final base = ThemePreferences.data(theme);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: WardrobeProvider(),
          child: MaterialApp(
            theme: base.copyWith(
              textTheme: base.textTheme.apply(fontFamily: 'ReviewFont'),
            ),
            home: RepaintBoundary(key: key, child: const DashboardScreen()),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = key.currentContext!;
        await precacheImage(
          AssetImage(
            theme == StyleTheme.rose
                ? 'assets/images/hero_mannequin_female_v1.png'
                : 'assets/images/hero_mannequin_v1.png',
          ),
          context,
        );
        await precacheImage(
          const AssetImage('assets/images/stylo_icon.png'),
          context,
        );
      });
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await File(
          '$output/stylo-mobile-${theme.name}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
  });
}
