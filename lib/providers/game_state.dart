// lib/providers/game_state.dart
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

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

class FactoryProduct {
  String name; int level; double baseIncome; double baseCost;
  FactoryProduct({required this.name, this.level = 0, required this.baseIncome, required this.baseCost});
  double get manualIncome => level == 0 ? 0.0 : baseIncome * math.pow(1.3, level - 1);
  double get passiveIncome => manualIncome * 0.4; 
  double get upgradeCost => baseCost * math.pow(1.4, level);
  Map<String, dynamic> toJson() => {'name': name, 'level': level};
}

class FactoryData {
  final String id; final String name; final double price; bool isUnlocked; List<FactoryProduct> products;
  FactoryData({required this.id, required this.name, required this.price, this.isUnlocked = false, required this.products});
  int get totalLevel => products.fold(0, (sum, p) => sum + p.level);
  int get currentStage => totalLevel < 100 ? 0 : (totalLevel < 200 ? 1 : 2);
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
  double _money = 0.0; 
  int _researchPoints = 0;
  bool _isFirstLaunch = true;
  String _language = 'tr';

  List<FactoryData> _factories = [];
  List<ResearchNode> _researchNodes = [];
  
  // 50 SEVİYELİ PERSONEL YÖNETİM SİSTEMİ
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
  ];

  int statClicks = 0; int statStocks = 0; int statUpgrades = 0; int statTaxes = 0; int statPrestige = 0; int statAdsWatched = 0; int statWheelSpins = 0; 
  List<bool> claimedTasks = List.filled(4, false);
  List<bool> claimedAchievements = List.filled(7, false);

  DateTime? _boostEndTime; 
  GameEvent? activeEvent; 
  DateTime? _eventEndTime;
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
    if (isBoostActive) { m *= 2.0; }
    if (isEventActive) { m *= activeEvent!.multiplier; }
    // Müdürlerin (staff_2) Üretim Bonusu Bağlantısı
    m *= (1.0 + officeStaff.firstWhere((s) => s.id == 'staff_2').currentEffectValue);
    m *= researchMultiplier; 
    return m;
  }
  
  bool get isBoostActive => _boostEndTime != null && DateTime.now().isBefore(_boostEndTime!);
  bool get isEventActive => activeEvent != null && _eventEndTime != null && DateTime.now().isBefore(_eventEndTime!);
  double get incomePerSecond => _factories.fold(0.0, (sum, f) => sum + f.basePassiveIncome) * currentMultiplier;
  double get baseIncomePerSecond => _factories.fold(0.0, (sum, f) => sum + f.basePassiveIncome); 

  DateTime? _lastTaxIssued; 
  DateTime? _taxDeadline; 
  double _currentTaxDebt = 0.0; 
  bool _isUnderPenalty = false;
  double get currentTaxDebt => _currentTaxDebt; 
  bool get hasTaxDebt => _currentTaxDebt > 0; 
  bool get isUnderPenalty => _isUnderPenalty;

  DateTime? _lastSaveTime; 
  Timer? _gameTimer; 
  final math.Random _random = math.Random(); 
  List<Stock> _stocks = [];

  double get money => _money; 
  int get researchPoints => _researchPoints; 
  bool get isFirstLaunch => _isFirstLaunch; 
  String get language => _language; 
  List<Stock> get stocks => _stocks; 
  List<FactoryData> get factories => _factories; 
  List<ResearchNode> get researchNodes => _researchNodes;

  GameEvent? consumeUnhandledEvent() { var ev = _unhandledEvent; _unhandledEvent = null; return ev; }
  double consumeUnhandledBagReward() { var b = _unhandledBagReward; _unhandledBagReward = 0.0; return b; }

  // --- OYUN VERİLERİNİ YÜKLEME VE KAYDETME ---

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedGameJson = prefs.getString('game_save_data');

    if (savedGameJson != null) {
      Map<String, dynamic> data = jsonDecode(savedGameJson);
      _money = (data['money'] as num?)?.toDouble() ?? 0.0;
      _researchPoints = (data['researchPoints'] as num?)?.toInt() ?? 0;
      _isFirstLaunch = data['isFirstLaunch'] ?? true;
      _language = data['language'] ?? 'tr';
      _currentTaxDebt = (data['currentTaxDebt'] as num?)?.toDouble() ?? 0.0;
      
      statClicks = data['statClicks'] ?? 0; 
      statStocks = data['statStocks'] ?? 0; 
      statUpgrades = data['statUpgrades'] ?? 0; 
      statTaxes = data['statTaxes'] ?? 0; 
      statPrestige = data['statPrestige'] ?? 0; 
      statAdsWatched = data['statAdsWatched'] ?? 0; 
      statWheelSpins = data['statWheelSpins'] ?? 0;
      
      if (data['claimedTasks'] != null) claimedTasks = List<bool>.from(data['claimedTasks']);
      if (data['claimedAchievements'] != null) claimedAchievements = List<bool>.from(data['claimedAchievements']);
      
      if (data['officeStaffLevels'] != null) {
        List<dynamic> staffList = data['officeStaffLevels'];
        for (var saved in staffList) {
          try { 
            var staff = officeStaff.firstWhere((s) => s.id == saved['id']); 
            staff.level = saved['level'] ?? 0; 
          } catch (_) {}
        }
      } else if (data['hiredStaff'] != null) {
        List<String> hiredIds = List<String>.from(data['hiredStaff']);
        for (var staff in officeStaff) { 
          if (hiredIds.contains(staff.id)) staff.level = 1; 
        }
      }

      if (data['lastTaxIssued'] != null) _lastTaxIssued = DateTime.parse(data['lastTaxIssued']); 
      if (data['taxDeadline'] != null) _taxDeadline = DateTime.parse(data['taxDeadline']); 
      if (data['lastSaveTime'] != null) _lastSaveTime = DateTime.parse(data['lastSaveTime']); 
      if (data['boostEndTime'] != null) _boostEndTime = DateTime.parse(data['boostEndTime']); 
      if (data['eventEndTime'] != null && data['activeEvent'] != null) { 
        _eventEndTime = DateTime.parse(data['eventEndTime']); 
        var ev = data['activeEvent']; 
        activeEvent = GameEvent(ev['title'], ev['desc'], ev['mult'], ev['dur'], ev['cost']); 
      }
      _isUnderPenalty = data['isUnderPenalty'] ?? false;

      _loadStocksFromJson(data['stocks']);
      _loadFactoriesFromJson(data['factories']);
      _loadResearchFromJson(data['researchNodes']); 
      
      if (_lastSaveTime != null) {
        int secondsPassed = DateTime.now().difference(_lastSaveTime!).inSeconds;
        if (secondsPassed > 60 && baseIncomePerSecond > 0) {
          offlineEarningsToClaim = secondsPassed * baseIncomePerSecond;
        }
      }
    } else {
      _loadStocksFromJson(null); 
      _loadFactoriesFromJson(null); 
      _loadResearchFromJson(null);
      _lastTaxIssued = DateTime.now(); 
      _taxDeadline = DateTime.now().add(const Duration(hours: 12)); 
    }

    await TranslationService.instance.loadLanguage(_language);
    notifyListeners(); 
    _startGlobalTimers();
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSaveTime = DateTime.now();

    Map<String, dynamic> gameData = {
      'money': _money, 'researchPoints': _researchPoints, 'isFirstLaunch': _isFirstLaunch, 'language': _language,
      'statClicks': statClicks, 'statStocks': statStocks, 'statUpgrades': statUpgrades, 'statTaxes': statTaxes, 'statPrestige': statPrestige, 'statAdsWatched': statAdsWatched, 'statWheelSpins': statWheelSpins,
      'claimedTasks': claimedTasks, 'claimedAchievements': claimedAchievements, 
      'officeStaffLevels': officeStaff.map((s) => {'id': s.id, 'level': s.level}).toList(), 
      'currentTaxDebt': _currentTaxDebt, 
      'lastTaxIssued': _lastTaxIssued?.toIso8601String(), 
      'taxDeadline': _taxDeadline?.toIso8601String(), 
      'lastSaveTime': _lastSaveTime?.toIso8601String(), 
      'boostEndTime': _boostEndTime?.toIso8601String(), 
      'eventEndTime': _eventEndTime?.toIso8601String(),
      'activeEvent': activeEvent != null ? {'title': activeEvent!.title, 'desc': activeEvent!.description, 'mult': activeEvent!.multiplier, 'dur': activeEvent!.durationMinutes, 'cost': activeEvent!.preventCost} : null,
      'isUnderPenalty': _isUnderPenalty,
      'stocks': _stocks.map((s) => {'id': s.id, 'currentPrice': s.currentPrice, 'history': s.history, 'ownedShares': s.ownedShares, 'totalSpent': s.totalSpent}).toList(),
      'factories': _factories.map((f) => {'id': f.id, 'isUnlocked': f.isUnlocked, 'products': f.products.map((p) => p.toJson()).toList()}).toList(),
      'researchNodes': _researchNodes.map((r) => {'id': r.id, 'level': r.currentLevel}).toList(),
    };
    await prefs.setString('game_save_data', jsonEncode(gameData));
  }

  // --- İNŞAAT, AR-GE VE BORSA VERİ OLUŞTURUCULARI ---

  void _initDefaultFactories() {
    _factories = [
      _buildFac('1', 'Mobilya Fabrikası', 0, true, ['Ahşap Sandalye', 'Masa', 'Koltuk', 'Gardırop', 'Lüks Yatak'], 10.0),
      _buildFac('2', 'Süt Ürünleri', 1e4, false, ['Süt', 'Yoğurt', 'Peynir', 'Tereyağı', 'Gurme Kaşar'], 250.0),
      _buildFac('3', 'Tarım Tesisleri', 2.5e6, false, ['Buğday', 'Mısır', 'Pamuk', 'Soya', 'Tohum'], 15000.0),
      _buildFac('4', 'Tekstil Atölyesi', 5e8, false, ['İplik', 'Kumaş', 'Tişört', 'Ceket', 'Özel Tasarım'], 1e6),
      _buildFac('5', 'Çelik Kapı Fab.', 1e11, false, ['Sac', 'Kilit', 'Panel', 'Çelik Kapı', 'Zırhlı Kasa'], 5e7),
      _buildFac('6', 'Gıda İşleme', 2.5e13, false, ['Un', 'Şeker', 'Konserve', 'Dondurulmuş', 'Çikolata'], 5e9),
      _buildFac('7', 'Kimya Tesisleri', 5e15, false, ['Gübre', 'Plastik', 'Boya', 'Deterjan', 'Kozmetik'], 250e9),
      _buildFac('8', 'Otomobil Fab.', 1e18, false, ['Lastik', 'Motor', 'Şasi', 'Sedan Araç', 'Spor Araba'], 20e12),
      _buildFac('9', 'Maden Çıkarma', 2.5e20, false, ['Kömür', 'Demir', 'Bakır', 'Altın', 'Elmas'], 1.5e15),
      _buildFac('10', 'Elektronik Tesis', 5e22, false, ['Devre', 'Çip', 'Telefon', 'Bilgisayar', 'İşlemci'], 100e15),
      _buildFac('11', 'Yapay Zeka Ar-Ge', 1e25, false, ['Veri', 'Algoritma', 'Bot', 'Otonom', 'AGI'], 5e18),
      _buildFac('12', 'Biyoteknoloji', 2.5e27, false, ['Aşı', 'Protein', 'Hücre', 'DNA', 'Serum'], 250e18),
      _buildFac('13', 'Füzyon Enerji', 5e29, false, ['Plazma', 'Mıknatıs', 'Reaktör', 'Saf Enerji', 'Çekirdek'], 15e21),
      _buildFac('14', 'Uzay Sanayii', 1e32, false, ['Uydu', 'Roket', 'İstasyon', 'Gezgin', 'Işık Motoru'], 1e24),
    ];
  }

  FactoryData _buildFac(String id, String n, double pr, bool unl, List<String> pNames, double bInc) {
    List<FactoryProduct> prods = [];
    for(int i = 0; i < pNames.length; i++) {
       double inc = bInc * math.pow(6, i); 
       prods.add(FactoryProduct(name: pNames[i], baseIncome: inc, baseCost: inc * 10, level: (unl && i == 0) ? 1 : 0));
    }
    return FactoryData(id: id, name: n, price: pr, isUnlocked: unl, products: prods);
  }

  void _loadFactoriesFromJson(dynamic savedList) {
    _initDefaultFactories(); 
    if (savedList != null) {
      for (var saved in savedList) {
        try { 
          var fac = _factories.firstWhere((f) => f.id == saved['id']); 
          fac.isUnlocked = saved['isUnlocked']; 
          for (int i = 0; i < fac.products.length; i++) { 
            if (i < saved['products'].length) { 
              fac.products[i].level = saved['products'][i]['level']; 
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
      _n('node_006', 'Pres Çelik Kapı', 'Fabrika', 'Çelik kapı fabrikası üretim hattının kârını artırır.', Icons.door_front_door_rounded, 4, 5, ['node_003'], (lvl) => 'Çelik Kapı Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_007', 'Mekanik Dokuma', 'Fabrika', 'Tekstil fabrikası üretim hattının kârını artırır.', Icons.checkroom_rounded, 4, 5, ['node_004'], (lvl) => 'Tekstil Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_008', 'Karoser Robot Hattı', 'Fabrika', 'Otomobil fabrikası üretim hattının kârını artırır.', Icons.directions_car_rounded, 4, 5, ['node_004'], (lvl) => 'Otomobil Fabrikası Geliri: +%${lvl * 5}'),
      _n('node_009', 'Derin Kuyu Sondajı', 'Fabrika', 'Maden fabrikası üretim hattının kârını artırır.', Icons.landslide_rounded, 5, 5, ['node_005'], (lvl) => 'Maden Fabrikası Geliri: +%${lvl * 6}'),
      _n('node_010', 'Yarı İletken Baskı', 'Fabrika', 'Elektronik fabrikası üretim hattının kârını artırır.', Icons.memory_rounded, 5, 5, ['node_006'], (lvl) => 'Elektronik Fabrikası Geliri: +%${lvl * 6}'),
      _n('node_011', 'Nöral Ağ Optimizasyonu', 'Fabrika', 'Yapay zeka geliştirme fabrikasının kârını artırır.', Icons.psychology_rounded, 6, 5, ['node_007'], (lvl) => 'Yapay Zeka Fabrikası Geliri: +%${lvl * 7}'),
      _n('node_012', 'Genetik Rekombinasyon', 'Fabrika', 'Biyoteknoloji fabrikası üretim hattının kârını artırır.', Icons.biotech_rounded, 6, 5, ['node_008'], (lvl) => 'Biyoteknoloji Fabrikası Geliri: +%${lvl * 7}'),
      _n('node_013', 'Tokamak Manyetik Alanı', 'Fabrika', 'Füzyon enerji fabrikası üretim hattının kârını artırır.', Icons.bolt_rounded, 7, 5, ['node_009', 'node_010'], (lvl) => 'Füzyon Enerji Fabrikası Geliri: +%${lvl * 8}'),
      _n('node_014', 'Yörünge İtki Sistemleri', 'Fabrika', 'Uzay sanayii fabrikası üretim hattının kârını artırır.', Icons.rocket_launch_rounded, 8, 5, ['node_011', 'node_012'], (lvl) => 'Uzay Sanayii Fabrikası Geliri: +%${lvl * 10}'),
      _n('node_015', 'Sanayi Kartel Sinerjisi', 'Sanayi', 'Tüm 12 fabrikanın taban gelirine toplu çarpan sağlar.', Icons.hub_rounded, 10, 3, ['node_013', 'node_014'], (lvl) => 'Tüm 12 Fabrikanın Geliri: +%${lvl * 10}'),
      _n('node_016', 'İndirimli Tedarik', 'Maliyet', 'Fabrika geliştirme maliyet çarpanını tabandan aşağı çeker.', Icons.trending_down_rounded, 4, 3, ['node_002'], (lvl) => 'Maliyet Çarpanı: ${(1.15 - lvl * 0.005).toStringAsFixed(3)}x'),
      _n('node_017', 'Toplu Malzeme Siparişi', 'Maliyet', 'Toplu alım anlaşmaları ile tesis geliştirme maliyetini kırar.', Icons.shopping_cart_rounded, 6, 3, ['node_016'], (lvl) => 'Ekstra Geliştirme İndirimi: -%${lvl * 4}'),
      _n('node_018', 'Küresel Tedarik Zinciri', 'Maliyet', 'Uluslararası navlun anlaşmaları ile kurulum masraflarını düşürür.', Icons.public_rounded, 8, 3, ['node_017'], (lvl) => 'Tesis Kurulum Maliyet İndirimi: -%${lvl * 6}'),
      _n('node_019', 'Üretim Standartlaşması', 'Kazanç', 'Üretme kazancı çarpanını taban değerin üzerine çıkarır.', Icons.trending_up_rounded, 5, 3, ['node_016'], (lvl) => 'Üretme Kazancı Çarpanı: ${(1.03 + lvl * 0.002).toStringAsFixed(3)}x'),
      _n('node_020', 'Yalın Kaizen Felsefesi', 'Kazanç', 'Sürekli iyileştirme prensibi ile ürün katsayılarını yükseltir.', Icons.speed_rounded, 7, 3, ['node_019'], (lvl) => 'Ürün Üretim Kazanç Bonusu: +%${lvl * 5}'),
      _n('node_021', 'Sürekli Akış Bandı', 'Pasif', 'Saniyelik pasif gelir oranını üretim kazancının yarısından yukarı taşır.', Icons.timer_rounded, 6, 3, ['node_019'], (lvl) => 'Saniyelik Gelir Oranı: %${50 + lvl * 3}'),
      _n('node_022', 'Vardiyasız Çalışma', 'Pasif', 'Tesislerin saniyelik pasif gelir akışını kademeli artırır.', Icons.all_inclusive_rounded, 8, 3, ['node_021'], (lvl) => 'Saniyelik Pasif Gelir İlavesi: +%${lvl * 3}'),
      _n('node_023', 'Tam Otonom Tesis', 'Pasif', 'İnsansız üretim ile saniyelik gelir çarpanını katlar.', Icons.smart_toy_rounded, 12, 3, ['node_022'], (lvl) => 'Otonom Pasif Gelir Çarpanı: +%${lvl * 10}'),
      _n('node_024', 'Hurda Değerleme', 'Yıkım', 'Fabrika yıkıldığında geri ödenen harcama oranını artırır.', Icons.recycling_rounded, 4, 2, ['node_023'], (lvl) => 'Fabrika Yıkım İadesi: %${50 + lvl * 5}'),
      _n('node_025', 'Sigortalı Söküm', 'Yıkım', 'Gelişmiş söküm teknikleriyle yıkım bedeli iadesini yükseltir.', Icons.shield_rounded, 6, 2, ['node_024'], (lvl) => 'Yıkım İadesi Kurtarma Oranı: %${60 + lvl * 5}'),
      _n('node_026', 'Kentsel Dönüşüm', 'Yıkım', 'Yıkılan tesis arazisinin geri kazanım değerini artırır.', Icons.location_city_rounded, 8, 2, ['node_025'], (lvl) => 'Kentsel Dönüşüm İade Oranı: %${70 + lvl * 5}'),
      _n('node_027', 'Sıfır Zarar Tasfiyesi', 'Yıkım', 'Yıkım iade oranını maksimum seviyeye çıkarır.', Icons.price_check_rounded, 12, 1, ['node_026'], (lvl) => 'Maksimum Yıkım İadesi: %80'),
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
      _n('node_041', 'Serbest Bölge (9-12)', 'Arsa', '9-12 numaralı ileri sanayi arsalarının satın alma bedelini düşürür.', Icons.domain_add_rounded, 12, 2, ['node_040'], (lvl) => '9-12 Nolu Arsa Maliyeti: -%${lvl * 25}'),
      _n('node_042', '12 Parsel Tam Kapasite', 'Arsa', 'Tüm parseller faaliyete geçtiğinde büyük holding kârı verir.', Icons.select_all_rounded, 18, 1, ['node_041'], (lvl) => '12 Arsa Dolduğunda Toplam Holding Geliri: +%30'),
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
      _n('node_081', 'Hızlı Kriz Çözümü', 'Kriz', 'Kabul edilen gelir yarılanması kriz süresini kısaltır.', Icons.timelapse_rounded, 10, 2, ['node_080'], (lvl) => 'Kabul Edilen Kriz Süresi: ${30 - lvl * 8} Dakika'),
      _n('node_082', 'Dış Ticaret Ataşeliği', 'İhracat', 'İhracat anlaşması fırsatındaki gelir bonusunu artırır.', Icons.flight_takeoff_rounded, 6, 3, ['node_081'], (lvl) => 'İhracat Fırsatı Gelir Bonusu: +%${10 + lvl * 5}'),
      _n('node_083', 'İhracat Koridoru', 'İhracat', 'İhracat anlaşması fırsatının aktif kalma süresini uzatır.', Icons.local_shipping_rounded, 8, 2, ['node_082'], (lvl) => 'İhracat Fırsatı Süresi: ${10 + lvl * 5} Dakika'),
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
          node.currentLevel = saved['level'] ?? 0;
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
    ];

    if (savedList != null) {
      for (var s in savedList) {
        try {
          var e = _stocks.firstWhere((st) => st.id == s['id']);
          e.currentPrice = (s['currentPrice'] as num).toDouble(); 
          e.history = List<double>.from((s['history'] as List).map((x) => (x as num).toDouble())); 
          e.ownedShares = (s['ownedShares'] as num).toDouble(); 
          e.totalSpent = (s['totalSpent'] as num).toDouble(); 
        } catch (_) {}
      }
    }
  }

  // --- OYUN DÖNGÜSÜ VE MEKANİKLER ---

  void _startGlobalTimers() { 
    _gameTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) { 
      _processSecond(); 
    }); 
  }

  void _processSecond() {
    if (incomePerSecond > 0) {
      _money += incomePerSecond;
    }
    
    // Borsa Güncellemesi (Her 5 Saniyede Bir)
    if (DateTime.now().second % 5 == 0) {
      double analystBonus = officeStaff.firstWhere((s) => s.id == 'staff_4').currentEffectValue;
      for (var stock in _stocks) {
        double vol = (_random.nextDouble() * 0.04) + 0.01;
        bool isProfit = _random.nextDouble() < (0.51 + analystBonus); 
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
    notifyListeners();
    if (DateTime.now().second % 10 == 0) {
      _saveGame(); 
    }
  }

  void _checkRandomEvents() {
    if (activeEvent != null && _eventEndTime != null && DateTime.now().isAfter(_eventEndTime!)) {
      activeEvent = null; 
      _eventEndTime = null; 
      _saveGame(); 
    }
    if (baseIncomePerSecond > 0 && activeEvent == null && _unhandledEvent == null && _random.nextDouble() < 0.005) {
      if (_random.nextBool()) {
        _unhandledEvent = GameEvent('Lojistik Krizi', 'Liman grevleri sebebiyle 3 dakikalığına gelirler %50 düşecek.', 0.5, 3, baseIncomePerSecond * 120);
      } else {
        _unhandledEvent = GameEvent('Küresel Talep Patlaması', 'Ürünlerimize yoğun ilgi var! 2 dakikalığına gelirler 2 Kat artacak!', 2.0, 2, 0);
      }
    }
    if (baseIncomePerSecond > 0 && _unhandledBagReward == 0 && _random.nextDouble() < 0.005) {
      _unhandledBagReward = baseIncomePerSecond * 300; 
    }
  }

  void resolveEvent(bool payToPrevent, GameEvent ev) {
    if (payToPrevent) { 
      if (_money >= ev.preventCost) {
        _money -= ev.preventCost; 
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
      _money += watchAd ? (offlineEarningsToClaim * 2) : offlineEarningsToClaim; 
      offlineEarningsToClaim = 0; 
      _saveGame(); 
      notifyListeners(); 
    }
  }

  void claimBagReward(bool watchAd, double reward) { 
    _money += watchAd ? (reward * 3) : reward; 
    _saveGame(); 
    notifyListeners(); 
  }

  void activate2xBoost() { 
    _boostEndTime = DateTime.now().add(const Duration(minutes: 3)); 
    _saveGame(); 
    notifyListeners(); 
  }

  void applyTaxAmnesty() { 
    _currentTaxDebt = 0; 
    _isUnderPenalty = false; 
    _lastTaxIssued = DateTime.now(); 
    _taxDeadline = DateTime.now().add(const Duration(hours: 12)); 
    _saveGame(); 
    notifyListeners(); 
  }

  void _checkTaxSystem() {
    final now = DateTime.now();
    if (_lastTaxIssued != null && now.difference(_lastTaxIssued!).inHours >= 5 && _currentTaxDebt == 0) {
      double taxRate = 0.10;
      taxRate -= officeStaff.firstWhere((s) => s.id == 'staff_1').currentEffectValue;
      if (taxRate < 0.02) taxRate = 0.02; 
      
      _currentTaxDebt = (baseIncomePerSecond * 3600 * 5) * taxRate; 
      _lastTaxIssued = now; 
      _taxDeadline = now.add(const Duration(hours: 12)); 
      _isUnderPenalty = false;
      _saveGame(); 
    }
    if (_currentTaxDebt > 0 && _taxDeadline != null && now.isAfter(_taxDeadline!)) {
      if (!_isUnderPenalty) {
         _isUnderPenalty = true;
         _saveGame(); 
      }
      if (now.second == 0) {
        _currentTaxDebt *= 1.002; 
      }
      if (now.difference(_taxDeadline!).inHours >= 1) {
        _executeForeclosure(); 
      }
    }
  }

  void _executeForeclosure() {
    var unlockedFacs = _factories.where((f) => f.isUnlocked && f.id != '1').toList();
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
    _saveGame(); 
  }

  void payTax() {
    if (_money >= _currentTaxDebt) { 
      _money -= _currentTaxDebt; 
      _currentTaxDebt = 0; 
      _isUnderPenalty = false; 
      statTaxes++; 
      _saveGame(); 
      notifyListeners(); 
    }
  }

  void completeManualProduction(String facId, int productIndex) {
    var prod = _factories.firstWhere((f) => f.id == facId).products[productIndex];
    if (prod.level > 0) { 
      _money += prod.manualIncome * currentMultiplier; 
      statClicks++; 
      _saveGame(); 
      notifyListeners(); 
    }
  }

  bool unlockFactory(String facId) {
    var fac = _factories.firstWhere((f) => f.id == facId);
    double finalPrice = fac.price;
    finalPrice *= (1.0 - officeStaff.firstWhere((s) => s.id == 'staff_3').currentEffectValue);

    if (!fac.isUnlocked && _money >= finalPrice) {
      _money -= finalPrice; 
      fac.isUnlocked = true; 
      fac.products[0].level = 1; 
      _saveGame(); 
      notifyListeners(); 
      return true;
    }
    return false;
  }

  void hireStaff(String staffId) {
    var staff = officeStaff.firstWhere((s) => s.id == staffId);
    double cost = staff.currentCost;
    if (!staff.isMaxed && _money >= cost) {
      _money -= cost;
      staff.level++;
      _saveGame(); 
      notifyListeners();
    }
  }

  void upgradeProduct(String facId, int productIndex) {
    var prod = _factories.firstWhere((f) => f.id == facId).products[productIndex];
    if (prod.level >= 60) return;
    
    double cost = prod.upgradeCost;
    if (_money >= cost) { 
      _money -= cost; 
      prod.level++; 
      statUpgrades++; 
      _saveGame(); 
      notifyListeners(); 
    }
  }

  void upgradeResearch(String researchId) {
    var node = _researchNodes.firstWhere((n) => n.id == researchId);
    if (_researchPoints >= node.cost && !node.isMaxed) {
      _researchPoints -= node.cost;
      node.currentLevel++;
      _saveGame();
      notifyListeners();
    }
  }

  void executePrestige(int earnedRP) {
    _researchPoints += earnedRP; 
    _money = 0; 
    statPrestige++;
    for (var f in _factories) { 
      f.isUnlocked = f.id == '1'; 
      for (var p in f.products) { 
        p.level = (f.id == '1' && p == f.products.first) ? 1 : 0; 
      } 
    }
    _saveGame(); 
    notifyListeners();
  }

  void incrementAdsWatched() { statAdsWatched++; _saveGame(); notifyListeners(); }
  void incrementWheelSpins() { statWheelSpins++; _saveGame(); notifyListeners(); }
  Future<void> updateMoney(double amount) async { _money += amount; if (_money < 0) { _money = 0; } await _saveGame(); notifyListeners(); }
  Future<void> updateResearchPoints(int amount) async { _researchPoints += amount; await _saveGame(); notifyListeners(); }
  Future<void> setLanguage(String langCode) async { _language = langCode; await TranslationService.instance.loadLanguage(_language); await _saveGame(); notifyListeners(); }
  Future<void> completeFirstLaunch() async { _isFirstLaunch = false; await _saveGame(); notifyListeners(); }
  
  // YENİ BORSA MANTIĞI: Miktara Göre Alım (Küsüratsız Yuvarlama)
  void buyStockWithAmount(String stockId, double inputAmount) {
    var s = _stocks.firstWhere((st) => st.id == stockId);
    
    if (inputAmount > _money) {
      inputAmount = _money;
    }
    
    if (inputAmount >= s.currentPrice) {
      double sharesToBuy = (inputAmount / s.currentPrice).floorToDouble();
      double totalCost = sharesToBuy * s.currentPrice;

      if (sharesToBuy > 0 && _money >= totalCost) {
        _money -= totalCost; 
        s.ownedShares += sharesToBuy; 
        s.totalSpent += totalCost; 
        statStocks++;
        _saveGame(); 
        notifyListeners();
      }
    }
  }
  
  void sellAllStock(String stockId) {
    var s = _stocks.firstWhere((st) => st.id == stockId);
    if (s.ownedShares > 0) { 
      _money += s.ownedShares * s.currentPrice * 0.995; 
      s.ownedShares = 0; 
      s.totalSpent = 0; 
      _saveGame(); 
      notifyListeners(); 
    }
  }
}