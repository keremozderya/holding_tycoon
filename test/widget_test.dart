// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:holding_tycoon/main.dart';
import 'package:holding_tycoon/screens/main_menu_screen.dart';
import 'package:holding_tycoon/theme/app_theme.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HoldingTycoonApp());
  });
}