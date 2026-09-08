// lib/providers/game_state.dart
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double _money = 0.0;
  int _researchPoints = 0;
  bool _isFirstLaunch = true;

  // Borsa Verileri
  Timer? _marketTimer;
  final Random _random = Random();
  static const int _historyLength = 40;
  
  List<Stock> _stocks = [];

  // --- GETTER METOTLARI ---
  double get money => _money;
  int get researchPoints => _researchPoints;
  bool get isFirstLaunch => _isFirstLaunch;
  List<Stock> get stocks => _stocks;

  // --- 1. VERİLERİ YÜKLEME VE OYUNU BAŞLATMA ---
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _money = prefs.getDouble('money') ?? 1000.0; 
    _researchPoints = prefs.getInt('researchPoints') ?? 0;
    _isFirstLaunch = prefs.getBool('is_initial_launch') ?? true;
    
    // Borsayı Yükle
    _loadStocks(prefs);

    notifyListeners(); 

    // Veriler yüklendikten sonra global oyun döngülerini başlat
    _startGlobalTimers();
  }

  // --- 2. BORSA HAFIZA YÖNETİMİ (JSON) ---
  void _loadStocks(SharedPreferences prefs) {
    String? savedStocksJson = prefs.getString('saved_stocks');
    
    // Temel Şirket Şablonları (İkonlar ve Renkler JSON'a kaydedilemediği için burada eşleştiriyoruz)
    _stocks = [
      Stock(id: '1', name: 'Redof Tech', icon: Icons.smart_toy_rounded, iconColor: Colors.blueAccent, currentPrice: 71.0, history: List.generate(_historyLength, (_) => 71.0)),
      Stock(id: '2', name: 'Titan Ağır Sanayi', icon: Icons.factory_rounded, iconColor: Colors.pinkAccent, currentPrice: 24280.0, history: List.generate(_historyLength, (_) => 24280.0)),
      Stock(id: '3', name: 'Lunar Uzaycılık', icon: Icons.rocket_launch_rounded, iconColor: Colors.redAccent, currentPrice: 62240.0, history: List.generate(_historyLength, (_) => 62240.0)),
      Stock(id: '4', name: 'Apex Biyoteknoloji', icon: Icons.biotech_rounded, iconColor: Colors.greenAccent, currentPrice: 150.0, history: List.generate(_historyLength, (_) => 150.0)),
      Stock(id: '5', name: 'Nova Enerji', icon: Icons.bolt_rounded, iconColor: Colors.amberAccent, currentPrice: 85.0, history: List.generate(_historyLength, (_) => 85.0)),
    ];

    // Eğer daha önce kaydedilmiş bir borsa verisi varsa, fiyatları ve sahip olunan lotları üzerine yaz
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
    // Borsa listesini JSON formatına dönüştürüp kaydediyoruz
    String encoded = jsonEncode(_stocks.map((s) => {
      'id': s.id,
      'currentPrice': s.currentPrice,
      'history': s.history,
      'ownedShares': s.ownedShares,
      'totalSpent': s.totalSpent,
    }).toList());
    await prefs.setString('saved_stocks', encoded);
  }

  // --- 3. OYUN DÖNGÜLERİ (ARKAPLAN İŞLEMLERİ) ---
  void _startGlobalTimers() {
    // Haritada dolaşırken bile borsa 5 saniyede bir güncellenir
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
    _saveStocks(); // Fiyatlar her değiştiğinde telefona kaydet
    notifyListeners(); // Ekranı güncelle
  }

  // --- 4. HİSSE AL / SAT İŞLEMLERİ ---
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

  // --- TEMEL KAYIT İŞLEMLERİ ---
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