import 'package:outfit/services/anchor_fit_service.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:outfit/models/clothing_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:outfit/providers/wardrobe_provider.dart';
import 'package:outfit/theme/theme_preferences.dart';
import 'package:outfit/ui/screens/outfit_studio/outfit_studio_screen.dart';

class _TestWardrobe extends WardrobeProvider {
  @override
  List<ClothingItem> get items => [
    ClothingItem(
      name: 'Test shirt',
      category: 'Tricou',
      imagePath: 'missing-test.png',
    ),
  ];
}

class _SlotsWardrobe extends WardrobeProvider {
  @override
  List<ClothingItem> get items => [
    ClothingItem(
      name: 'Shoe one',
      category: 'Pantofi',
      imagePath: 'shoe-one.png',
      placementSlot: 'Papucul 1',
    ),
    ClothingItem(
      name: 'Shoe two',
      category: 'Pantofi',
      imagePath: 'shoe-two.png',
      placementSlot: 'Papucul 2',
    ),
    ClothingItem(
      name: 'Bag',
      category: 'Accesorii',
      imagePath: 'bag.png',
      placementSlot: 'Geantă',
    ),
    ClothingItem(
      name: 'Ring',
      category: 'Accesorii',
      imagePath: 'ring.png',
      placementSlot: 'Inel',
    ),
  ];
}

void main() {
  late Directory temporary;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('fitting-room-test');
    Hive.init(temporary.path);
    await Hive.openBox<dynamic>('anchor_fits_v1');
  });
  tearDownAll(() async {
    await Hive.close();
    await temporary.delete(recursive: true);
  });
  testWidgets('Saved anchors disappear and persist after reopening the room', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = _TestWardrobe();
    Widget app() => ChangeNotifierProvider<WardrobeProvider>.value(
      value: provider,
      child: const MaterialApp(home: OutfitStudioScreen()),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Test shirt'));
    await tester.tap(find.text('Test shirt'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('anchor-0')), findsNothing);
    await tester.ensureVisible(find.text('2. Ajustează pe corp'));
    await tester.tap(find.text('2. Ajustează pe corp'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('anchor-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('anchor-4')), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Mută ancora la dreapta'));
    await tester.tap(find.byTooltip('Mută ancora la dreapta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvează potrivirea'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Salvează potrivirea'));
      await Hive.box('anchor_fits_v1').flush();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('anchor-0')), findsNothing);
    expect(find.text('Potrivire salvată · ancore ascunse'), findsOneWidget);
    final fit = await tester.runAsync(
      () => AnchorFitService.load('missing-test.png'),
    );
    expect(
      fit!.target[0].dx,
      closeTo(AnchorFit.initial('Tricou').target[0].dx + .002, .000001),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Test shirt'));
    await tester.tap(find.text('Test shirt'));
    await tester.pumpAndSettle();
    expect(find.text('Potrivire salvată · ancore ascunse'), findsOneWidget);
    expect(find.byKey(const ValueKey('anchor-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Shoes, bag and ring can be selected at the same time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<WardrobeProvider>.value(
        value: _SlotsWardrobe(),
        child: const MaterialApp(home: OutfitStudioScreen()),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['Shoe one', 'Shoe two', 'Bag', 'Ring']) {
      await tester.ensureVisible(find.text(name));
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byType(InputChip).first);
    expect(find.byType(InputChip), findsNWidgets(4));
    expect(find.text('Shoe one · nesalvat'), findsOneWidget);
    expect(find.text('Shoe two · nesalvat'), findsOneWidget);
    expect(find.text('Bag · nesalvat'), findsOneWidget);
    expect(find.text('Ring · nesalvat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Fitting room scrolls on a compact phone in every theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final theme in StyleTheme.values) {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: WardrobeProvider(),
          child: MaterialApp(
            theme: ThemePreferences.data(theme),
            home: const OutfitStudioScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cabina de probă'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Port această ținută azi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Port această ținută azi'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    }
  });
}
