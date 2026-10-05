import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outfit/services/pro_service.dart';
import 'package:outfit/ui/screens/paywall_screen.dart';

void main() {
  test('varianta gratuită are limită de piese', () {
    final pro = ProService();
    expect(pro.isPro, isFalse);
    expect(pro.canAdd(ProService.freeItemLimit - 1), isTrue);
    expect(pro.canAdd(ProService.freeItemLimit), isFalse);
  });

  testWidgets('fără magazin configurat, abonarea e dezactivată', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaywallScreen(reason: 'Test')),
    );
    expect(
      find.text('Plățile nu sunt disponibile în această versiune.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(button.onPressed, isNull);
  });
}
