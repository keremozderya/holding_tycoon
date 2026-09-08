// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:holding_tycoon/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HoldingTycoonApp());
  });
}