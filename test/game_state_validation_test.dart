import 'package:flutter_test/flutter_test.dart';
import 'package:holding_tycoon/providers/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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
}
