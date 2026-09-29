import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:outfit/providers/wardrobe_provider.dart';
import 'package:outfit/screens/wardrobe_screen.dart';
import 'package:outfit/theme/theme_preferences.dart';

void main() {
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('stylo-theme-test-');
    Hive.init(storage.path);
    await ThemePreferences.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await storage.delete(recursive: true);
  });
  testWidgets('Compact wardrobe stays scrollable with keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: WardrobeProvider(),
        child: const MaterialApp(home: WardrobeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'test');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Wardrobe follows all themes on an already opened route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: WardrobeProvider(),
        child: ValueListenableBuilder<StyleTheme>(
          valueListenable: ThemePreferences.selected,
          builder: (_, theme, _) => MaterialApp(
            theme: ThemePreferences.data(theme),
            home: const WardrobeScreen(),
          ),
        ),
      ),
    );
    for (final theme in StyleTheme.values) {
      await tester.runAsync(() => ThemePreferences.setTheme(theme));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(WardrobeScreen));
      expect(
        Theme.of(context).scaffoldBackgroundColor,
        ThemePreferences.data(theme).scaffoldBackgroundColor,
      );
      expect(find.text('Adaugă prima piesă'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.runAsync(() => ThemePreferences.init());
    expect(ThemePreferences.selected.value, StyleTheme.rose);
  });
}

