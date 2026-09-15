// lib/config/game_balance.dart
import 'dart:math' as math;

/// Centralized progression constants.
///
/// The target experience is roughly 90 calendar days for a player who spends
/// about 30 active minutes per day (≈45 active hours total). The constants are
/// deliberately kept in one place so economy, tasks, achievements and research
/// can be tuned together instead of drifting apart.
class GameBalance {
  GameBalance._();

  static const int targetDays = 90;
  static const int targetActiveMinutesPerDay = 30;
  static const int targetActiveSeconds =
      targetDays * targetActiveMinutesPerDay * 60; // 162,000 s

  // Product progression. The previous 1.12 income / 1.32 cost pair created
  // increasingly long dead zones. The new pair keeps upgrades meaningful while
  // avoiding runaway stalls.
  static const double productIncomeGrowth = 1.18;
  static const double productUpgradeCostGrowth = 1.23;
  static const double passiveIncomeRatio = 0.22;
  static const double productTierIncomeMultiplier = 2.50;
  static const double productBaseCostMultiplier = 12.0;

  // Research.
  static const double researchCostScale = 0.70;

  // Daily task targets: manual production, product upgrades, stock trades,
  // wheel spins.
  static const List<int> dailyTaskTargets = <int>[75, 10, 3, 1];
  static const List<int> dailyTaskRpRewards = <int>[6, 7, 5, 4];
  static const int dailyTaskCompletionBonusRp = 8;

  // Money rewards scale with the player's current economy while preserving a
  // starter floor.
  static const List<double> dailyTaskRewardSeconds = <double>[
    240.0,
    300.0,
    180.0,
    120.0,
  ];
  static const List<double> dailyTaskMinimumMoney = <double>[
    2500.0,
    4000.0,
    3000.0,
    2000.0,
  ];

  // Every target is reachable inside actual game limits.
  // Product-level total caps at 4,500 (15 factories × 5 products × 60 levels).
  static const List<List<double>> achievementTargets = <List<double>>[
    <double>[100, 300, 750, 1500, 3000, 5000, 7500, 10000, 14000, 18000],
    <double>[1e6, 1e9, 1e12, 1e15, 1e18, 1e21, 1e24, 1e27, 1e29, 1e30],
    <double>[1, 2, 3, 5, 7, 9, 10, 11, 12, 14],
    <double>[1, 2, 3, 5, 7, 10, 14, 18, 24, 30],
    <double>[60, 180, 400, 750, 1200, 1800, 2500, 3200, 3900, 4400],
    <double>[3, 10, 25, 50, 100, 180, 280, 400, 550, 750],
    <double>[1e6, 1e9, 1e12, 1e15, 1e18, 1e21, 1e24, 1e27, 1e29, 1e30],
  ];

  static int researchCost({
    required int baseCost,
    required int currentLevel,
    required int maxLevel,
  }) {
    final raw =
        baseCost * (currentLevel >= maxLevel ? maxLevel : currentLevel + 1);
    return math.max(1, (raw * researchCostScale).ceil());
  }

  static int taskTarget(int index) =>
      dailyTaskTargets[index.clamp(0, dailyTaskTargets.length - 1).toInt()];

  static int taskRpReward(int index) =>
      dailyTaskRpRewards[index.clamp(0, dailyTaskRpRewards.length - 1).toInt()];

  static double taskMoneyReward(int index, double baseIncomePerSecond) {
    final i = index.clamp(0, dailyTaskTargets.length - 1).toInt();
    return math.max(
      dailyTaskMinimumMoney[i],
      baseIncomePerSecond * dailyTaskRewardSeconds[i],
    );
  }

  static int achievementRpReward(int tier) =>
      tier.clamp(0, 9).toInt() + 1;

  static double achievementMoneyReward(
    int tier,
    double baseIncomePerSecond,
  ) {
    final safeTier = tier.clamp(0, 9).toInt();
    final floorReward = 2500.0 * math.pow(2.15, safeTier);
    final productionReward =
        baseIncomePerSecond * (180.0 + safeTier * 60.0);
    return math.max(floorReward, productionReward);
  }
}
