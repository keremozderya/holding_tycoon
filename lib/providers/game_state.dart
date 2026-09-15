// lib/providers/game_state.dart
// ignore_for_file: discarded_futures, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';
import '../services/audio_service.dart';

// --- MODELLER ---

class OfficeStaff {
  final String id; 
  final String title; 
  final String baseDescription; 
  final double baseCost;
  final double costMultiplier;
  final int maxLevel;
  int level;
  final String Function(int level) effectTextBuilder;
  final double Function(int level) effectValueBuilder;

  OfficeStaff({
    required this.id, 
    required this.title, 
    required this.baseDescription, 
    required this.baseCost, 
    required this.costMultiplier,
    this.maxLevel = 50,
    this.level = 0,
    required this.effectTextBuilder,
    required this.effectValueBuilder,
  });

  double get currentCost => baseCost * math.pow(costMultiplier, level);
  bool get isMaxed => level >= maxLevel;
  double get currentEffectValue => effectValueBuilder(level);
  String get currentEffectText => level == 0 ? 'Etki Yok' : effectTextBuilder(level);
  String get nextEffectText => isMaxed ? 'Maksimum Seviye' : effectTextBuilder(level + 1);
}

class GameEvent {
  final String title; 
  final String description; 
  final double multiplier; 
  final int durationMinutes; 
  final double preventCost;
  GameEvent(this.title, this.description, this.multiplier, this.durationMinutes, this.preventCost);
}

class InGameNotification {
  final String id;
  final String header;
  final String title;
  final String type;
  final int index;
  InGameNotification(this.header, this.title, this.type, this.index) : id = math.Random().nextInt(999999).toString();
}

class FactoryProduct {
  String name; int level; double baseIncome; double baseCost;
  FactoryProduct({required this.name, this.level = 0, required this.baseIncome, required this.baseCost});
  
  double get manualIncome => level == 0 ? 0.0 : baseIncome * math.pow(1.12, level - 1);
  double get passiveIncome => manualIncome * 0.20; 
  double get upgradeCost => baseCost * math.pow(1.32, level);
  
  Map<String, dynamic> toJson() => {'name': name, 'level': level};
}

class FactoryData {
  final String id; final String name; double price; bool isUnlocked; List<FactoryProduct> products;
  FactoryData({required this.id, required this.name, required this.price, this.isUnlocked = false, required this.products});
  int get totalLevel => products.fold(0, (sum, p) => sum + p.level);
  int get currentStage {
    if (totalLevel >= 120) return 4;
    if (totalLevel >= 90) return 3;
    if (totalLevel >= 60) return 2;
    if (totalLevel >= 30) return 1;
    return 0;
  }
  double get basePassiveIncome => isUnlocked ? products.fold(0.0, (sum, p) => sum + p.passiveIncome) : 0.0;
}

class Stock {
  final String id; final String name; final IconData icon; final Color iconColor;
  double currentPrice; List<double> history; double ownedShares; double totalSpent;
  Stock({required this.id, required this.name, required this.icon, required this.iconColor, required this.currentPrice, required this.history, this.ownedShares = 0, this.totalSpent = 0});
  double get netPnl => (currentPrice * ownedShares) - totalSpent;
}

class ResearchNode {
  final String id; final String title; final String category; final String description; final IconData icon; final int baseCost; final int maxLevel; int currentLevel; final List<String> parentIds; final String Function(int level) effectBuilder;
  ResearchNode({required this.id, required this.title, required this.category, required this.description, required this.icon, required this.baseCost, required this.maxLevel, this.currentLevel = 0, required this.parentIds, required this.effectBuilder});
  bool get isUnlocked => currentLevel > 0; 
  bool get isMaxed => currentLevel >= maxLevel; 
  int get cost => isMaxed ? baseCost * maxLevel : baseCost * (currentLevel + 1);
  String get currentEffectText => currentLevel == 0 ? 'research.not_active'.tr() : effectBuilder(currentLevel);
  String get nextEffectText => isMaxed ? 'research.max_level_reached'.tr() : effectBuilder(currentLevel + 1);
}

ResearchNode _n(String id, String title, String category, String description, IconData icon, int baseCost, int maxLevel, List<String> parentIds, String Function(int lvl) effectBuilder, {int currentLevel = 0}) {
  return ResearchNode(id: id, title: title, category: category, description: description, icon: icon, baseCost: baseCost, maxLevel: maxLevel, currentLevel: currentLevel, parentIds: parentIds, effectBuilder: effectBuilder);
}

// --- ANA GAME STATE (STATE MANAGER) ---

class GameState extends ChangeNotifier {
  static const double prestigeThreshold = 1.0e20;
  static const Duration _newGameEventGracePeriod = Duration(minutes: 30);

  double _money = 0.0; 
  int _researchPoints = 0;
  bool _isFirstLaunch = true;
  bool _isInitialized = false;
  bool _disposed = false;
  bool _saveRequested = false;
  Future<void>? _saveInProgress;
  String _language = 'tr';
  bool _useDarkTheme = false;
  String _starterFactoryId = ''; 
  String get starterFactoryId => _starterFactoryId;

  List<FactoryData> _factories = [];
  List<ResearchNode> _researchNodes = [];
  
  List<OfficeStaff> officeStaff = [
    OfficeStaff(
      id: 'staff_1', 
      title: 'Muhasebe Departmanı', 
      baseDescription: 'Tuttuğunuz her muhasebeci vergi oranını %0.4 düşürür.', 
      baseCost: 15000.0, 
      costMultiplier: 1.65, 
      effectTextBuilder: (lvl) => 'Vergi İndirimi: -%${(lvl * 0.4).toStringAsFixed(1)}',
      effectValueBuilder: (lvl) => lvl * 0.004, 
    ),
    OfficeStaff(
      id: 'staff_2', 
      title: 'Üretim Müdürlüğü', 
      baseDescription: 'Her müdür fabrikaların saniyelik gelirini kalıcı %2 artırır.', 
      baseCost: 50000.0, 
      costMultiplier: 1.70, 
      effectTextBuilder: (lvl) => 'Global Gelir İlavesi: +%${lvl * 2}',
      effectValueBuilder: (lvl) => lvl * 0.02,
    ),
    OfficeStaff(
      id: 'staff_3', 
      title: 'İnsan Kaynakları', 
      baseDescription: 'Her uzman yeni arsa alımlarında maliyeti %0.5 düşürür.', 
      baseCost: 150000.0, 
      costMultiplier: 1.70, 
      effectTextBuilder: (lvl) => 'Arsa İndirimi: -%${(lvl * 0.5).toStringAsFixed(1)}',
      effectValueBuilder: (lvl) => lvl * 0.005,
    ),
    OfficeStaff(
      id: 'staff_4', 
      title: 'Borsa Analistleri', 
      baseDescription: 'Her analist borsada kâr etme olasılığını %0.1 artırır.', 
      baseCost: 1000000.0, 
      costMultiplier: 1.75, 
      effectTextBuilder: (lvl) => 'Ekstra Kâr Şansı: +%${(lvl * 0.1).toStringAsFixed(1)}',
      effectValueBuilder: (lvl) => lvl * 0.001,
    ),
    OfficeStaff(
      id: 'staff_5', 
      title: 'Pazarlama Departmanı', 
      baseDescription: 'Her uzman sahada bulunan para çantalarındaki nakit ödül miktarını %10 artırır.', 
      baseCost: 50000000.0, 
      costMultiplier: 1.80, 
      effectTextBuilder: (lvl) => 'Çanta Finansman Primi: +%${lvl * 10}',
      effectValueBuilder: (lvl) => lvl * 0.10, 
    ),
    OfficeStaff(
      id: 'staff_6', 
      title: 'Lojistik & Tedarik', 
      baseDescription: 'Her direktör fabrika üretim bantlarının seviye geliştirme masrafını %0.4 düşürür.', 
      baseCost: 500000000.0, 
      costMultiplier: 1.85, 
      effectTextBuilder: (lvl) => 'Geliştirme İndirimi: -%${(lvl * 0.4).toStringAsFixed(1)}',
      effectValueBuilder: (lvl) => lvl * 0.004,
    ),
    OfficeStaff(
      id: 'staff_7', 
      title: 'Vardiya Operasyonu', 
      baseDescription: 'Her saha şefi siz oyunda yokken biriken çevrimdışı gece mesaisi gelirini %10 artırır.', 
      baseCost: 5000000000.0, 
      costMultiplier: 1.90, 
      effectTextBuilder: (lvl) => 'Gece Mesaisi Katkısı: +%${lvl * 10}',
      effectValueBuilder: (lvl) => lvl * 0.10,
    ),
  ];

  int statClicks = 0; int statStocks = 0; int statUpgrades = 0; int statTaxes = 0; int statPrestige = 0; int statAdsWatched = 0; int statWheelSpins = 0; 
  double statTotalEarned = 0.0; 

  int offlineSecondsCapped = 0;
  double offlineEfficiencyApplied = 0.0;

  List<bool> claimedTasks = List.filled(4, false);

  bool _areAchievementsUnlocked = false;
  bool get areAchievementsUnlocked => _areAchievementsUnlocked;

  int _achBaselineClicks = 0;
  double _achBaselineEarned = 0.0;
  int _achBaselineUnlockedFacs = 0;
  int _achBaselinePrestige = 0;
  int _achBaselineProductLevels = 0;
  int _achBaselineStocks = 0;
  double _achBaselineMoney = 0.0;

  List<int> claimedAchievements = List.filled(7, 0); 
  
  final List<InGameNotification> _notifications = [];
  List<InGameNotification> get notifications => List.unmodifiable(_notifications);
  List<bool> notifiedTasks = List.filled(4, false);
  List<int> notifiedAchievements = List.filled(7, 0);

  static const List<List<double>> achievementTargets = [
    [250, 1000, 5000, 20000, 50000, 150000, 400000, 1000000, 2500000, 5000000], 
    [5e8, 2e11, 1e14, 5e16, 2e19, 1e22, 5e24, 2e27, 1e30, 5e33], 
    [1, 2, 4, 6, 8, 10, 11, 12, 13, 14], 
    [1, 5, 15, 35, 80, 200, 500, 1200, 3000, 10000], 
    [100, 300, 750, 1500, 2500, 3500, 4500, 5500, 6500, 7500], 
    [25, 100, 500, 2000, 7500, 25000, 75000, 200000, 500000, 1000000], 
    [1e8, 5e10, 2e13, 1e16, 5e18, 2e21, 1e24, 5e26, 2e29, 1e32], 
  ];

  double getAchievementMoneyReward(int tier) => 1500.0 * math.pow(2.2, tier); 
  int getAchievementRpReward(int tier) => (tier >= 2) ? (tier - 1) : 1; 

  double getAchievementProgress(int index) {
    if (!_areAchievementsUnlocked) return 0.0;
    if (index == 0) return math.max(0.0, (statClicks - _achBaselineClicks).toDouble());
    if (index == 1) return math.max(0.0, statTotalEarned - _achBaselineEarned);
    if (index == 2) return math.max(0.0, (_factories.where((f) => f.isUnlocked).length - _achBaselineUnlockedFacs).toDouble());
    if (index == 3) return math.max(0.0, (statPrestige - _achBaselinePrestige).toDouble());
    if (index == 4) {
      int t = _factories.fold(0, (sum, f) => sum + f.totalLevel);
      return math.max(0.0, (t - _achBaselineProductLevels).toDouble());
    }
    if (index == 5) return math.max(0.0, (statStocks - _achBaselineStocks).toDouble());
    if (index == 6) return math.max(0.0, _money - _achBaselineMoney);
    return 0.0;
  }

  bool get areTasksUnlocked => true;

  int get unclaimedTasksCount {
    int count = 0;
    if (!claimedTasks[0] && statAdsWatched >= 3) count++;
    if (!claimedTasks[1] && statWheelSpins >= 1) count++;
    if (!claimedTasks[2] && statClicks >= 20) count++;
    if (!claimedTasks[3] && statStocks >= 3) count++;
    return count;
  }

  int get unclaimedAchievementsCount {
    if (!_areAchievementsUnlocked) return 0;
    int count = 0;
    for (int i = 0; i < 7; i++) {
      int tier = claimedAchievements[i];
      if (tier < achievementTargets[i].length) {
        if (getAchievementProgress(i) >= achievementTargets[i][tier]) count++;
      }
    }
    return count;
  }

  double getTaskMoneyReward(int index) {
    const List<double> starterRewards = [800.0, 500.0, 400.0, 600.0];
    const List<double> scaleSeconds = [75.0, 50.0, 40.0, 60.0];
    int i = index.clamp(0, 3);
    double scaled = baseIncomePerSecond * scaleSeconds[i];
    return math.max(starterRewards[i], scaled);
  }

  void _checkAchievementsUnlock() {
    if (!_areAchievementsUnlocked && _factories.any((f) => f.isUnlocked && f.totalLevel >= 30)) {
      _areAchievementsUnlocked = true;
      _achBaselineClicks = statClicks;
      _achBaselineEarned = statTotalEarned;
      _achBaselineUnlockedFacs = _factories.where((f) => f.isUnlocked).length;
      _achBaselinePrestige = statPrestige;
      _achBaselineProductLevels = _factories.fold(0, (sum, f) => sum + f.totalLevel);
      _achBaselineStocks = statStocks;
      _achBaselineMoney = _money;
      claimedAchievements = List.filled(7, 0);
      notifiedAchievements = List.filled(7, 0);
      _saveGame();
      notifyListeners();
    }
  }

