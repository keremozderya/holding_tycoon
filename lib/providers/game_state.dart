// lib/providers/game_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState extends ChangeNotifier {
  // --- OYUN VERİLERİ (STATE) ---
  double _money = 0.0;
  int _researchPoints = 0;
  bool _isFirstLaunch = true;

  // --- GETTER METOTLARI (Verileri dışarıdan okumak için) ---
  double get money => _money;
  int get researchPoints => _researchPoints;
  bool get isFirstLaunch => _isFirstLaunch;

  // --- 1. VERİLERİ YÜKLEME (Oyun açıldığında çalışır) ---
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Veritabanından verileri çekiyoruz. Eğer veri yoksa varsayılan değerleri atıyoruz.
    _money = prefs.getDouble('money') ?? 1000.0; // Oyuna 1000$ ile başlasın
    _researchPoints = prefs.getInt('researchPoints') ?? 0;
    _isFirstLaunch = prefs.getBool('is_initial_launch') ?? true;
    
    // Veriler yüklendikten sonra UI'ı (arayüzü) güncellemek için dinleyicilere haber veriyoruz.
    notifyListeners(); 
  }

  // --- 2. İLK GİRİŞİ TAMAMLAMA ---
  Future<void> completeFirstLaunch() async {
    _isFirstLaunch = false;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_initial_launch', false);
  }

  // --- 3. PARA EKLEME / ÇIKARMA ---
  // Eksi değer göndererek (örn: updateMoney(-500)) para harcatabilirsiniz.
  Future<void> updateMoney(double amount) async {
    _money += amount;
    
    // Paranın sıfırın altına düşmesini engellemek isterseniz:
    if (_money < 0) _money = 0; 

    notifyListeners(); // Arayüzdeki para miktarını anında günceller
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('money', _money); // Arka planda telefona kaydeder
  }

  // --- 4. AR-GE PUANI (RP) EKLEME / HARCAMA ---
  Future<void> updateResearchPoints(int amount) async {
    _researchPoints += amount;
    
    if (_researchPoints < 0) _researchPoints = 0;

    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('researchPoints', _researchPoints);
  }
}