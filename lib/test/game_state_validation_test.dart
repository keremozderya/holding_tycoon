import 'package:flutter_test/flutter_test.dart';
import 'package:holding_tycoon/providers/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // This test-only API is required to reset preferences between tests.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('prestige is locked below 100 Qi', () {
    final state = GameState();
    expect(state.calculateEarnableRP(GameState.prestigeThreshold - 1), 0);
    expect(state.calculateEarnableRP(GameState.prestigeThreshold), 10);
    state.dispose();
  });

  test('tasks cannot be claimed before their requirement', () {
    final state = GameState();
    expect(state.claimTask(0), isFalse);
    expect(state.claimTask(-1), isFalse);
    expect(state.claimTask(99), isFalse);
    state.dispose();
  });

  test('non-finite money mutations are rejected', () async {
    final state = GameState();
    await state.updateMoney(double.nan);
    await state.updateMoney(double.infinity);
    expect(state.money, 0);
    state.dispose();
  });

  test('factory catalog contains 75 unique, correctly named products', () {
    final state = GameState();
    final products = state.factories.expand((factory) => factory.products).toList();
    final names = products.map((product) => product.name).toSet();

    expect(state.factories, hasLength(15));
    expect(products, hasLength(75));
    expect(names, hasLength(75));
    expect(names, containsAll(<String>[
      'Tereyağı',
      'Motosiklet',
      'VIP Limuzin',
      'COVID-19 Aşısı',
      'Rüzgar Türbini',
    ]));
    state.dispose();
  });
}