  void claimAchievement(int index) {
    if (!_areAchievementsUnlocked || index < 0 || index >= achievementTargets.length) return;
    int tier = claimedAchievements[index];
    if (tier < achievementTargets[index].length) {
      double req = achievementTargets[index][tier];
      if (getAchievementProgress(index) >= req) {
        claimedAchievements[index]++;
        double mReward = getAchievementMoneyReward(tier);
        int rpReward = getAchievementRpReward(tier);
        _money += mReward;
        statTotalEarned += mReward;
        _researchPoints += rpReward;
        _saveGame();
        _checkNotifications(); 
        notifyListeners();
      }
    }
  }

  bool claimTask(int index) {
    if (index < 0 || index >= claimedTasks.length || claimedTasks[index]) return false;
    final requirementsMet = <bool>[
      statAdsWatched >= 3,
      statWheelSpins >= 1,
      statClicks >= 20,
      statStocks >= 3,
    ];
    if (!requirementsMet[index]) return false;
    claimedTasks[index] = true;
    
    double mReward = 0; 
    int rpReward = 0;
    
    if (index == 0) mReward = getTaskMoneyReward(0);
    else if (index == 1) rpReward = 5;
    else if (index == 2) mReward = getTaskMoneyReward(2);
    else if (index == 3) rpReward = 2;

    if (mReward > 0) { _money += mReward; statTotalEarned += mReward; }
    if (rpReward > 0) { _researchPoints += rpReward; }
    
    _saveGame();
    _checkNotifications(); 
    notifyListeners();
    return true;
  }

  void removeNotification(InGameNotification notif) {
    _notifications.remove(notif);
    notifyListeners();
  }

  void _checkNotifications() {
    if (areTasksUnlocked) {
      final List<Map<String, dynamic>> tData = [
        {'title': 'Sermaye Enjeksiyonu', 'c': statAdsWatched, 't': 3},
        {'title': 'Makine Çarkı', 'c': statWheelSpins, 't': 1},
        {'title': 'Aktif Mesai', 'c': statClicks, 't': 20},
        {'title': 'Piyasayı Yokla', 'c': statStocks, 't': 3},
      ];
      for (int i = 0; i < 4; i++) {
        if (!notifiedTasks[i] && !claimedTasks[i]) {
          if (tData[i]['c'] >= tData[i]['t']) {
            notifiedTasks[i] = true;
            _notifications.add(InGameNotification('GÖREV TAMAMLANDI', tData[i]['title'], 'task', i));
          }
        }
      }
    }

    if (_areAchievementsUnlocked) {
      final List<String> achTitles = ['Tıklama Kralı', 'Kasa Bekçisi', 'Holding Genişlemesi', 'Prestij Lordu', 'Seviye Canavarı', 'Hisse Avcısı', 'Zirveye Tırmanış'];
      for (int i = 0; i < 7; i++) {
        int currentTier = claimedAchievements[i];
        if (currentTier < achievementTargets[i].length) {
          if (notifiedAchievements[i] == currentTier) {
            if (getAchievementProgress(i) >= achievementTargets[i][currentTier]) {
              notifiedAchievements[i] = currentTier + 1;
              _notifications.add(InGameNotification('BAŞARIM TAMAMLANDI', '${achTitles[i]} (Kademe ${currentTier + 1})', 'achievement', i));
            }
          }
        }
      }
    }

  }

  DateTime? _boostEndTime; 
  GameEvent? activeEvent; 
  DateTime? _eventEndTime;
  DateTime? _newGameStartedAt;
  GameEvent? _unhandledEvent; 
  double _unhandledBagReward = 0.0; 
  double offlineEarningsToClaim = 0.0; 

