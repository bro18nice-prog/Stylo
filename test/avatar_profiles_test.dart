import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:outfit/providers/wardrobe_provider.dart';
import 'package:outfit/services/avatar_preferences.dart';
import 'package:outfit/services/anchor_fit_service.dart';
import 'package:outfit/ui/screens/dashboard_screen.dart';
import 'package:outfit/ui/screens/outfit_studio/outfit_studio_screen.dart';

Finder asset(String name) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == name,
);
void main() {
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('stylo-profiles-');
    Hive.init(storage.path);
    await AvatarPreferences.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await storage.delete(recursive: true);
  });
  test('Female fittings do not replace existing male fittings', () async {
    final male = AnchorFit.initial('Tricou'),
        female = AnchorFit.initial('Geacă');
    await AnchorFitService.save('same-photo.png', male);
    await AnchorFitService.save('same-photo.png', female, profile: 'Feminin');
    await AvatarPreferences.setProfile('Feminin');
    await Hive.close();
    await AvatarPreferences.init();
    expect(AvatarPreferences.selectedProfile.value, 'Feminin');
    expect(
      (await AnchorFitService.load('same-photo.png'))!.toMap(),
      male.toMap(),
    );
    expect(
      (await AnchorFitService.load(
        'same-photo.png',
        profile: 'Feminin',
      ))!.toMap(),
      female.toMap(),
    );
  });
  testWidgets('Home follows selected mannequin and cabin uses feminine asset', (
    tester,
  ) async {
    final wardrobe = WardrobeProvider();
    AvatarPreferences.selectedProfile.value = 'Masculin';
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: wardrobe,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(asset('assets/images/hero_mannequin_v1.png'), findsOneWidget);
    AvatarPreferences.selectedProfile.value = 'Feminin';
    await tester.pumpAndSettle();
    expect(asset('assets/images/hero_mannequin_female_v1.png'), findsOneWidget);
    expect(asset('assets/images/hero_mannequin_v1.png'), findsNothing);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: wardrobe,
        child: const MaterialApp(home: OutfitStudioScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(asset('assets/images/mannequin_female_v1.png'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
