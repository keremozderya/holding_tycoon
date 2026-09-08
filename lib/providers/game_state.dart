// lib/providers/game_state.dart
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

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
  double _money = 0.0;
  int _researchPoints = 0;
  bool _isFirstLaunch = true;
  String _language = 'tr';

  Timer? _marketTimer;
  final Random _random = Random();
  static const int _historyLength = 40;
  
  List<Stock> _stocks = [];

  double get money => _money;
  int get researchPoints => _researchPoints;
  bool get isFirstLaunch => _isFirstLaunch;
  String get language => _language;
  List<Stock> get stocks => _stocks;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _money = prefs.getDouble('money') ?? 1000.0; 
    _researchPoints = prefs.getInt('researchPoints') ?? 0;
    _isFirstLaunch = prefs.getBool('is_initial_launch') ?? true;
    _language = prefs.getString('language') ?? 'tr';

    await TranslationService.instance.loadLanguage(_language);

    _loadStocks(prefs);
    notifyListeners(); 
    _startGlobalTimers();
  }

  Future<void> setLanguage(String langCode) async {
    _language = langCode.toLowerCase();
    await TranslationService.instance.loadLanguage(_language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    notifyListeners();
  }

  void _loadStocks(SharedPreferences prefs) {
    String? savedStocksJson = prefs.getString('saved_stocks');
    
    _stocks = [
      Stock(id: '1', name: 'Redof Tech', icon: Icons.smart_toy_rounded, iconColor: Colors.blueAccent, currentPrice: 71.0, history: List.generate(_historyLength, (_) => 71.0)),
      Stock(id: '2', name: 'Titan Ağır Sanayi', icon: Icons.factory_rounded, iconColor: Colors.pinkAccent, currentPrice: 24280.0, history: List.generate(_historyLength, (_) => 24280.0)),
      Stock(id: '3', name: 'Lunar Uzaycılık', icon: Icons.rocket_launch_rounded, iconColor: Colors.redAccent, currentPrice: 62240.0, history: List.generate(_historyLength, (_) => 62240.0)),
      Stock(id: '4', name: 'Apex Biyoteknoloji', icon: Icons.biotech_rounded, iconColor: Colors.greenAccent, currentPrice: 150.0, history: List.generate(_historyLength, (_) => 150.0)),
      Stock(id: '5', name: 'Nova Enerji', icon: Icons.bolt_rounded, iconColor: Colors.amberAccent, currentPrice: 85.0, history: List.generate(_historyLength, (_) => 85.0)),
    ];

    if (savedStocksJson != null) {
      List<dynamic> decoded = jsonDecode(savedStocksJson);
      for (var savedStock in decoded) {
        var existingStock = _stocks.firstWhere((s) => s.id == savedStock['id']);
        existingStock.currentPrice = savedStock['currentPrice'];
        existingStock.history = List<double>.from(savedStock['history']);
        existingStock.ownedShares = savedStock['ownedShares'];
        existingStock.totalSpent = savedStock['totalSpent'];
      }
    }
  }

  Future<void> _saveStocks() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(_stocks.map((s) => {
      'id': s.id,
      'currentPrice': s.currentPrice,
      'history': s.history,
      'ownedShares': s.ownedShares,
      'totalSpent': s.totalSpent,
    }).toList());
    await prefs.setString('saved_stocks', encoded);
  }

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
    _saveStocks();
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

      updateMoney(-totalCost);
      stock.ownedShares += sharesToBuy;
      stock.totalSpent += totalCost;
      _saveStocks();
      notifyListeners();
    }
  }

  void sellAllStock(String stockId) {
    var stock = _stocks.firstWhere((s) => s.id == stockId);
    if (stock.ownedShares > 0) {
      double gross = stock.ownedShares * stock.currentPrice;
      double commission = gross * 0.005; 
      double net = gross - commission;

      updateMoney(net);
      stock.ownedShares = 0;
      stock.totalSpent = 0;
      _saveStocks();
      notifyListeners();
    }
  }

  Future<void> completeFirstLaunch() async {
    _isFirstLaunch = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_initial_launch', false);
  }

  Future<void> updateMoney(double amount) async {
    _money += amount;
    if (_money < 0) _money = 0; 
    notifyListeners(); 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('money', _money); 
  }

  Future<void> updateResearchPoints(int amount) async {
    _researchPoints += amount;
    if (_researchPoints < 0) _researchPoints = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('researchPoints', _researchPoints);
  }
}