// lib/providers/game_state.dart
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

// --- HİSSE SENEDİ MODELİ ---
class Stock {
  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
  double currentPrice;
  List<double> history;
  double ownedShares;
  double totalSpent;

  Stock({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.currentPrice,
    required this.history,
    this.ownedShares = 0,
    this.totalSpent = 0,
  });

  double get netPnl => (currentPrice * ownedShares) - totalSpent;
}

class GameState extends ChangeNotifier {
  // --- OYUN VERİLERİ (STATE) ---
  double _money = 1000.0;
  int _researchPoints = 0;
  bool _isFirstLaunch = true;
  String _language = 'tr';

  // Borsa Verileri
  Timer? _marketTimer;
  final Random _random = Random();
  static const int _historyLength = 40;
  List<Stock> _stocks = [];

  // Getterlar
  double get money => _money;
  int get researchPoints => _researchPoints;
  bool get isFirstLaunch => _isFirstLaunch;
  String get language => _language;
  List<Stock> get stocks => _stocks;

  // --- 1. OYUNU YÜKLEME (LOAD) ---
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Temel Ayarları ve Verileri Okuma
    String? savedGameJson = prefs.getString('game_save_data');

    if (savedGameJson != null) {
      // Eğer daha önceden kaydedilmiş bir JSON varsa, paketi açıp verileri yerine koyuyoruz
      Map<String, dynamic> data = jsonDecode(savedGameJson);
      _money = data['money'] ?? 1000.0;
      _researchPoints = data['researchPoints'] ?? 0;
      _isFirstLaunch = data['isFirstLaunch'] ?? true;
      _language = data['language'] ?? 'tr';

      // Borsayı JSON'dan gelen verilerle yükle
      _loadStocksFromJson(data['stocks']);
    } else {
      // İlk kez açılıyorsa varsayılan borsa verilerini oluştur
      _initDefaultStocks();
    }

    await TranslationService.instance.loadLanguage(_language);
    notifyListeners();
    _startGlobalTimers();
  }

  // --- 2. OYUNU KAYDETME (SAVE - TEK JSON KUTUSU) ---
  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();

    // Tüm oyun verilerini tek bir harita (Map) yapısında topluyoruz
    Map<String, dynamic> gameData = {
      'money': _money,
      'researchPoints': _researchPoints,
      'isFirstLaunch': _isFirstLaunch,
      'language': _language,
      'stocks': _stocks.map((s) => {
        'id': s.id,
        'currentPrice': s.currentPrice,
        'history': s.history,
        'ownedShares': s.ownedShares,
        'totalSpent': s.totalSpent,
      }).toList(),
      // İleride fabrikalar buraya eklenebilir: 'factories': [...]
    };

    // Tek bir satır metin (JSON) haline getirip telefona kaydediyoruz
    String jsonString = jsonEncode(gameData);
    await prefs.setString('game_save_data', jsonString);
  }

  // --- Borsa Başlangıç ve JSON Eşleme Yardımcıları ---
  void _initDefaultStocks() {
    _stocks = [
      Stock(id: '1', name: 'Redof Tech', icon: Icons.smart_toy_rounded, iconColor: Colors.blueAccent, currentPrice: 71.0, history: List.generate(_historyLength, (_) => 71.0)),
      Stock(id: '2', name: 'Titan Ağır Sanayi', icon: Icons.factory_rounded, iconColor: Colors.pinkAccent, currentPrice: 24280.0, history: List.generate(_historyLength, (_) => 24280.0)),
      Stock(id: '3', name: 'Lunar Uzaycılık', icon: Icons.rocket_launch_rounded, iconColor: Colors.redAccent, currentPrice: 62240.0, history: List.generate(_historyLength, (_) => 62240.0)),
      Stock(id: '4', name: 'Apex Biyoteknoloji', icon: Icons.biotech_rounded, iconColor: Colors.greenAccent, currentPrice: 150.0, history: List.generate(_historyLength, (_) => 150.0)),
      Stock(id: '5', name: 'Nova Enerji', icon: Icons.bolt_rounded, iconColor: Colors.amberAccent, currentPrice: 85.0, history: List.generate(_historyLength, (_) => 85.0)),
    ];
  }

  void _loadStocksFromJson(dynamic savedStocksList) {
    _initDefaultStocks(); // Önce şablonu kur
    if (savedStocksList != null) {
      for (var savedStock in savedStocksList) {
        try {
          var existingStock = _stocks.firstWhere((s) => s.id == savedStock['id']);
          existingStock.currentPrice = savedStock['currentPrice'];
          existingStock.history = List<double>.from(savedStock['history']);
          existingStock.ownedShares = savedStock['ownedShares'];
          existingStock.totalSpent = savedStock['totalSpent'];
        } catch (_) {}
      }
    }
  }

  // --- OYUN DÖNGÜLERİ ---
  void _startGlobalTimers() {
    _marketTimer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateMarket();
    });
  }

  void _updateMarket() {
    for (var stock in _stocks) {
      bool isProfit = _random.nextDouble() < 0.51;
      double volatility = (_random.nextDouble() * 0.04) + 0.01;
      if (!isProfit) volatility = -volatility;

      stock.currentPrice = stock.currentPrice * (1 + volatility);
      if (stock.currentPrice < 1.0) stock.currentPrice = 1.0;

      stock.history.add(stock.currentPrice);
      if (stock.history.length > _historyLength) {
        stock.history.removeAt(0);
      }
    }
    _saveGame(); // Her borsa değişiminde otomatik kaydet
    notifyListeners();
  }

  // --- İŞLEM FONKSİYONLARI ---
  Future<void> setLanguage(String langCode) async {
    _language = langCode.toLowerCase();
    await TranslationService.instance.loadLanguage(_language);
    await _saveGame();
    notifyListeners();
  }

  Future<void> completeFirstLaunch() async {
    _isFirstLaunch = false;
    await _saveGame();
    notifyListeners();
  }

  Future<void> updateMoney(double amount) async {
    _money += amount;
    if (_money < 0) _money = 0; 
    await _saveGame();
    notifyListeners(); 
  }

  Future<void> updateResearchPoints(int amount) async {
    _researchPoints += amount;
    if (_researchPoints < 0) _researchPoints = 0;
    await _saveGame();
    notifyListeners();
  }

  void buyStock(String stockId) {
    var stock = _stocks.firstWhere((s) => s.id == stockId);
    double budget = _money * 0.1;
    if (budget < stock.currentPrice) budget = stock.currentPrice;

    if (_money >= stock.currentPrice) {
      double sharesToBuy = (budget / stock.currentPrice).floorToDouble();
      if (sharesToBuy < 1) sharesToBuy = 1;
      
      if (_money < sharesToBuy * stock.currentPrice) {
        sharesToBuy = (_money / stock.currentPrice).floorToDouble();
      }

      double totalCost = sharesToBuy * stock.currentPrice;

      _money -= totalCost;
      if (_money < 0) _money = 0;
      stock.ownedShares += sharesToBuy;
      stock.totalSpent += totalCost;

      _saveGame();
      notifyListeners();
    }
  }

  void sellAllStock(String stockId) {
    var stock = _stocks.firstWhere((s) => s.id == stockId);
    if (stock.ownedShares > 0) {
      double gross = stock.ownedShares * stock.currentPrice;
      double commission = gross * 0.005; 
      double net = gross - commission;

      _money += net;
      stock.ownedShares = 0;
      stock.totalSpent = 0;

      _saveGame();
      notifyListeners();
    }
  }
}