  String get activeEventTimeLeft {
    if (!isEventActive) return '';
    int secs = _eventEndTime!.difference(DateTime.now()).inSeconds;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  String get boostTimeLeft {
    if (!isBoostActive) return '';
    int secs = _boostEndTime!.difference(DateTime.now()).inSeconds;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  double get researchMultiplier {
    double m = 1.0;
    if (_researchNodes.isNotEmpty) {
      var node1 = _researchNodes.firstWhere((n) => n.id == 'node_001', orElse: () => _researchNodes[0]);
      if (node1.currentLevel > 0) { m += (node1.currentLevel * 0.03); }
      var node15 = _researchNodes.firstWhere((n) => n.id == 'node_015', orElse: () => _researchNodes[0]);
      if (node15.currentLevel > 0) { m += (node15.currentLevel * 0.10); }
    }
    return m;
  }

  double get currentMultiplier {
    double m = 1.0;
    if (isBoostActive) { m *= _nodeLevel('node_078') > 0 ? 2.5 : 2.0; }
    if (isTaxBonusActive) {
      m *= 1.20 + (_nodeLevel('node_055') * 0.03) + (_nodeLevel('node_057') * 0.10);
    }
    if (isEventActive) { m *= activeEvent!.multiplier; }
    m *= 1.0 + _officeEffect('staff_2');
    m *= researchMultiplier; 
    m *= 1.0 + (_nodeLevel('node_019') * 0.002) + (_nodeLevel('node_020') * 0.05);
    final unlocked = _factories.where((factory) => factory.isUnlocked).toList();
    if (_nodeLevel('node_042') > 0 && unlocked.length == _factories.length) m *= 1.30;
    m *= 1.0 + (unlocked.where((f) => f.totalLevel >= 50).length * _nodeLevel('node_043') * 0.02);
    m *= 1.0 + (unlocked.where((f) => f.totalLevel >= 100).length * _nodeLevel('node_044') * 0.03);
    m *= 1.0 + (unlocked.where((f) => f.totalLevel >= 200).length * _nodeLevel('node_046') * 0.05);
    if (_nodeLevel('node_050') > 0) m *= 1.50;
    m *= 1.0 + (_nodeLevel('node_024') * 0.02) + (_nodeLevel('node_025') * 0.03) +
        (_nodeLevel('node_026') * 0.04) + (_nodeLevel('node_027') * 0.05);
    final visualMilestones = unlocked.fold<int>(0, (sum, factory) => sum + factory.totalLevel ~/ 50);
    m *= 1.0 + (visualMilestones * _nodeLevel('node_049') * 0.05);
    const turnoverRanks = <double>[1e6, 1e9, 1e12, 1e15, 1e18, 1e21, 1e24, 1e27, 1e30, 1e33];
    final rank = turnoverRanks.where((target) => statTotalEarned >= target).length;
    m *= 1.0 + (rank * _nodeLevel('node_095') * 0.05);
    if (rank >= 6) m *= 1.0 + (_nodeLevel('node_096') * 0.10);
    if (statTotalEarned >= 1e30 && _nodeLevel('node_097') > 0) m *= 1.50;
    if (_nodeLevel('node_100') > 0) m *= 5.0;
    return m;
  }
  
  bool get isBoostActive => _boostEndTime != null && DateTime.now().isBefore(_boostEndTime!);
  bool get isEventActive => activeEvent != null && _eventEndTime != null && DateTime.now().isBefore(_eventEndTime!);
  double get incomePerSecond => _factories.fold(0.0, (sum, factory) {
    if (!factory.isUnlocked) return sum;
    var factoryIncome = 0.0;
    for (var i = 0; i < factory.products.length; i++) {
      final productNode = i < 1 ? null : 'node_0${27 + i}';
      final productBonus = productNode == null ? 1.0 : 1.0 + (_nodeLevel(productNode) * (0.05 + i * 0.05));
      factoryIncome += factory.products[i].passiveIncome * productBonus;
    }
    final passiveBonus = 1.0 + (_nodeLevel('node_021') * 0.03) +
        (_nodeLevel('node_022') * 0.03) + (_nodeLevel('node_023') * 0.10);
    return sum + (factoryIncome * passiveBonus * _factoryResearchMultiplier(factory.id));
  }) * currentMultiplier;
  double get baseIncomePerSecond => _factories.fold(0.0, (sum, f) => sum + f.basePassiveIncome); 

  int _nodeLevel(String id) {
    for (final node in _researchNodes) {
      if (node.id == id) return node.currentLevel;
    }
    return 0;
  }

  int researchLevel(String id) => _nodeLevel(id);

  double _officeEffect(String staffId) {
    final staff = officeStaff.firstWhere((item) => item.id == staffId);
    var power = 1.0;
    if (staffId == 'staff_2') power += _nodeLevel('node_035') * 0.12;
    if (staffId == 'staff_3' || staffId == 'staff_6') power += _nodeLevel('node_036') * 0.15;
    if (staffId == 'staff_4' || staffId == 'staff_5' || staffId == 'staff_7') power += _nodeLevel('node_037') * 0.20;
    if (_nodeLevel('node_038') > 0) power += 0.25;
    return staff.currentEffectValue * power;
  }

  double staffCost(OfficeStaff staff) {
    final discount = (_nodeLevel('node_033') * 0.10) + (_nodeLevel('node_034') * 0.15);
    return staff.currentCost * (1.0 - discount).clamp(0.2, 1.0);
  }

  double manualProductionMultiplier(String factoryId, int productIndex) {
    if (productIndex < 0 || productIndex > 4) return 0;
    final productNode = productIndex < 1 ? null : 'node_0${27 + productIndex}';
    final productBonus = productNode == null ? 1.0 :
        1.0 + (_nodeLevel(productNode) * (0.05 + productIndex * 0.05));
    return productBonus * _factoryResearchMultiplier(factoryId) * currentMultiplier;
  }

  double? productUpgradeCost(String factoryId, int productIndex) {
    final matches = _factories.where((factory) => factory.id == factoryId);
    if (matches.isEmpty) return null;
    final factory = matches.first;
    if (!factory.isUnlocked || productIndex < 0 || productIndex >= factory.products.length) return null;
    final product = factory.products[productIndex];
    const unlockLevels = <int>[0, 30, 60, 90, 120];
    if (product.level >= 60 || (product.level == 0 && factory.totalLevel < unlockLevels[productIndex])) return null;
    final logisticsDiscount = _officeEffect('staff_6');
    var researchDiscount = (_nodeLevel('node_002') * 0.03) +
        (_nodeLevel('node_016') * 0.005) + (_nodeLevel('node_017') * 0.04);
    if (product.level == 0) researchDiscount += _nodeLevel('node_032') * 0.15;
    if (factory.totalLevel >= 150) researchDiscount += _nodeLevel('node_045') * 0.02;
    if (_nodeLevel('node_100') > 0) researchDiscount += 0.50;
    return product.upgradeCost * (1.0 - logisticsDiscount - researchDiscount).clamp(0.1, 1.0);
  }

  double? factoryUnlockCost(String factoryId) {
    final matches = _factories.where((factory) => factory.id == factoryId);
    if (matches.isEmpty || matches.first.isUnlocked) return null;
    final factory = matches.first;
    var discount = _officeEffect('staff_3') + (_nodeLevel('node_018') * 0.06);
    final number = int.tryParse(factoryId) ?? 0;
    if (number <= 4) {
      discount += _nodeLevel('node_039') * 0.15;
    } else if (number <= 8) {
      discount += _nodeLevel('node_040') * 0.20;
    } else {
      discount += _nodeLevel('node_041') * 0.25;
    }
    if (_nodeLevel('node_100') > 0) discount += 0.50;
    return factory.price * (1.0 - discount).clamp(0.1, 1.0);
  }

  double _factoryResearchMultiplier(String factoryId) {
    const nodeByFactory = <String, String>{
      '1': 'node_007', '2': 'node_003', '3': 'node_005', '4': 'node_004', '6': 'node_006',
      '7': 'node_009', '9': 'node_008', '11': 'node_010', '12': 'node_011',
      '13': 'node_013', '14': 'node_012', '15': 'node_014',
    };
    final nodeId = nodeByFactory[factoryId];
    if (nodeId == null) return 1.0;
    final perLevel = <String, double>{
      'node_009': 0.06, 'node_010': 0.06, 'node_011': 0.07,
      'node_012': 0.07, 'node_013': 0.08, 'node_014': 0.10,
    }[nodeId] ?? 0.05;
    return 1.0 + (_nodeLevel(nodeId) * perLevel);
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  DateTime? _lastTaxIssued; 
  DateTime? _taxDeadline; 
  double _currentTaxDebt = 0.0; 
  bool _isUnderPenalty = false;
  DateTime? _taxBonusEndTime; 
  DateTime? _lastPenaltyCompoundTime; 

  double get currentTaxDebt => _currentTaxDebt; 
  bool get hasTaxDebt => _currentTaxDebt > 0; 
  bool get isUnderPenalty => _isUnderPenalty;
  bool get isTaxBonusActive => _taxBonusEndTime != null && DateTime.now().isBefore(_taxBonusEndTime!);

  int get taxRemainingSeconds {
    if (_taxDeadline == null) return 0;
    final diff = _taxDeadline!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  String get taxTimeLeftFormatted {
    int secs = taxRemainingSeconds;
    int h = secs ~/ 3600;
    int m = (secs % 3600) ~/ 60;
    int s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get taxBonusTimeLeft {
    if (!isTaxBonusActive) return '';
    int secs = _taxBonusEndTime!.difference(DateTime.now()).inSeconds;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  DateTime? _lastSaveTime; 
  Timer? _gameTimer; 
  final math.Random _random = math.Random(); 
  List<Stock> _stocks = [];

  double get money => _money; 
  int get researchPoints => _researchPoints; 
  bool get isFirstLaunch => _isFirstLaunch; 
  String get language => _language;
  bool get useDarkTheme => _useDarkTheme;
  List<Stock> get stocks => _stocks; 
  List<FactoryData> get factories => _factories; 
  List<ResearchNode> get researchNodes => _researchNodes;

  GameEvent? consumeUnhandledEvent() { var ev = _unhandledEvent; _unhandledEvent = null; return ev; }
  double consumeUnhandledBagReward() { var b = _unhandledBagReward; _unhandledBagReward = 0.0; return b; }

  int calculateEarnableRP([double? turnover]) {
    final double evalTurnover = turnover ?? statTotalEarned;
    if (evalTurnover < prestigeThreshold) return 0;
    
    final double ratio = evalTurnover / prestigeThreshold;
    double baseRp = 10.0 * math.sqrt(ratio);

    double rpMultiplier = 1.0;
    if (_researchNodes.isNotEmpty) {
      var n89 = _researchNodes.firstWhere((n) => n.id == 'node_089', orElse: () => _researchNodes[0]);
      if (n89.currentLevel > 0) rpMultiplier += (n89.currentLevel * 0.15);

      var n90 = _researchNodes.firstWhere((n) => n.id == 'node_090', orElse: () => _researchNodes[0]);
      if (n90.currentLevel > 0) rpMultiplier += (n90.currentLevel * 0.25);

      var n91 = _researchNodes.firstWhere((n) => n.id == 'node_091', orElse: () => _researchNodes[0]);
      if (n91.currentLevel > 0) rpMultiplier += (n91.currentLevel * 0.50);

      var n100 = _researchNodes.firstWhere((n) => n.id == 'node_100', orElse: () => _researchNodes[0]);
      if (n100.currentLevel > 0) rpMultiplier *= 3.0;

      final level250Factories = _factories.where((factory) => factory.totalLevel >= 250).length;
      rpMultiplier += level250Factories * _nodeLevel('node_047') * 0.03;
    }

    return (baseRp * rpMultiplier).floor();
  }

  Future<void> loadData() async {
    if (_isInitialized) return; 
    _isInitialized = true;

    final prefs = await SharedPreferences.getInstance();
    _useDarkTheme = prefs.getBool('use_dark_theme') ?? false;
    final savedGameJson = prefs.getString('game_save_data');
    Map<String, dynamic>? decodedSave;
    if (savedGameJson != null) {
      try {
        final decoded = jsonDecode(savedGameJson);
        if (decoded is Map<String, dynamic>) decodedSave = decoded;
      } catch (error) {
        debugPrint('Ignoring invalid save data: $error');
        await prefs.remove('game_save_data');
      }
    }

    if (decodedSave != null) {
      final data = decodedSave;
      
      _starterFactoryId = data['starterFactoryId'] ?? ''; 
      _money = (data['money'] as num?)?.toDouble() ?? 0.0;
      if (!_money.isFinite || _money < 0) _money = 0.0;
      statTotalEarned = (data['statTotalEarned'] as num?)?.toDouble() ?? _money; 
      if (!statTotalEarned.isFinite || statTotalEarned < 0) statTotalEarned = _money;
      _researchPoints = (data['researchPoints'] as num?)?.toInt() ?? 0;
      _isFirstLaunch = data['isFirstLaunch'] ?? true;
      _language = data['language'] ?? 'tr';
      _currentTaxDebt = (data['currentTaxDebt'] as num?)?.toDouble() ?? 0.0;
      
      statClicks = (data['statClicks'] as num?)?.toInt() ?? 0;
      statStocks = (data['statStocks'] as num?)?.toInt() ?? 0;
      statUpgrades = (data['statUpgrades'] as num?)?.toInt() ?? 0;
      statTaxes = (data['statTaxes'] as num?)?.toInt() ?? 0;
      statPrestige = (data['statPrestige'] as num?)?.toInt() ?? 0;
      statAdsWatched = (data['statAdsWatched'] as num?)?.toInt() ?? 0;
      statWheelSpins = (data['statWheelSpins'] as num?)?.toInt() ?? 0;
      
      if (data['claimedTasks'] is List) {
        final saved = List<dynamic>.from(data['claimedTasks']);
        claimedTasks = List<bool>.generate(4, (i) => i < saved.length && saved[i] == true);
      }
      
      _areAchievementsUnlocked = data['areAchievementsUnlocked'] ?? false;
      _achBaselineClicks = data['achBaselineClicks'] ?? 0;
      _achBaselineEarned = (data['achBaselineEarned'] as num?)?.toDouble() ?? 0.0;
      _achBaselineUnlockedFacs = data['achBaselineUnlockedFacs'] ?? 0;
      _achBaselinePrestige = data['achBaselinePrestige'] ?? 0;
      _achBaselineProductLevels = data['achBaselineProductLevels'] ?? 0;
      _achBaselineStocks = data['achBaselineStocks'] ?? 0;
      _achBaselineMoney = (data['achBaselineMoney'] as num?)?.toDouble() ?? 0.0;

      if (data['notifiedTasks'] is List) {
        final saved = List<dynamic>.from(data['notifiedTasks']);
        notifiedTasks = List<bool>.generate(4, (i) => i < saved.length && saved[i] == true);
      } else {
        notifiedTasks = List<bool>.from(claimedTasks);
      }

      if (data['claimedAchievements'] != null) {
        List<dynamic> loadedAch = data['claimedAchievements'];
        claimedAchievements = List.generate(7, (i) {
          if (i < loadedAch.length) {
            if (loadedAch[i] is bool) return loadedAch[i] ? 1 : 0; 
            if (loadedAch[i] is num) return (loadedAch[i] as num).toInt().clamp(0, 10);
          }
          return 0;
        });
      }

      if (data['notifiedAchievements'] != null) {
        List<dynamic> loadedNotif = data['notifiedAchievements'];
        notifiedAchievements = List.generate(7, (i) => i < loadedNotif.length && loadedNotif[i] is num ? (loadedNotif[i] as num).toInt().clamp(0, 10) : 0);
      } else {
        notifiedAchievements = List<int>.from(claimedAchievements);
      }
      
      if (data['officeStaffLevels'] != null) {
        List<dynamic> staffList = data['officeStaffLevels'];
        for (var saved in staffList) {
          try { 
            var staff = officeStaff.firstWhere((s) => s.id == saved['id']); 
            staff.level = ((saved['level'] as num?)?.toInt() ?? 0).clamp(0, staff.maxLevel);
          } catch (_) {}
        }
      }

      _lastTaxIssued = _tryParseDate(data['lastTaxIssued']);
      _taxDeadline = _tryParseDate(data['taxDeadline']);
      _taxBonusEndTime = _tryParseDate(data['taxBonusEndTime']);
      _lastPenaltyCompoundTime = _tryParseDate(data['lastPenaltyCompoundTime']);
      _lastSaveTime = _tryParseDate(data['lastSaveTime']);
      _boostEndTime = _tryParseDate(data['boostEndTime']);
      _newGameStartedAt = _tryParseDate(data['newGameStartedAt']);
      if (data['eventEndTime'] != null && data['activeEvent'] != null) { 
        _eventEndTime = _tryParseDate(data['eventEndTime']);
        var ev = data['activeEvent']; 
        if (_eventEndTime != null && ev is Map) {
          activeEvent = GameEvent(
            ev['title']?.toString() ?? '',
            ev['desc']?.toString() ?? '',
            (ev['mult'] as num?)?.toDouble() ?? 1.0,
            (ev['dur'] as num?)?.toInt() ?? 0,
            (ev['cost'] as num?)?.toDouble() ?? 0.0,
          );
        }
      }
      _isUnderPenalty = data['isUnderPenalty'] ?? false;

      _loadStocksFromJson(data['stocks']);
      _loadFactoriesFromJson(data['factories']);
      _loadResearchFromJson(data['researchNodes']); 
      
      if (_lastSaveTime != null) {
        int secondsPassed = DateTime.now().difference(_lastSaveTime!).inSeconds;
        if (secondsPassed < 0) secondsPassed = 0;

        int maxOfflineHours = 3; 
        var n86 = _researchNodes.firstWhere((n) => n.id == 'node_086', orElse: () => _researchNodes[0]);
        if (n86.currentLevel > 0) maxOfflineHours = 6 + (n86.currentLevel * 3);
        
        var n87 = _researchNodes.firstWhere((n) => n.id == 'node_087', orElse: () => _researchNodes[0]);
        if (n87.currentLevel > 0) maxOfflineHours += (n87.currentLevel * 4);

        int maxOfflineSeconds = maxOfflineHours * 3600;

        if (secondsPassed > maxOfflineSeconds) {
          secondsPassed = maxOfflineSeconds;
        }
        
        offlineSecondsCapped = secondsPassed;

        if (secondsPassed > 60 && baseIncomePerSecond > 0) {
          double offlineEfficiency = 0.20; 
          double shiftBonus = _officeEffect('staff_7');
          
          double afkNodeBonus = 0.0;
          var n85 = _researchNodes.firstWhere((n) => n.id == 'node_085', orElse: () => _researchNodes[0]);
          if (n85.currentLevel > 0) afkNodeBonus = n85.currentLevel * 0.20;

          double totalOfflineEfficiency = offlineEfficiency + shiftBonus + afkNodeBonus;
          offlineEfficiencyApplied = totalOfflineEfficiency;

          offlineEarningsToClaim = secondsPassed * baseIncomePerSecond * totalOfflineEfficiency;
        }
      }

      _checkAchievementsUnlock();
    } else {
      _loadStocksFromJson(null); 
      _loadFactoriesFromJson(null); 
      _loadResearchFromJson(null);
      _lastTaxIssued = DateTime.now(); 
      _taxDeadline = DateTime.now().add(const Duration(hours: 12)); 
    }

    if (_eventEndTime != null && !DateTime.now().isBefore(_eventEndTime!)) {
      activeEvent = null;
      _eventEndTime = null;
    }
    if (_boostEndTime != null && !DateTime.now().isBefore(_boostEndTime!)) _boostEndTime = null;
    if (_taxBonusEndTime != null && !DateTime.now().isBefore(_taxBonusEndTime!)) _taxBonusEndTime = null;

    await TranslationService.instance.loadLanguage(_language);
    await AudioService.instance.init();
    notifyListeners(); 
    _startGlobalTimers();
  }

  Future<void> _saveGame() {
    if (_disposed) return Future<void>.value();
    _saveRequested = true;
    return _saveInProgress ??= _flushSaveQueue();
  }

  bool get canPrestige => statTotalEarned >= prestigeThreshold && (!hasTaxDebt || _nodeLevel('node_098') > 0);

  Future<void> _flushSaveQueue() async {
    try {
      while (_saveRequested && !_disposed) {
        _saveRequested = false;
        try {
          await _writeSave();
        } catch (error) {
          debugPrint('Game save failed: $error');
        }
      }
    } finally {
      _saveInProgress = null;
      if (_saveRequested && !_disposed) await _saveGame();
    }
  }

  Future<void> _writeSave() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSaveTime = DateTime.now();

    Map<String, dynamic> gameData = {
      'starterFactoryId': _starterFactoryId,
      'money': _money, 'researchPoints': _researchPoints, 'isFirstLaunch': _isFirstLaunch, 'language': _language,
      'statClicks': statClicks, 'statStocks': statStocks, 'statUpgrades': statUpgrades, 'statTaxes': statTaxes, 'statPrestige': statPrestige, 'statAdsWatched': statAdsWatched, 'statWheelSpins': statWheelSpins, 'statTotalEarned': statTotalEarned,
      'claimedTasks': claimedTasks, 
      'notifiedTasks': notifiedTasks,
      'areAchievementsUnlocked': _areAchievementsUnlocked,
      'achBaselineClicks': _achBaselineClicks,
      'achBaselineEarned': _achBaselineEarned,
      'achBaselineUnlockedFacs': _achBaselineUnlockedFacs,
      'achBaselinePrestige': _achBaselinePrestige,
      'achBaselineProductLevels': _achBaselineProductLevels,
      'achBaselineStocks': _achBaselineStocks,
      'achBaselineMoney': _achBaselineMoney,
      'claimedAchievements': claimedAchievements, 
      'notifiedAchievements': notifiedAchievements,
      'officeStaffLevels': officeStaff.map((s) => {'id': s.id, 'level': s.level}).toList(), 
      'currentTaxDebt': _currentTaxDebt, 
      'lastTaxIssued': _lastTaxIssued?.toIso8601String(), 
      'taxDeadline': _taxDeadline?.toIso8601String(), 
      'taxBonusEndTime': _taxBonusEndTime?.toIso8601String(),
      'lastPenaltyCompoundTime': _lastPenaltyCompoundTime?.toIso8601String(),
      'lastSaveTime': _lastSaveTime?.toIso8601String(), 
      'boostEndTime': _boostEndTime?.toIso8601String(), 
      'newGameStartedAt': _newGameStartedAt?.toIso8601String(),
      'eventEndTime': _eventEndTime?.toIso8601String(),
      'activeEvent': activeEvent != null ? {'title': activeEvent!.title, 'desc': activeEvent!.description, 'mult': activeEvent!.multiplier, 'dur': activeEvent!.durationMinutes, 'cost': activeEvent!.preventCost} : null,
      'isUnderPenalty': _isUnderPenalty,
      'stocks': _stocks.map((s) => {'id': s.id, 'currentPrice': s.currentPrice, 'history': s.history, 'ownedShares': s.ownedShares, 'totalSpent': s.totalSpent}).toList(),
      'factories': _factories.map((f) => {'id': f.id, 'isUnlocked': f.isUnlocked, 'products': f.products.map((p) => p.toJson()).toList()}).toList(),
      'researchNodes': _researchNodes.map((r) => {'id': r.id, 'level': r.currentLevel}).toList(),
    };
    await prefs.setString('game_save_data', jsonEncode(gameData));
  }

  Future<void> startNewGameSession() async {
    _isFirstLaunch = false;
    _starterFactoryId = ''; 
    _money = 0.0;
    _researchPoints = 0;
    
    _initDefaultFactories();
    _initDefaultResearchNodes();
    _loadStocksFromJson(null);
    
    for (var s in officeStaff) { s.level = 0; }
    for (var s in _stocks) { s.ownedShares = 0; s.totalSpent = 0; }

    _currentTaxDebt = 0.0;
    _isUnderPenalty = false;
    _lastTaxIssued = DateTime.now();
    _taxDeadline = DateTime.now().add(const Duration(hours: 12));
    _taxBonusEndTime = null;
    _lastPenaltyCompoundTime = null;
    _boostEndTime = null;
    _newGameStartedAt = DateTime.now();
    activeEvent = null;
    _eventEndTime = null;
    _unhandledEvent = null;
    _unhandledBagReward = 0.0;
    offlineEarningsToClaim = 0.0;
    offlineSecondsCapped = 0;
    offlineEfficiencyApplied = 0.0;
    _lastSaveTime = DateTime.now();

    statClicks = 0; statStocks = 0; statUpgrades = 0; statTaxes = 0; 
    statPrestige = 0; statAdsWatched = 0; statWheelSpins = 0; statTotalEarned = 0.0;
    
    claimedTasks = List.filled(4, false);
    notifiedTasks = List.filled(4, false);

    _areAchievementsUnlocked = false;
    _achBaselineClicks = 0;
    _achBaselineEarned = 0.0;
    _achBaselineUnlockedFacs = 0;
    _achBaselinePrestige = 0;
    _achBaselineProductLevels = 0;
    _achBaselineStocks = 0;
    _achBaselineMoney = 0.0;
    claimedAchievements = List.filled(7, 0); 
    notifiedAchievements = List.filled(7, 0);
    _notifications.clear();
    
    await _saveGame();
    notifyListeners();
  }

  Future<void> applyStarterSector(String facId) async {
    if (_starterFactoryId.isNotEmpty || !const {'1', '2', '3'}.contains(facId)) return;
    _starterFactoryId = facId;
    for (var f in _factories) {
      if (f.id == facId) {
        f.isUnlocked = true;
        f.price = 0.0;
        f.products[0].level = 1;
      }
    }
    await _saveGame();
    notifyListeners();
  }

  void _initDefaultFactories() {
    _factories = [
      _buildFac('1', 'Tekstil Atölyesi', _starterFactoryId == '1' ? 0.0 : 300000.0, _starterFactoryId == '1', ['T-shirt', 'Pantolon', 'Ayakkabı', 'Çanta', 'Takım Elbise'], 2.0),
      _buildFac('2', 'Mobilya Fabrikası', _starterFactoryId == '2' ? 0.0 : 300000.0, _starterFactoryId == '2', ['Sandalye', 'Masa', 'Koltuk', 'Yatak', 'Dolap'], 2.0),
      _buildFac('3', 'Tarım Tesisleri', _starterFactoryId == '3' ? 0.0 : 300000.0, _starterFactoryId == '3', ['Buğday', 'Mısır', 'Pamuk', 'Safran', 'Hibrit Tohum'], 2.0),
      _buildFac('4', 'Süt Ürünleri', 4e6, false, ['Süt', 'Yoğurt', 'Tereyağ', 'Arı Sütü', 'Pule Peyniri'], 120.0), 
      _buildFac('5', 'Mezbaha', 65e6, false, ['Sosis', 'Tavuk', 'Kebap', 'Timsah Derisi', 'Wagyu Eti'], 1600.0),
      _buildFac('6', 'Gıda İşleme', 1.5e9, false, ['Un', 'Şeker', 'Konserve', 'Havyar', 'Gurme Çikolata'], 28000.0), 
      _buildFac('7', 'Maden Çıkarma', 45e9, false, ['Kömür', 'Demir', 'Gümüş', 'Altın', 'Elmas'], 600000.0), 
      _buildFac('8', 'Kimya Tesisleri', 1.8e12, false, ['Gübre', 'Plastik', 'Boya', 'Lüks Parfüm', 'Karbonfiber'], 15e6), 
      _buildFac('9', 'Otomobil Fabrikası', 80e12, false, ['Lastik', 'Motorsiklet', 'Otomobil', 'Vip Limuzin', 'Süper Spor Araç'], 450e6), 
      _buildFac('10', 'İlaç Fabrikası', 4e15, false, ['Vitamin Hapı', 'Ağrı Kesici', 'Antibiyotik', 'Covi-19 Aşısı', 'Kanser İlacı'], 12e9), 
      _buildFac('11', 'Elektronik Eşya', 200e15, false, ['Hesap Makinesi', 'Telefon', 'Televizyon', 'İnsansız Hava Aracı', 'Kuantum PC'], 380e9), 
      _buildFac('12', 'Yapay Zeka Ar-Ge', 12e18, false, ['Sohbet Botu', 'Satranç Botu', 'Görsel Oluşturma Botu', 'Kodlama Botu', 'Humanoid Robot'], 12e12), 
      _buildFac('13', 'Enerji Santrali', 800e18, false, ['Güneş Paneli', 'Rüzgar Tribünü', 'Nükleer Santral', 'Parçacık Hızlandırıcı', 'Füzyon Çekirdeği'], 400e12), 
      _buildFac('14', 'Biyoteknoloji', 60e21, false, ['Kök Hücre', '3D Biyo-Yazıcı', 'Biyonik Organ', 'Biyoçip', 'Klon Canlı'], 15e15), 
      _buildFac('15', 'Uzay Sanayii', 500e27, false, ['Roket Motoru', 'Uydu', 'Uzay Mekiği', 'Ay İniş Aracı', 'Yıldız Gemisi'], 750e15),
    ];
  }

  FactoryData _buildFac(String id, String n, double pr, bool unl, List<String> pNames, double bInc) {
    List<FactoryProduct> prods = [];
    for(int i = 0; i < pNames.length; i++) {
       double inc = bInc * math.pow(2.5, i); 
       prods.add(FactoryProduct(name: pNames[i], baseIncome: inc, baseCost: inc * 12.0, level: (unl && i == 0) ? 1 : 0)); 
    }
    return FactoryData(id: id, name: n, price: pr, isUnlocked: unl, products: prods);
  }

  void _loadFactoriesFromJson(dynamic savedList) {
    _initDefaultFactories(); 
    if (savedList != null) {
      for (var saved in savedList) {
        try { 
          var fac = _factories.firstWhere((f) => f.id == saved['id']); 
          fac.isUnlocked = saved['isUnlocked'] == true;
          for (int i = 0; i < fac.products.length; i++) { 
            if (i < saved['products'].length) { 
              fac.products[i].level = ((saved['products'][i]['level'] as num?)?.toInt() ?? 0).clamp(0, 60);
            } 
          } 
        } catch (_) {}
      }
    }
  }

  void _initDefaultResearchNodes() {
    _researchNodes = [
      _n('node_001', 'Holding Beratı', 'Temel', 'Tüm fabrikaların taban üretim gelirini kalıcı olarak artırır.', Icons.account_balance_rounded, 1, 1, [], (lvl) => 'Tüm Fabrika Taban Geliri: +%${lvl * 3}', currentLevel: 1),
      _n('node_002', 'Ağır Sanayi Doktrini', 'Sanayi', 'Fabrika geliştirme maliyetlerini kalıcı olarak düşürür.', Icons.factory_rounded, 2, 5, ['node_001'], (lvl) => 'Fabrika Geliştirme Maliyeti: -%${lvl * 3}'),
      _n('node_003', 'Mobilya Seri Üretimi', 'Fabrika', 'Mobilya fabrikası üretim hattının kârını artırır.', Icons.chair_rounded, 3, 5, ['node_002'], (lvl) => 'Mobilya Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_004', 'Pastörizasyon Hatları', 'Fabrika', 'Süt ürünleri fabrikası üretim hattının kârını artırır.', Icons.local_drink_rounded, 3, 5, ['node_002'], (lvl) => 'Süt Ürünleri Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_005', 'Otomatik Sulama', 'Fabrika', 'Tarım fabrikası üretim hattının kârını artırır.', Icons.agriculture_rounded, 4, 5, ['node_003'], (lvl) => 'Tarım Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_006', 'Gıda Seri Üretimi', 'Fabrika', 'Gıda işleme tesisinin üretim hattı kârını artırır.', Icons.restaurant_rounded, 4, 5, ['node_003'], (lvl) => 'Gıda İşleme Geliri: +%${lvl * 5}'),
      _n('node_007', 'Mekanik Dokuma', 'Fabrika', 'Tekstil fabrikası üretim hattının kârını artırır.', Icons.checkroom_rounded, 4, 5, ['node_004'], (lvl) => 'Tekstil Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_008', 'Karoser Robot Hattı', 'Fabrika', 'Otomobil fabrikası üretim hattının kârını artırır.', Icons.directions_car_rounded, 4, 5, ['node_004'], (lvl) => 'Otomobil Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_009', 'Derin Kuyu Sondajı', 'Fabrika', 'Maden fabrikası üretim hattının kârını artırır.', Icons.landslide_rounded, 5, 5, ['node_005'], (lvl) => 'Maden Fabrikası Geliri: +%${lvl * 6}'),
      _n('node_010', 'Yarı İletken Baskı', 'Fabrika', 'Elektronik fabrikası üretim hattının kârını artırır.', Icons.memory_rounded, 5, 5, ['node_006'], (lvl) => 'Elektronik Fabrikası Geliri: +%${lvl * 6}'),
      _n('node_011', 'Nöral Ağ Optimizasyonu', 'Fabrika', 'Yapay zeka geliştirme fabrikasının kârını artırır.', Icons.psychology_rounded, 6, 5, ['node_007'], (lvl) => 'Yapay Zeka Fabrikası Geliri: +%${lvl * 7}'),
      _n('node_012', 'Genetik Rekombinasyon', 'Fabrika', 'Biyoteknoloji fabrikası üretim hattının kârını artırır.', Icons.biotech_rounded, 6, 5, ['node_008'], (lvl) => 'Biyoteknoloji Fabrikası Geliri: +%${lvl * 7}'),
      _n('node_013', 'Tokamak Manyetik Alanı', 'Fabrika', 'Füzyon enerji fabrikası üretim hattının kârını artırır.', Icons.bolt_rounded, 7, 5, ['node_009', 'node_010'], (lvl) => 'Füzyon Enerji Fabrikası Geliri: +%${lvl * 8}'),
      _n('node_014', 'Yörünge İtki Sistemleri', 'Fabrika', 'Uzay sanayii fabrikası üretim hattının kârını artırır.', Icons.rocket_launch_rounded, 8, 5, ['node_011', 'node_012'], (lvl) => 'Uzay Sanayii Fabrikası Geliri: +%${lvl * 10}'),
      _n('node_015', 'Sanayi Kartel Sinerjisi', 'Sanayi', 'Tüm 15 fabrikanın taban gelirine toplu çarpan sağlar.', Icons.hub_rounded, 10, 3, ['node_013', 'node_014'], (lvl) => 'Tüm 15 Fabrikanın Geliri: +%${lvl * 10}'),
      _n('node_016', 'İndirimli Tedarik', 'Maliyet', 'Fabrika geliştirme maliyet çarpanını tabandan aşağı çeker.', Icons.trending_down_rounded, 4, 3, ['node_002'], (lvl) => 'Maliyet Çarpanı: ${(1.15 - lvl * 0.005).toStringAsFixed(3)}x'),
      _n('node_017', 'Toplu Malzeme Siparişi', 'Maliyet', 'Toplu alım anlaşmaları ile tesis geliştirme maliyetini kırar.', Icons.shopping_cart_rounded, 6, 3, ['node_016'], (lvl) => 'Ekstra Geliştirme İndirimi: -%${lvl * 4}'),
      _n('node_018', 'Küresel Tedarik Zinciri', 'Maliyet', 'Uluslararası navlun anlaşmaları ile kurulum masraflarını düşürür.', Icons.public_rounded, 8, 3, ['node_017'], (lvl) => 'Tesis Kurulum Maliyet İndirimi: -%${lvl * 6}'),
      _n('node_019', 'Üretim Standartlaşması', 'Kazanç', 'Üretme kazancı çarpanını taban değerin üzerine çıkarır.', Icons.trending_up_rounded, 5, 3, ['node_016'], (lvl) => 'Üretme Kazancı Çarpanı: ${(1.03 + lvl * 0.002).toStringAsFixed(3)}x'),
      _n('node_020', 'Yalın Kaizen Felsefesi', 'Kazanç', 'Sürekli iyileştirme prensibi ile ürün katsayılarını yükseltir.', Icons.speed_rounded, 7, 3, ['node_021'], (lvl) => 'Ürün Üretim Kazanç Bonusu: +%${lvl * 5}'),
      _n('node_021', 'Sürekli Akış Bandı', 'Pasif', 'Saniyelik pasif gelir oranını üretim kazancının yarısından yukarı taşır.', Icons.timer_rounded, 6, 3, ['node_019'], (lvl) => 'Saniyelik Gelir Oranı: %${50 + lvl * 3}'),
      _n('node_022', 'Vardiyasız Çalışma', 'Pasif', 'Tesislerin saniyelik pasif gelir akışını kademeli artırır.', Icons.all_inclusive_rounded, 8, 3, ['node_021'], (lvl) => 'Saniyelik Pasif Gelir İlavesi: +%${lvl * 3}'),
      _n('node_023', 'Tam Otonom Tesis', 'Pasif', 'İnsansız üretim ile saniyelik gelir çarpanını katlar.', Icons.smart_toy_rounded, 12, 3, ['node_022'], (lvl) => 'Otonom Pasif Gelir Çarpanı: +%${lvl * 10}'),
      _n('node_024', 'Hurda Değerleme', 'Verim', 'Üretim artıklarını değerlendirerek holding gelirini artırır.', Icons.recycling_rounded, 4, 2, ['node_023'], (lvl) => 'Holding Gelir Bonusu: +%${lvl * 2}'),
      _n('node_025', 'Sigortalı Operasyon', 'Verim', 'Operasyon kayıplarını azaltarak net geliri yükseltir.', Icons.shield_rounded, 6, 2, ['node_024'], (lvl) => 'Holding Gelir Bonusu: +%${lvl * 3}'),
      _n('node_026', 'Kentsel Dönüşüm', 'Verim', 'Tesis çevresindeki altyapı yatırımları üretkenliği artırır.', Icons.location_city_rounded, 8, 2, ['node_025'], (lvl) => 'Holding Gelir Bonusu: +%${lvl * 4}'),
      _n('node_027', 'Sıfır Kayıp Protokolü', 'Verim', 'Üretim kayıplarını en aza indirerek kalıcı gelir sağlar.', Icons.price_check_rounded, 12, 1, ['node_026'], (lvl) => 'Holding Gelir Bonusu: +%5'),
      _n('node_028', '2. Ürün Ar-Ge\'si', 'Ürün', 'Lvl 30\'da açılan 2. ürünlerin üretim kazancını artırır.', Icons.auto_awesome_motion_rounded, 6, 3, ['node_027'], (lvl) => '2. Ürün Üretim Kazancı: +%${lvl * 10}'),
      _n('node_029', '3. Ürün İmalatı', 'Ürün', 'Lvl 60\'ta açılan 3. ürünlerin üretim kazancını artırır.', Icons.layers_rounded, 8, 3, ['node_028'], (lvl) => '3. Ürün Üretim Kazancı: +%${lvl * 15}'),
      _n('node_030', '4. Ürün Montajı', 'Ürün', 'Lvl 90\'da açılan 4. ürünlerin üretim kazancını artırır.', Icons.view_in_ar_rounded, 10, 3, ['node_029'], (lvl) => '4. Ürün Üretim Kazancı: +%${lvl * 20}'),
      _n('node_031', '5. Amiral Gemisi', 'Ürün', 'Lvl 120\'de açılan 5. ürünlerin üretim kazancını artırır.', Icons.star_rounded, 14, 3, ['node_030'], (lvl) => '5. Ürün Üretim Kazancı: +%${lvl * 25}'),
      _n('node_032', 'Kalıp Standardizasyonu', 'Ürün', 'Yeni açılan ürünlerin ilk seviye geliştirme masrafını düşürür.', Icons.architecture_rounded, 10, 2, ['node_031'], (lvl) => 'Yeni Ürün Başlangıç Maliyeti: -%${lvl * 15}'),
      _n('node_033', 'İK İşe Alım Ağı', 'Yönetim', 'Fabrikalara yönetici atama ve sözleşme bedelini azaltır.', Icons.badge_rounded, 5, 3, ['node_032'], (lvl) => 'Yönetici Atama Maliyeti: -%${lvl * 10}'),
      _n('node_034', 'Headhunter Sözleşmesi', 'Yönetim', 'Üst düzey yönetici transfer masraflarını düşürür.', Icons.person_search_rounded, 8, 3, ['node_033'], (lvl) => 'Yönetici Lisans İndirimi: -%${lvl * 15}'),
      _n('node_035', 'Usta Başı Disiplini', 'Yönetim', '1. yöneticinin fabrikaya sağladığı üretim gelirini artırır.', Icons.engineering_rounded, 6, 3, ['node_034'], (lvl) => '1. Yönetici Gelir Gücü: +%${lvl * 12}'),
      _n('node_036', 'Tesis Müdürü', 'Yönetim', '2. yöneticinin fabrikadaki maliyet indirim etkisini artırır.', Icons.manage_accounts_rounded, 8, 3, ['node_035'], (lvl) => '2. Yönetici İndirim Gücü: +%${lvl * 15}'),
      _n('node_037', 'Genel Koordinatör', 'Yönetim', '3. yöneticinin üretim hızlandırma çarpanını artırır.', Icons.supervisor_account_rounded, 10, 3, ['node_036'], (lvl) => '3. Yönetici Hız Çarpanı: +%${lvl * 20}'),
      _n('node_038', 'Plaza Mimari Dönüşümü', 'Yönetim', 'Yazıhaneden plazaya geçişte yöneticileri güçlendirir.', Icons.apartment_rounded, 16, 1, ['node_037'], (lvl) => 'Plaza Yöneticilerine Kalıcı Güçlendirme: +%25'),
      _n('node_039', 'İmar Ruhsatı (1-4)', 'Arsa', '1-4 numaralı sanayi arsalarının satın alma bedelini düşürür.', Icons.map_rounded, 6, 2, ['node_038'], (lvl) => '1-4 Nolu Arsa Maliyeti: -%${lvl * 15}'),
      _n('node_040', 'Sanayi Teşviki (5-8)', 'Arsa', '5-8 numaralı sanayi arsalarının satın alma bedelini düşürür.', Icons.landscape_rounded, 8, 2, ['node_039'], (lvl) => '5-8 Nolu Arsa Maliyeti: -%${lvl * 20}'),
      _n('node_041', 'Serbest Bölge (9-15)', 'Arsa', '9-15 numaralı ileri sanayi arsalarının satın alma bedelini düşürür.', Icons.domain_add_rounded, 12, 2, ['node_040'], (lvl) => '9-15 Nolu Arsa Maliyeti: -%${lvl * 25}'),
      _n('node_042', '15 Parsel Tam Kapasite', 'Arsa', 'Tüm 15 parsel faaliyete geçtiğinde büyük holding kârı verir.', Icons.select_all_rounded, 18, 1, ['node_041'], (lvl) => '15 Arsa Dolduğunda Toplam Holding Geliri: +%30'),
      _n('node_043', 'Seviye 50 Eşiği', 'Seviye', 'Lvl 50\'ye ulaşan her fabrika tüm holdinge ek getiri sağlar.', Icons.looks_one_rounded, 6, 2, ['node_042'], (lvl) => 'Lvl 50 Fabrika Başına Holding Geliri: +%${lvl * 2}'),
      _n('node_044', 'Seviye 100 Eşiği', 'Seviye', 'Lvl 100\'e ulaşan her fabrika tüm holdinge ek getiri sağlar.', Icons.looks_two_rounded, 8, 2, ['node_043'], (lvl) => 'Lvl 100 Fabrika Başına Holding Geliri: +%${lvl * 3}'),
      _n('node_045', 'Seviye 150 Eşiği', 'Seviye', 'Lvl 150\'ye ulaşan fabrikaların geliştirme maliyetini kırar.', Icons.looks_3_rounded, 10, 2, ['node_044'], (lvl) => 'Lvl 150 Fabrika Maliyet İndirimi: -%${lvl * 2}'),
      _n('node_046', 'Seviye 200 Eşiği', 'Seviye', 'Lvl 200\'e ulaşan her fabrika için büyük üretim primi verir.', Icons.looks_4_rounded, 12, 2, ['node_045'], (lvl) => 'Lvl 200 Fabrika Gelir Bonusu: +%${lvl * 5}'),
      _n('node_047', 'Seviye 250 Eşiği', 'Seviye', 'Lvl 250 fabrikalar prestij tasfiyesinde ilave RP üretir.', Icons.looks_5_rounded, 16, 2, ['node_046'], (lvl) => 'Lvl 250 Fabrika Prestij RP Katkısı: +%${lvl * 3}'),
      _n('node_048', 'Seviye 300 Maksimum', 'Seviye', 'Fabrika 300. seviyeye ulaştığında saf kâr çarpanı kilitlenir.', Icons.workspace_premium_rounded, 25, 1, ['node_047'], (lvl) => 'Lvl 300 Fabrikaya Özel Saf 2.0x Gelir Çarpanı'),
      _n('node_049', 'Çırak-Usta Tasarımı', 'Seviye', 'Her 50 seviye görsel değişiminde geçici üretim takviyesi verir.', Icons.palette_rounded, 12, 2, ['node_048'], (lvl) => 'Görsel Değişim Gelir Boost: ${(1.0 + lvl * 0.25).toStringAsFixed(2)}x'),
      _n('node_050', 'Sanayi Sütun Zirvesi', 'Apex Kol 1', 'Kol 1 Apex: Tüm fabrikaların taban üretim katsayısını kalıcı katlar.', Icons.military_tech_rounded, 40, 1, ['node_049'], (lvl) => 'Sanayi Sütun Zirvesi: Taban Gelir Kalıcı +%50'),
      _n('node_051', 'Finansal Mühendislik', 'Finans', '5 saatte bir tahakkuk eden temel vergi borcu oranını düşürür.', Icons.account_balance_wallet_rounded, 2, 5, ['node_001'], (lvl) => 'Vergi Borcu Oranı: %${(10.0 - lvl * 0.2).toStringAsFixed(1)}'),
      _n('node_052', 'Gider Muhasebesi', 'Vergi', 'Verginin tahakkuk etme periyodunu uzatarak nakit akışını rahatlatır.', Icons.receipt_long_rounded, 4, 3, ['node_051'], (lvl) => 'Vergi Tahakkuk Periyodu: ${(5.0 + lvl * 0.5).toStringAsFixed(1)} Saat'),
      _n('node_053', 'Kurumlar Vergisi Muafiyeti', 'Vergi', 'Hesaplanan toplam vergi borcundan doğrudan kesinti yapar.', Icons.security_rounded, 6, 3, ['node_052'], (lvl) => 'Vergi Borcu İndirim Kalkanı: -%${lvl * 3}'),
      _n('node_054', 'Holding Vergi Tavanı', 'Vergi', 'Vergi borcu oranını en dip seviyeye kilitler.', Icons.verified_user_rounded, 10, 1, ['node_053'], (lvl) => 'Vergi Oranı Taban Sınırı: %8.0 (Kilitli)'),
      _n('node_055', 'Sadık Mükellef Primi', 'Vergi', '12 saat içinde ödenen verginin sağladığı gelir bonusunu artırır.', Icons.alarm_on_rounded, 4, 3, ['node_054'], (lvl) => 'Erken Ödeme Gelir Bonusu: %${20 + lvl * 3}'),
      _n('node_056', 'Mali Teşvik Protokolü', 'Vergi', 'Erken vergi ödeme bonusunun aktif kalma süresini uzatır.', Icons.hourglass_top_rounded, 6, 3, ['node_055'], (lvl) => 'Erken Ödeme Bonus Süresi: ${30 + lvl * 10} Dakika'),
      _n('node_057', 'Altın Mükellef Rozeti', 'Vergi', 'Vergisini aksatmayan holdinge ilave gelir çarpanı sağlar.', Icons.stars_rounded, 10, 2, ['node_056'], (lvl) => 'Erken Ödeme İlave Çarpanı: +%${lvl * 10}'),
      _n('node_058', 'Uzlaşma Masası', 'Vergi', '12 saat ödenmeyen vergide saat başı işleyen faiz oranını kırar.', Icons.handshake_rounded, 6, 2, ['node_057'], (lvl) => 'Saat Başı Gecikme Faizi: %${(0.10 - lvl * 0.02).toStringAsFixed(2)}'),
      _n('node_059', 'Haciz Erteleme Kararı', 'Vergi', 'En değerli fabrikanın haciz ile satılma süresini uzatır.', Icons.gavel_rounded, 8, 2, ['node_058'], (lvl) => 'Fabrika Haciz Erteleme Süresi: ${72 + lvl * 24} Saat'),
      _n('node_060', 'Vergi Barışı Lobiciliği', 'Vergi', 'Çark çevrildiğinde vergi affı çıkma olasılığını yükseltir.', Icons.campaign_rounded, 12, 2, ['node_059'], (lvl) => 'Çarktan Vergi Affı Çıkma Şansı: +%${lvl * 25}'),
      _n('node_061', 'Broker Lisansı', 'Borsa', 'Borsada hisse satarken kesilen işlem komisyonunu düşürür.', Icons.candlestick_chart_rounded, 4, 3, ['node_060'], (lvl) => 'Borsa Satış Komisyonu: %${(0.50 - lvl * 0.08).toStringAsFixed(2)}'),
      _n('node_062', 'Doğrudan Piyasa Erişimi', 'Borsa', 'Aracı komisyonlarını daha da aşağı çeker.', Icons.query_stats_rounded, 6, 3, ['node_061'], (lvl) => 'Satış Komisyonu İlave İndirimi: -%${(lvl * 0.05).toStringAsFixed(2)}'),
      _n('node_063', 'Kurumsal İletim Masası', 'Borsa', 'Hisse senedi alımlarında doğrudan komisyon iadesi üretir.', Icons.broadcast_on_personal_rounded, 8, 3, ['node_062'], (lvl) => 'Hisse Alım Nakit İadesi: %${(lvl * 0.2).toStringAsFixed(1)}'),
      _n('node_064', 'Sıfır Komisyon Ayrıcalığı', 'Borsa', 'Borsa komisyon oranını taban seviyeye sabitler.', Icons.money_off_rounded, 12, 1, ['node_063'], (lvl) => 'Minimum Komisyon: %0.10 (Kilitli)'),
      _n('node_065', 'Piyasa Derinliği', 'Borsa', '7 şirketin 5 saniyede bir işleyen %51 kâr eğilimini artırır.', Icons.trending_up_rounded, 6, 3, ['node_064'], (lvl) => '7 Şirketin Kâr Eğilimi: %${(51.0 + lvl * 0.4).toStringAsFixed(1)}'),
      _n('node_066', 'Algoritmik Fiyatlama', 'Borsa', 'Hisselerin kâr artış hızını ve getiri tavanını büyütür.', Icons.terminal_rounded, 8, 3, ['node_065'], (lvl) => 'Hisse Değer Artış İvmesi: +%${lvl * 5}'),
      _n('node_067', 'Piyasa Yapıcı Tekeli', 'Borsa', 'Borsa şirketlerinin kâr olasılığını zirveye taşır.', Icons.balance_rounded, 14, 2, ['node_066'], (lvl) => 'Hisse Kâr Eğilimi Tavanı: %${(52.2 + lvl * 0.4).toStringAsFixed(1)}'),
      _n('node_068', 'Portföy Temettü Havuzu', 'Borsa', 'Elde tutulan hisselerden saat başı pasif nakit üretir.', Icons.savings_rounded, 8, 3, ['node_067'], (lvl) => 'Saatlik Pasif Temettü Getirisi: %${(lvl * 0.2).toStringAsFixed(1)}'),
      _n('node_069', 'İmtiyazlı Borsa Payı', 'Borsa', 'Saatlik hisse temettü oranını kademeli yükseltir.', Icons.card_membership_rounded, 12, 2, ['node_068'], (lvl) => 'Saatlik Hisse Temettü Oranı: +%${(lvl * 0.3).toStringAsFixed(1)}'),
      _n('node_070', 'SVG Terminal Analitiği', 'Borsa', 'SVG grafiğinde dipten alımlarda sermaye primi sağlar.', Icons.show_chart_rounded, 16, 1, ['node_069'], (lvl) => 'Dipten Alımlarda Anında %5 Sermaye Primi'),
      _n('node_071', 'Yatırımcı Çantası', 'Fırsat', 'Ekranda beliren para çantasındaki nakit miktarını artırır.', Icons.business_center_rounded, 4, 3, ['node_070'], (lvl) => 'Para Çantası Nakit Artışı: +%${lvl * 25}'),
      _n('node_072', 'Girişim Sermayesi', 'Fırsat', 'Para çantasındaki ödül miktarını ek çarpanla büyütür.', Icons.work_rounded, 6, 3, ['node_071'], (lvl) => 'Para Çantası Nakit Çarpanı: +%${lvl * 30}'),
      _n('node_073', 'Melek Yatırımcı Ziyareti', 'Fırsat', 'Para çantasının ekranda daha sık çıkmasını sağlar.', Icons.timer_3_rounded, 8, 3, ['node_072'], (lvl) => 'Para Çantası Çıkış Sıklığı: +%${lvl * 20}'),
      _n('node_074', 'Altın Şans Çarkı', 'Çark', 'Çarktaki nakit ödüllerin taban büyüklüğünü artırır.', Icons.casino_rounded, 6, 3, ['node_073'], (lvl) => 'Çark Nakit Ödül Taban Değeri: +%${lvl * 25}'),
      _n('node_075', 'Büyük İkramiye Odası', 'Çark', 'Çarkta 3x çanta ve 2x boost gelme olasılığını yükseltir.', Icons.auto_awesome_rounded, 10, 2, ['node_074'], (lvl) => '3x Çanta & 2x Boost Şans Artışı: +%${lvl * 20}'),
      _n('node_076', 'Enerji Takviyesi', 'Boost', '3 dakikalık 2x gelir boost süresini uzatır.', Icons.battery_charging_full_rounded, 6, 2, ['node_075'], (lvl) => '2x Gelir Boost Süresi: ${3 + lvl} Dakika'),
      _n('node_077', 'Vardiya Seferberliği', 'Boost', '2x gelir boost süresine ilave dakikalar ekler.', Icons.more_time_rounded, 8, 2, ['node_076'], (lvl) => 'Boost Süresi İlavesi: +$lvl Dakika'),
      _n('node_078', 'Aşırı Yükleme', 'Boost', '2x boost çarpanının katsayısını kalıcı olarak artırır.', Icons.electric_bolt_rounded, 14, 1, ['node_077'], (lvl) => 'Gelir Boost Çarpanı Kalıcı 2.5x Olarak Uygulanır'),
      _n('node_079', 'Acil Durum Fonu', 'Kriz', 'Lojistik krizini parayla önleme bedelini düşürür.', Icons.emergency_rounded, 5, 3, ['node_078'], (lvl) => 'Kriz Önleme Bedeli İndirimi: -%${lvl * 20}'),
      _n('node_080', 'Kriz Sigortası', 'Kriz', 'Lojistik krizini savuşturma masraflarını kırar.', Icons.health_and_safety_rounded, 8, 2, ['node_079'], (lvl) => 'Kriz Önleme Ek İndirimi: -%${lvl * 25}'),
      _n('node_081', 'Hızlı Kriz Çözümü', 'Kriz', 'Kabul edilen krizlerin süresini kısaltır.', Icons.timelapse_rounded, 10, 2, ['node_080'], (lvl) => 'Kriz Süresi: -$lvl Dakika'),
      _n('node_082', 'Dış Ticaret Ataşeliği', 'Fırsat', 'Olumlu piyasa olaylarının gelir çarpanını artırır.', Icons.flight_takeoff_rounded, 6, 3, ['node_081'], (lvl) => 'Olumlu Olay Geliri: +%${lvl * 5}'),
      _n('node_083', 'İhracat Koridoru', 'Fırsat', 'Olumlu piyasa olaylarının aktif kalma süresini uzatır.', Icons.local_shipping_rounded, 8, 2, ['node_082'], (lvl) => 'Olumlu Olay Süresi: +${lvl * 5} Dakika'),
      _n('node_084', 'Global Pazar Radarı', 'Fırsat', 'Ekrana gelen fırsat ve krizlerin sıklığını artırır.', Icons.radar_rounded, 12, 2, ['node_083'], (lvl) => 'Fırsat & Kriz Belirme Sıklığı: +%${lvl * 25}'),
      _n('node_085', 'Otonom Gece Vardiyası', 'AFK', 'Oyunda değilken kazanılan saniyelik geliri artırır.', Icons.bedtime_rounded, 6, 3, ['node_084'], (lvl) => 'Çevrimdışı Saniyelik Gelir Bonusu: +%${lvl * 20}'),
      _n('node_086', 'Kasa Birikim Deposu', 'AFK', 'Çevrimdışı gelir toplama süresi sınırını uzatır.', Icons.lock_clock_rounded, 8, 2, ['node_085'], (lvl) => 'Maksimum Çevrimdışı Süre: ${6 + lvl * 3} Saat'),
      _n('node_087', 'Sürekli Holding Faaliyeti', 'AFK', 'Çevrimdışı süre sınırına ilave saatler ekler.', Icons.update_rounded, 12, 2, ['node_086'], (lvl) => 'Çevrimdışı Süre İlavesi: +${lvl * 4} Saat'),
      _n('node_088', 'Sponsorlu Üçlü Kazanç', 'AFK', 'Dönüşte reklamla alınan 2x çevrimdışı bonusunu 3x yapar.', Icons.video_call_rounded, 16, 1, ['node_087'], (lvl) => 'Reklamla Alınan 2x AFK Bonusu 3x Olarak Verilir'),
      _n('node_089', 'Prestij Ar-Ge İvmesi', 'Prestij', '100 Qi prestijinde ciroya oranla kazanılan RP miktarını artırır.', Icons.science_rounded, 10, 3, ['node_088'], (lvl) => 'Kazanılan Ar-Ge Puanı (RP): +%${lvl * 15}'),
      _n('node_090', 'Patent Konsorsiyumu', 'Prestij', 'Prestij tasfiyesinde kazanılan RP\'ye ek çarpan sağlar.', Icons.biotech_rounded, 14, 3, ['node_089'], (lvl) => 'Kazanılan RP İlavesi: +%${lvl * 25}'),
      _n('node_091', 'Düşünce Kuruluşu', 'Prestij', 'Prestij tasfiyesinden gelen RP çarpanını ikiye katlar.', Icons.psychology_alt_rounded, 20, 2, ['node_090'], (lvl) => 'Kazanılan RP Çarpanı: +%${lvl * 50}'),
      _n('node_092', 'Melek Sermaye Mirası', 'Prestij', 'Prestij yapıp sıfırlandıktan sonra hazır nakit hibesi verir.', Icons.monetization_on_rounded, 10, 2, ['node_091'], (lvl) => 'Başlangıç Nakit Hibesi: \$${lvl * 1000000}'),
      _n('node_093', 'Hazır Arsa Hibesi', 'Prestij', 'Prestij sonrası sanayi arsalarının bedelsiz açık başlamasını sağlar.', Icons.add_business_rounded, 14, 2, ['node_092'], (lvl) => 'Prestij Sonrası İlk ${lvl * 2} Arsa Bedelsiz Açık'),
      _n('node_094', 'Endüstriyel Miras', 'Prestij', 'Prestij sonrası ilk fabrikayı seviyesi ve 2. ürünü açık başlatır.', Icons.corporate_fare_rounded, 18, 1, ['node_093'], (lvl) => 'İlk Fabrika Doğrudan Seviye 30 Başlar'),
      _n('node_095', 'Girişimci Unvanı', 'Unvan', 'Kazanılan her ciro rütbesi için kalıcı ciro primi sağlar.', Icons.military_tech_outlined, 12, 2, ['node_094'], (lvl) => 'Her Ciro Rütbesi İçin Gelir Bonusu: +%${lvl * 5}'),
      _n('node_096', 'Galaktik Tycoon', 'Unvan', 'Lvl 6 Galaktik Tycoon ve üzeri rütbelere dev gelir çarpanı verir.', Icons.military_tech_sharp, 18, 2, ['node_095'], (lvl) => 'Lvl 6+ Rütbelere Özel Gelir Çarpanı: +%${lvl * 10}'),
      _n('node_097', '10^33 İvmelendiricisi', 'Unvan', '10^33 unvanına yaklaşırken gelir çarpanlarını katlar.', Icons.all_inclusive_rounded, 25, 1, ['node_096'], (lvl) => '10^33 Hedefine Yaklaşırken Ciro Katsayıları 1.5x Katlanır'),
      _n('node_098', 'Otomatik Tasfiye Protokolü', 'Prestij', 'Prestij yaparken vergi borcu engelini tek tuşla otomatik çözer.', Icons.assignment_turned_in_rounded, 20, 1, ['node_097'], (lvl) => 'Vergi Borcu Varsa Otomatik Affettirilir'),
      _n('node_099', 'Sermaye Sütun Zirvesi', 'Apex Kol 2', 'Kol 2 Apex: Borsa, kâr ve nakit akışını kalıcı olarak ikiye katlar.', Icons.account_balance_rounded, 40, 1, ['node_098'], (lvl) => 'Borsa ve Nakit Akışı Kalıcı 2.0x'),
      _n('node_100', 'Dünyaların Sahibi', 'Apex', '10^33 Ciroya Giden Zirve: Tüm sistemleri maksimum verimle taçlandırır.', Icons.diamond_rounded, 100, 1, ['node_050', 'node_099'], (lvl) => '10^33 Zirvesi: Maliyetler -%50, Saniyelik Gelir 5x ve Prestij RP Kazanımı 3x!'),
    ];
  }

  void _loadResearchFromJson(dynamic savedList) {
    _initDefaultResearchNodes(); 
    if (savedList != null) {
      for (var saved in savedList) {
        try {
          var node = _researchNodes.firstWhere((n) => n.id == saved['id']);
          node.currentLevel = ((saved['level'] as num?)?.toInt() ?? 0).clamp(0, node.maxLevel);
        } catch (_) {}
      }
    }
  }

  void _loadStocksFromJson(dynamic savedList) {
    _stocks = [
      Stock(id: '1', name: 'Redof Tech', icon: Icons.smart_toy_rounded, iconColor: Colors.blueAccent, currentPrice: 85.0, history: List.generate(40, (_) => 85.0)),
      Stock(id: '2', name: 'Anadolu Ağır Sanayi', icon: Icons.factory_rounded, iconColor: Colors.orangeAccent, currentPrice: 340.0, history: List.generate(40, (_) => 340.0)),
      Stock(id: '3', name: 'Titan Kimya', icon: Icons.science_rounded, iconColor: Colors.purpleAccent, currentPrice: 920.0, history: List.generate(40, (_) => 920.0)),
      Stock(id: '4', name: 'Nova Enerji', icon: Icons.bolt_rounded, iconColor: Colors.amberAccent, currentPrice: 2150.0, history: List.generate(40, (_) => 2150.0)),
      Stock(id: '5', name: 'Atlas Lojistik', icon: Icons.local_shipping_rounded, iconColor: Colors.tealAccent, currentPrice: 5400.0, history: List.generate(40, (_) => 5400.0)),
      Stock(id: '6', name: 'Apex Biyoteknoloji', icon: Icons.biotech_rounded, iconColor: Colors.greenAccent, currentPrice: 14200.0, history: List.generate(40, (_) => 14200.0)),
      Stock(id: '7', name: 'Vakıf Gayrimenkul', icon: Icons.apartment_rounded, iconColor: Colors.deepOrangeAccent, currentPrice: 38000.0, history: List.generate(40, (_) => 38000.0)),
      Stock(id: '8', name: 'Aura Yarı İletken', icon: Icons.memory_rounded, iconColor: Colors.cyanAccent, currentPrice: 95000.0, history: List.generate(40, (_) => 95000.0)),
      Stock(id: '9', name: 'Lunar Havacılık', icon: Icons.flight_takeoff_rounded, iconColor: Colors.indigoAccent, currentPrice: 260000.0, history: List.generate(40, (_) => 260000.0)),
      Stock(id: '10', name: 'Galaktik Madencilik', icon: Icons.rocket_launch_rounded, iconColor: Colors.pinkAccent, currentPrice: 850000.0, history: List.generate(40, (_) => 850000.0)),
      Stock(id: '11', name: 'Kuantum Finans', icon: Icons.account_balance_rounded, iconColor: Colors.blueGrey, currentPrice: 5.5e7, history: List.generate(40, (_) => 5.5e7)),
      Stock(id: '12', name: 'Neo-Tarım A.Ş.', icon: Icons.agriculture_rounded, iconColor: Colors.lightGreenAccent, currentPrice: 1.2e9, history: List.generate(40, (_) => 1.2e9)),
      Stock(id: '13', name: 'Giga İnşaat', icon: Icons.construction_rounded, iconColor: Colors.orange, currentPrice: 4.8e10, history: List.generate(40, (_) => 4.8e10)),
      Stock(id: '14', name: 'Siber Güvenlik', icon: Icons.security_rounded, iconColor: Colors.cyan, currentPrice: 2.5e12, history: List.generate(40, (_) => 2.5e12)),
      Stock(id: '15', name: 'Okyanus Madencilik', icon: Icons.water_drop_rounded, iconColor: Colors.blue, currentPrice: 1.8e14, history: List.generate(40, (_) => 1.8e14)),
      Stock(id: '16', name: 'Astro-Biyoloji', icon: Icons.biotech_rounded, iconColor: Colors.purple, currentPrice: 7.5e15, history: List.generate(40, (_) => 7.5e15)),
      Stock(id: '17', name: 'Nano-Medikal', icon: Icons.medical_services_rounded, iconColor: Colors.redAccent, currentPrice: 4.2e17, history: List.generate(40, (_) => 4.2e17)),
      Stock(id: '18', name: 'Yıldız Gemisi A.Ş.', icon: Icons.rocket_rounded, iconColor: Colors.deepPurpleAccent, currentPrice: 1.5e19, history: List.generate(40, (_) => 1.5e19)),
      Stock(id: '19', name: 'Galaktik Lojistik', icon: Icons.local_shipping_rounded, iconColor: Colors.amber, currentPrice: 5.8e19, history: List.generate(40, (_) => 5.8e19)),
      Stock(id: '20', name: 'Evrensel Enerji', icon: Icons.bolt_rounded, iconColor: Colors.yellowAccent, currentPrice: 1.2e20, history: List.generate(40, (_) => 1.2e20)),
    ];

    if (savedList != null) {
      for (var s in savedList) {
        try {
          var e = _stocks.firstWhere((st) => st.id == s['id']);
          e.currentPrice = (s['currentPrice'] as num).toDouble(); 
          e.history = List<double>.from((s['history'] as List).map((x) => (x as num).toDouble())); 
          e.ownedShares = (s['ownedShares'] as num).toDouble(); 
          e.totalSpent = (s['totalSpent'] as num).toDouble(); 
          if (!e.currentPrice.isFinite || e.currentPrice < 1) e.currentPrice = 1;
          e.history = e.history.where((value) => value.isFinite && value >= 1).take(40).toList();
          if (e.history.isEmpty) e.history = List<double>.filled(40, e.currentPrice);
          if (!e.ownedShares.isFinite || e.ownedShares < 0) e.ownedShares = 0;
          if (!e.totalSpent.isFinite || e.totalSpent < 0) e.totalSpent = 0;
        } catch (_) {}
      }
    }
  }

  void _startGlobalTimers() { 
    _gameTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) { 
      _processSecond(); 
    }); 
  }

  void _processSecond() {
    if (incomePerSecond > 0) {
      _money += incomePerSecond;
      statTotalEarned += incomePerSecond; 
    }
    final hourlyDividendRate = (_nodeLevel('node_068') * 0.002) + (_nodeLevel('node_069') * 0.003);
    if (hourlyDividendRate > 0) {
      final portfolioValue = _stocks.fold<double>(0, (sum, stock) => sum + stock.currentPrice * stock.ownedShares);
      var dividend = portfolioValue * hourlyDividendRate / 3600;
      if (_nodeLevel('node_099') > 0) dividend *= 2;
      _money += dividend;
      statTotalEarned += dividend;
    }
    
    if (DateTime.now().second % 5 == 0) {
      double analystBonus = _officeEffect('staff_4');
      for (var stock in _stocks) {
        double vol = ((_random.nextDouble() * 0.04) + 0.01) * (1.0 + _nodeLevel('node_066') * 0.05);
        final researchChance = (_nodeLevel('node_065') + _nodeLevel('node_067')) * 0.004;
        bool isProfit = _random.nextDouble() < (0.51 + analystBonus + researchChance).clamp(0.0, 0.65);
        stock.currentPrice *= (1 + (isProfit ? vol : -vol));
        if (stock.currentPrice < 1.0) stock.currentPrice = 1.0; 
        stock.history.add(stock.currentPrice);
        if (stock.history.length > 40) {
          stock.history.removeAt(0);
        }
      }
    }
    _checkTaxSystem();
    _checkRandomEvents();
    _checkNotifications();
    notifyListeners();
    if (DateTime.now().second % 10 == 0) {
      _saveGame(); 
    }
  }

  void _checkRandomEvents() {
    final now = DateTime.now();

    if (activeEvent != null && _eventEndTime != null && now.isAfter(_eventEndTime!)) {
      activeEvent = null; 
      _eventEndTime = null; 
      _saveGame(); 
    }

    // A brand-new holding gets a protected onboarding window. The timestamp is
    // persisted, so closing/reopening the app cannot reset or bypass the 30-minute
    // grace period. Legacy saves without this field keep their existing behavior.
    final bool worldEventsUnlocked = _newGameStartedAt == null ||
        !now.isBefore(_newGameStartedAt!.add(_newGameEventGracePeriod));

    if (worldEventsUnlocked) {
      final eventChance = 0.002 * (1.0 + _nodeLevel('node_084') * 0.25);
      if (baseIncomePerSecond > 0 && activeEvent == null && _unhandledEvent == null && _random.nextDouble() < eventChance) {
        int eventType = _random.nextInt(5);
        final positiveBonus = 1.0 + (_nodeLevel('node_082') * 0.05);
        final positiveDuration = _nodeLevel('node_083') * 5;
        final crisisCostFactor = (1.0 - (_nodeLevel('node_079') * 0.20) -
            (_nodeLevel('node_080') * 0.25)).clamp(0.1, 1.0);
        switch (eventType) {
          case 0:
            _unhandledEvent = GameEvent('Küresel Talep Patlaması', 'Ürünlerimize yoğun ilgi var!', 2.0 * positiveBonus, 2 + positiveDuration, 0);
            break;
          case 1:
            _unhandledEvent = GameEvent('Vergi İadesi Teşviki', 'Devlet teşviki onaylandı!', 2.5 * positiveBonus, 3 + positiveDuration, 0);
            break;
          case 2:
            _unhandledEvent = GameEvent('Sosyal Medya Virali', 'Ürünlerimiz trend oldu!', 3.0 * positiveBonus, 2 + positiveDuration, 0);
            break;
          case 3:
            _unhandledEvent = GameEvent('Lojistik Krizi', 'Liman grevleri gelirleri geçici olarak düşürecek.', 0.5, math.max(1, 3 - _nodeLevel('node_081')).toInt(), baseIncomePerSecond * 120 * crisisCostFactor);
            break;
          case 4:
            _unhandledEvent = GameEvent('Hammadde Ambargosu', 'Tedarik zinciri koptu; gelirler geçici olarak düşecek.', 0.4, math.max(1, 5 - _nodeLevel('node_081')).toInt(), baseIncomePerSecond * 180 * crisisCostFactor);
            break;
        }
      }
    }

    // Money bags are not world crises/opportunities, so they remain available
    // during the protected first 30 minutes.
    final bagChance = 0.005 * (1.0 + _nodeLevel('node_073') * 0.20);
    if (baseIncomePerSecond > 0 && _unhandledBagReward == 0 && _random.nextDouble() < bagChance) {
      _unhandledBagReward = baseIncomePerSecond * 300; 
    }
  }

  void resolveEvent(bool payToPrevent, GameEvent ev) {
    if (payToPrevent) { 
      if (_money < ev.preventCost) return;
      _money -= ev.preventCost;
    } else { 
      activeEvent = ev; 
      _eventEndTime = DateTime.now().add(Duration(minutes: ev.durationMinutes)); 
    }
    _saveGame(); 
    notifyListeners();
  }

  bool _sameGameEvent(GameEvent? a, GameEvent b) {
    if (a == null) return false;
    return a.title == b.title &&
        a.multiplier == b.multiplier &&
        a.durationMinutes == b.durationMinutes &&
        a.preventCost == b.preventCost;
  }

  bool isEventActiveFor(GameEvent ev) => isEventActive && _sameGameEvent(activeEvent, ev);

  /// Rewarded-ad resolution for world events.
  /// Crises are prevented for free (or removed if they already started after a timeout),
  /// while positive chances are activated immediately.
  void resolveEventWithAd(GameEvent ev) {
    final bool isCrisis = ev.preventCost > 0;
    if (isCrisis) {
      if (_sameGameEvent(activeEvent, ev)) {
        activeEvent = null;
        _eventEndTime = null;
      }
    } else {
      activeEvent = ev;
      _eventEndTime = DateTime.now().add(Duration(minutes: ev.durationMinutes));
    }
    _saveGame();
    notifyListeners();
  }

  void claimOfflineEarnings(bool watchAd) {
    if (offlineEarningsToClaim > 0) {
      double multiplier = 1.0;
      if (watchAd) {
         var n88 = _researchNodes.firstWhere((n) => n.id == 'node_088', orElse: () => _researchNodes[0]);
         multiplier = (n88.currentLevel > 0) ? 3.0 : 2.0;
      }
      
      double add = offlineEarningsToClaim * multiplier;
      _money += add; 
      statTotalEarned += add;
      offlineEarningsToClaim = 0; 
      _saveGame(); 
      notifyListeners(); 
    }
  }

  void claimBagReward(bool watchAd, double reward) { 
    double marketingBonus = 1.0 + _officeEffect('staff_5');
    final researchBonus = 1.0 + (_nodeLevel('node_071') * 0.25) + (_nodeLevel('node_072') * 0.30);
    double finalReward = reward * marketingBonus * researchBonus;
    if (_nodeLevel('node_099') > 0) finalReward *= 2;
    double add = watchAd ? (finalReward * 3) : finalReward;
    _money += add; 
    statTotalEarned += add;
    _saveGame(); 
    notifyListeners(); 
  }

  void activate2xBoost() { 
    final minutes = 3 + _nodeLevel('node_076') + _nodeLevel('node_077');
    final start = isBoostActive ? _boostEndTime! : DateTime.now();
    _boostEndTime = start.add(Duration(minutes: minutes));
    _saveGame(); 
    notifyListeners(); 
  }

  void _applyTimelyTaxBonus() {
    if (!_isUnderPenalty && taxRemainingSeconds > 0) {
      _taxBonusEndTime = DateTime.now().add(Duration(minutes: 30 + (_nodeLevel('node_056') * 10)));
    }
  }

  void applyTaxAmnesty() { 
    _applyTimelyTaxBonus();
    _currentTaxDebt = 0; 
    _isUnderPenalty = false; 
    _lastTaxIssued = DateTime.now(); 
    _taxDeadline = DateTime.now().add(const Duration(hours: 12)); 
    _lastPenaltyCompoundTime = null;
    _saveGame(); 
    notifyListeners(); 
  }

  void payTaxWithAd() {
    _applyTimelyTaxBonus();
    _currentTaxDebt = 0; 
    _isUnderPenalty = false; 
    statTaxes++; 
    _lastTaxIssued = DateTime.now(); 
    _taxDeadline = DateTime.now().add(const Duration(hours: 12)); 
    _lastPenaltyCompoundTime = null;
    _saveGame(); 
    notifyListeners(); 
  }

  void _checkTaxSystem() {
    final now = DateTime.now();
    final issueMinutes = 300 + (_nodeLevel('node_052') * 30);
    if (_lastTaxIssued != null && now.difference(_lastTaxIssued!).inMinutes >= issueMinutes && _currentTaxDebt == 0) {
      double taxRate = 0.10 - (_nodeLevel('node_051') * 0.002);
      taxRate -= _officeEffect('staff_1');
      if (_nodeLevel('node_054') > 0) taxRate = math.min(taxRate, 0.08);
      taxRate = taxRate.clamp(0.02, 0.10);
      
      _currentTaxDebt = (baseIncomePerSecond * issueMinutes * 60) * taxRate;
      _currentTaxDebt *= (1.0 - _nodeLevel('node_053') * 0.03).clamp(0.5, 1.0);
      _lastTaxIssued = now; 
      _taxDeadline = now.add(const Duration(hours: 12)); 
      _isUnderPenalty = false;
      _lastPenaltyCompoundTime = null;
      _saveGame(); 
    }
    
    if (_currentTaxDebt > 0 && _taxDeadline != null && now.isAfter(_taxDeadline!)) {
      if (!_isUnderPenalty) {
         _isUnderPenalty = true;
         _lastPenaltyCompoundTime = now;
         _saveGame(); 
      }
      
      if (_lastPenaltyCompoundTime != null && now.difference(_lastPenaltyCompoundTime!).inHours >= 1) {
        final penaltyRate = (0.001 - _nodeLevel('node_058') * 0.0002).clamp(0.0001, 0.001);
        _currentTaxDebt *= 1.0 + penaltyRate;
        _lastPenaltyCompoundTime = now;
        _saveGame();
      }

      final foreclosureHours = 72 + (_nodeLevel('node_059') * 24);
      if (now.difference(_taxDeadline!).inHours >= foreclosureHours) {
        _executeForeclosure(); 
      }
    }
  }

  void _executeForeclosure() {
    var unlockedFacs = _factories.where((f) => f.isUnlocked && f.id != _starterFactoryId).toList();
    if (unlockedFacs.isNotEmpty) {
      unlockedFacs.sort((a, b) => b.price.compareTo(a.price));
      unlockedFacs.first.isUnlocked = false;
      for (var p in unlockedFacs.first.products) {
        p.level = 0; 
      }
    } else { 
      _money = 0; 
    }
    _currentTaxDebt = 0; 
    _isUnderPenalty = false; 
    _lastTaxIssued = DateTime.now(); 
    _taxDeadline = DateTime.now().add(const Duration(hours: 12));
    _lastPenaltyCompoundTime = null;
    _saveGame(); 
  }

  void payTax() {
    if (_money >= _currentTaxDebt) { 
      _money -= _currentTaxDebt; 
      _applyTimelyTaxBonus();
      _currentTaxDebt = 0; 
      _isUnderPenalty = false; 
      statTaxes++; 
      _lastTaxIssued = DateTime.now(); 
      _taxDeadline = DateTime.now().add(const Duration(hours: 12)); 
      _lastPenaltyCompoundTime = null;
      _saveGame(); 
      notifyListeners(); 
    }
  }

  bool _manualProductionNotifyScheduled = false;

  void completeManualProduction(String facId, int productIndex) {
    final factory = _factories.firstWhere((f) => f.id == facId);
    if (productIndex < 0 || productIndex >= factory.products.length) return;
    var prod = factory.products[productIndex];
    const unlockLevels = <int>[0, 30, 60, 90, 120];
    if (!factory.isUnlocked || (prod.level == 0 && factory.totalLevel < unlockLevels[productIndex])) return;
    if (prod.level > 0) { 
      double add = prod.manualIncome * manualProductionMultiplier(facId, productIndex);
      _money += add; 
      statTotalEarned += add;
      statClicks++; 
      
      _checkNotifications();

      if (!_manualProductionNotifyScheduled) {
        _manualProductionNotifyScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _manualProductionNotifyScheduled = false;
          if (!_disposed) notifyListeners();
        });
      }
    }
  }

  bool unlockFactory(String facId) {
    var fac = _factories.firstWhere((f) => f.id == facId);
    final finalPrice = factoryUnlockCost(facId);

    if (finalPrice != null && _money >= finalPrice) {
      _money -= finalPrice; 
      fac.isUnlocked = true; 
      fac.products[0].level = 1; 
      _checkAchievementsUnlock();
      _saveGame(); 
      _checkNotifications();
      notifyListeners(); 
      return true;
    }
    return false;
  }

  void hireStaff(String staffId) {
    var staff = officeStaff.firstWhere((s) => s.id == staffId);
    double cost = staffCost(staff);
    if (!staff.isMaxed && _money >= cost) {
      _money -= cost;
      staff.level++;
      _saveGame(); 
      notifyListeners();
    }
  }

  void upgradeProduct(String facId, int productIndex) {
    final factory = _factories.firstWhere((f) => f.id == facId);
    if (productIndex < 0 || productIndex >= factory.products.length) return;
    var prod = factory.products[productIndex];
    final cost = productUpgradeCost(facId, productIndex);
    if (cost == null) return;

    if (_money >= cost) { 
      _money -= cost; 
      prod.level++; 
      statUpgrades++; 
      _checkAchievementsUnlock();
      _saveGame(); 
      _checkNotifications();
      notifyListeners(); 
    }
  }

  void upgradeResearch(String researchId) {
    var node = _researchNodes.firstWhere((n) => n.id == researchId);
    final parentsUnlocked = node.parentIds.every((parentId) {
      final parent = _researchNodes.firstWhere((n) => n.id == parentId);
      return parent.isUnlocked;
    });
    if (_researchPoints >= node.cost && !node.isMaxed && parentsUnlocked) {
      _researchPoints -= node.cost;
      node.currentLevel++;
      _saveGame();
      notifyListeners();
    }
  }

  void executePrestige() {
    final int earnedRP = calculateEarnableRP();
    if (earnedRP <= 0 || !canPrestige) return;
    if (hasTaxDebt && _nodeLevel('node_098') > 0) {
      _currentTaxDebt = 0;
      _isUnderPenalty = false;
    }
    _researchPoints += earnedRP; 
    statPrestige++;
    
    int node92Level = _researchNodes.firstWhere((n) => n.id == 'node_092', orElse: () => _researchNodes[0]).currentLevel;
    _money = node92Level * 1000000.0; 
    statTotalEarned += _money;
    
    int node93Level = _researchNodes.firstWhere((n) => n.id == 'node_093', orElse: () => _researchNodes[0]).currentLevel;
    int freePlots = node93Level * 2; 
    
    int node94Level = _researchNodes.firstWhere((n) => n.id == 'node_094', orElse: () => _researchNodes[0]).currentLevel;
    bool firstFacLevel30 = node94Level > 0; 
    
    for (int i = 0; i < _factories.length; i++) { 
      var f = _factories[i];
      f.isUnlocked = false; 
      for (var p in f.products) { p.level = 0; }
      
      if (['1', '2', '3'].contains(f.id)) {
        f.price = 300000.0;
      }
      
      if (f.id == _starterFactoryId) {
        f.isUnlocked = true;
        f.price = 0.0;
        if (firstFacLevel30) {
          f.products[0].level = 30;
          f.products[1].level = 1;
        } else {
          f.products[0].level = 1;
        }
      } else if (freePlots > 0) {
        f.isUnlocked = true;
        f.products[0].level = 1;
        freePlots--;
      }
    }
    
    for (var s in officeStaff) { s.level = 0; }
    for (var s in _stocks) { s.ownedShares = 0; s.totalSpent = 0; }
    
    _currentTaxDebt = 0;
    _isUnderPenalty = false;
    _lastTaxIssued = DateTime.now();
    _taxDeadline = DateTime.now().add(const Duration(hours: 12));
    _taxBonusEndTime = null;
    _lastPenaltyCompoundTime = null;
    _boostEndTime = null;
    activeEvent = null;
    _eventEndTime = null;
    _unhandledEvent = null;
    _unhandledBagReward = 0.0;

    _saveGame(); 
    _checkNotifications();
    notifyListeners();
  }

  void incrementAdsWatched() { statAdsWatched++; _saveGame(); _checkNotifications(); notifyListeners(); }
  void incrementWheelSpins() { statWheelSpins++; _saveGame(); _checkNotifications(); notifyListeners(); }
  
  Future<void> updateMoney(double amount) async { 
    if (!amount.isFinite) return;
    _money += amount; 
    if (amount > 0) statTotalEarned += amount;
    if (_money < 0) _money = 0; 
    await _saveGame(); 
    _checkNotifications();
    notifyListeners(); 
  }
  
  Future<void> updateResearchPoints(int amount) async { _researchPoints = math.max(0, _researchPoints + amount); await _saveGame(); notifyListeners(); }
  Future<void> setLanguage(String langCode) async {
    await TranslationService.instance.loadLanguage(langCode);
    _language = TranslationService.instance.currentLanguage;
    await _saveGame();
    notifyListeners();
  }

  Future<void> setDarkTheme(bool enabled) async {
    if (_useDarkTheme == enabled) return;
    _useDarkTheme = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_dark_theme', enabled);
    notifyListeners();
  }

  Future<void> completeFirstLaunch() async { _isFirstLaunch = false; await _saveGame(); notifyListeners(); }
  
  void buyStockWithAmount(String stockId, double inputAmount) {
    if (!inputAmount.isFinite || inputAmount <= 0) return;
    var s = _stocks.firstWhere((st) => st.id == stockId);
    if (inputAmount > _money) inputAmount = _money;
    if (inputAmount >= s.currentPrice) {
      double sharesToBuy = (inputAmount / s.currentPrice).floorToDouble();
      double totalCost = sharesToBuy * s.currentPrice;
      if (sharesToBuy > 0 && _money >= totalCost) {
        _money -= totalCost; 
        var cashback = totalCost * _nodeLevel('node_063') * 0.002;
        if (_nodeLevel('node_070') > 0 && s.history.isNotEmpty && s.currentPrice <= s.history.reduce((a, b) => math.min(a, b).toDouble()) * 1.05) {
          cashback += totalCost * 0.05;
        }
        _money += cashback;
        statTotalEarned += cashback;
        s.ownedShares += sharesToBuy; 
        s.totalSpent += totalCost; 
        statStocks++;
        _saveGame(); 
        _checkNotifications();
        notifyListeners(); 
      }
    }
  }
  
  void sellAllStock(String stockId) {
    var s = _stocks.firstWhere((st) => st.id == stockId);
    if (s.ownedShares > 0) { 
      var commissionRate = 0.005;
      commissionRate -= _nodeLevel('node_061') * 0.0008;
      commissionRate -= _nodeLevel('node_062') * 0.0005;
      commissionRate = commissionRate.clamp(_nodeLevel('node_064') > 0 ? 0.001 : 0.002, 0.005);
      double grossIncome = s.ownedShares * s.currentPrice * (1.0 - commissionRate);
      double netProfit = grossIncome - s.totalSpent;
      if (netProfit > 0 && _nodeLevel('node_099') > 0) {
        grossIncome += netProfit;
        netProfit *= 2;
      }
      
      _money += grossIncome; 
      if (netProfit > 0) {
        statTotalEarned += netProfit; 
      }
      
      s.ownedShares = 0; 
      s.totalSpent = 0; 
      statStocks++;
      _saveGame(); 
      _checkNotifications();
      notifyListeners(); 
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _gameTimer?.cancel();
    _gameTimer = null;
    super.dispose();
  }
}
