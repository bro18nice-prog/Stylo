import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:outfit/models/clothing_item.dart';
import 'package:outfit/services/anchor_fit_service.dart';
import 'package:outfit/screens/usage_guide_screen.dart';
import 'package:outfit/screens/add_clothing_screen.dart';

void main() {
  test(
    'Affine alignment hits all three anchors at different viewport sizes',
    () {
      final fit = AnchorFit(
        source: const [Offset(.12, .17), Offset(.82, .11), Offset(.44, .9)],
        target: const [Offset(.2, .22), Offset(.76, .25), Offset(.5, .48)],
      );
      for (final size in [const Size(180, 420), const Size(414, 950)]) {
        final matrix = fit.matrix(size);
        for (var i = 0; i < 3; i++) {
          final point = MatrixUtils.transformPoint(
            matrix,
            Offset(
              fit.source[i].dx * size.width,
              fit.source[i].dy * size.height,
            ),
          );
          expect(point.dx, closeTo(fit.target[i].dx * size.width, .000001));
          expect(point.dy, closeTo(fit.target[i].dy * size.height, .000001));
        }
      }
      expect(
        fit
            .copyWith(source: const [Offset.zero, Offset(.5, .5), Offset(1, 1)])
            .valid,
        isFalse,
      );
    },
  );
  test(
    'Shoe and accessory slots survive storage reopening independently',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'anchor-persistence-',
      );
      Hive.init(directory.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ClothingItemAdapter());
      }
      try {
        for (final slot in ['Papucul 1', 'Papucul 2', 'Geantă', 'Inel']) {
          final fit = AnchorFit.initial(slot);
          expect(fit.valid, isTrue);
          await AnchorFitService.save('$slot.png', fit);
        }
        final box = await Hive.openBox<ClothingItem>('test-items');
        await box.add(
          ClothingItem(
            name: 'shoe',
            category: 'Pantofi',
            imagePath: 'shoe.png',
            placementSlot: 'Papucul 2',
          ),
        );
        await Hive.close();
        final reopened = await Hive.openBox<ClothingItem>('test-items');
        expect(reopened.getAt(0)!.slot, 'Papucul 2');
        final left = await AnchorFitService.load('Papucul 1.png');
        final right = await AnchorFitService.load('Papucul 2.png');
        expect(left!.target[0].dx, lessThan(right!.target[0].dx));
        expect(
          (await AnchorFitService.load('Inel.png'))!.toMap(),
          AnchorFit.initial('Inel').toMap(),
        );
        expect(
          ClothingItem(
            name: 'old',
            category: 'Pantofi',
            imagePath: 'old.png',
          ).slot,
          'Papucul 1',
        );
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets('Guide and shoe import fit on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: UsageGuideScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('5. Genți și inele'), 400);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      const MaterialApp(
        home: AddClothingScreen(
          initialCategory: 'Pantofi',
          initialSlot: 'Papucul 2',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Locul în cabină'), 300);
    expect(find.text('Papucul 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Render guide illustrations for visual review', (tester) async {
    if (Platform.environment['STYLO_REVIEW_DIR'] == null) return;
    await tester.runAsync(() async {
      final loader = FontLoader('ReviewFont');
      loader.addFont(
        File(
          Platform.environment['STYLO_REVIEW_FONT']!,
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
      await loader.load();
    });
    tester.view.physicalSize = const Size(640, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  SizedBox(
                    height: 210,
                    width: 315,
                    child: CustomPaint(
                      painter: GuideIllustration(
                        i,
                        ColorScheme.fromSeed(seedColor: Colors.deepOrange),
                        fontFamily: 'ReviewFont',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await File(
        '${Platform.environment['STYLO_REVIEW_DIR']}/guide-review.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
