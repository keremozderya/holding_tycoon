// lib/core/balance.dart
//
// YENİ DOSYA — oyunun tüm denge sabitleri tek merkezde.
//
// Bu dosya, koda dağılmış "sihirli sayıları" toplar. Simülatörle kalibre
// edildi; hedef: günde 30 dk oynayan oyuncu ~88. günde oyunu bitirir.
//
// Kalibrasyon sonucu (bkz. docs/01_analiz_ve_denge_raporu.md):
//   15 dk/gün -> 111 gün | 30 dk/gün -> 88 gün | 60 dk/gün -> 64 gün
//
// Bu dosyadaki bir sabiti değiştirirsen, raporun 4. bölümündeki tempo
// tablosu geçersiz olur — simülatörü yeniden çalıştırmadan dokunma.

import 'dart:math' as math;

class Balance {
  Balance._();

  // ===========================================================================
  // ÜRÜN EĞRİSİ
  // ===========================================================================

  /// Ürün gelirinin seviye başına büyümesi.
  /// DEĞİŞMEDİ (1.12) — tap başına his iyi çalışıyordu.
  static const double incomeGrowth = 1.12;

  /// Ürün geliştirme maliyetinin seviye başına büyümesi.
  /// DEĞİŞTİ: tek sabit 1.32 yerine üç bantlı yapı.
  /// Eski modelde maliyet/gelir makası her seviyede 1.1786 katlanıyordu ve
  /// bir ürünü max'lamanın geri ödemesi sabit 1115 saatti (= hiç değmez).
  /// Yeni bantlar + kilometre taşı çarpanı bu makası 1.115'e indiriyor.
  static const double costGrowthTier1 = 1.339; // seviye 0-29
  static const double costGrowthTier2 = 1.299; // seviye 30-44
  static const double costGrowthTier3 = 1.259; // seviye 45-59

  /// Belirtilen seviyeden bir sonrakine geçerken uygulanacak maliyet çarpanı.
  static double costGrowthAt(int level) {
    if (level < 30) return costGrowthTier1;
    if (level < 45) return costGrowthTier2;
    return costGrowthTier3;
  }

  /// baseCost = baseIncome * costRatio. DEĞİŞMEDİ.
  static const double costRatio = 12.0;

  /// passiveIncome = manualIncome * passiveRatio. DEĞİŞMEDİ.
  static const double passiveRatio = 0.20;

  /// Fabrika içinde ürün i'nin taban geliri = bInc * productStep^i. DEĞİŞMEDİ.
  static const double productStep = 2.5;

  /// Ürün başına maksimum seviye. DEĞİŞMEDİ (fabrika toplamı 5*60 = 300).
  static const int maxProductLevel = 60;

  /// Ürünlerin açılması için gereken fabrika toplam seviyesi. DEĞİŞMEDİ.
  static const List<int> productUnlockLevels = <int>[0, 30, 60, 90, 120];

  // ===========================================================================
  // KİLOMETRE TAŞI ÇARPANI  (YENİ)
  // ===========================================================================
  //
  // Her `milestoneStep` seviyede ürün geliri `milestoneMultiplier` ile çarpılır.
  // Bu, "duvar -> sıçrama -> duvar" döngüsünü kıran ana mekanizma:
  // etkin gelir büyümesi 1.12 -> 1.12 * 2^(1/10) = 1.2004 oluyor.
  //
  // UI notu: oyuncu bunu görmeli. Ürün kartında "sonraki ×2'ye N seviye"
  // göstergesi ekle — yoksa mekanizma çalışır ama hissedilmez.

  static const int milestoneStep = 10;
  static const double milestoneMultiplier = 2.0;

  /// `level` seviyesindeki bir ürünün kilometre taşı çarpanı.
  static double milestoneBonus(int level) =>
      math.pow(milestoneMultiplier, level ~/ milestoneStep).toDouble();

  /// Bir sonraki kilometre taşına kaç seviye kaldığı (UI göstergesi için).
  static int levelsToNextMilestone(int level) =>
      milestoneStep - (level % milestoneStep);

  // ===========================================================================
  // ÜRÜN HESAPLARI
  // ===========================================================================

  /// Ürünün manuel (tap) geliri.
  /// FactoryProduct.manualIncome buna yönlendirilmeli.
  static double manualIncome({required double baseIncome, required int level}) {
    if (level == 0) return 0.0;
    return baseIncome * math.pow(incomeGrowth, level - 1) * milestoneBonus(level);
  }

  /// Ürünün `level` -> `level+1` geliştirme maliyeti.
  /// FactoryProduct.upgradeCost buna yönlendirilmeli.
  ///
  /// Bantlı büyüme kümülatif olduğu için düz `pow` kullanılamaz; bantların
  /// kapalı formu aşağıda (döngüsüz, O(1)).
  static double upgradeCost({required double baseCost, required int level}) {
    final int t1 = level.clamp(0, 30);
    final int t2 = (level - 30).clamp(0, 15);
    final int t3 = (level - 45).clamp(0, 15);
    return baseCost *
        math.pow(costGrowthTier1, t1) *
        math.pow(costGrowthTier2, t2) *
        math.pow(costGrowthTier3, t3);
  }

  // ===========================================================================
  // FABRİKA ZİNCİRİ
  // ===========================================================================
  //
  // ESKİ SORUN: gelir sıçramaları düzensizdi (60x, 13.3x, 17.5x, 21.4x, 25x,
  // 30x, 26.7x, 31.7x, 31.6x, 33.3x, 37.5x, 50x) ve 15. fabrikanın fiyatı
  // 5e29 idi — prestij eşiğinin (1e20) bir milyar katı, yani erişilemez.
  //
  // YENİ: her kademe sabit x30 gelir, fiyat = taban maliyetin 12.000 katı.

  /// Giriş seviyesi fabrikaların (1, 2, 3) taban ürün geliri.
  static const double starterBaseIncome = 2.0;

  /// Kademe başına gelir çarpanı.
  static const double factoryIncomeStep = 30.0;

  /// Fabrika fiyatı = tabanÜrünMaliyeti * factoryPriceFactor.
  static const double factoryPriceFactor = 12000.0;

  /// Fabrika id'sinden (1..15) kademe numarası.
  /// 1, 2 ve 3 aynı kademededir (üçü de giriş seviyesi, biri bedava seçilir).
  static int factoryTier(int factoryNumber) =>
      factoryNumber <= 3 ? 0 : factoryNumber - 3;

  /// Fabrikanın 1. ürününün taban geliri.
  static double factoryBaseIncome(int factoryNumber) =>
      starterBaseIncome *
      math.pow(factoryIncomeStep, factoryTier(factoryNumber));

  /// Fabrikanın arsa/kurulum fiyatı. Giriş seviyesi üçlüsü için 300.000 sabit
  /// (seçilmeyen ikisi para ile alınabilsin diye), gerisi formülle.
  static double factoryPrice(int factoryNumber) {
    if (factoryNumber <= 3) return 300000.0;
    return factoryBaseIncome(factoryNumber) * costRatio * factoryPriceFactor;
  }

  // ===========================================================================
  // ÇEVRİMDIŞI GELİR
  // ===========================================================================
  //
  // DEĞİŞTİ: verim %20 -> %25, tavan 6 saat -> 8 saat.
  // Gerekçe: 30 dk/gün oynayan oyuncunun günün kalan 23.5 saatinden anlamlı
  // pay alması gerekiyor; modelde çevrimdışı katkı toplam kazancın ~%40'ı.

  static const double offlineEfficiency = 0.25;
  static const int offlineCapHours = 8;

  // ===========================================================================
  // PRESTİJ
  // ===========================================================================
  //
  // Yeni ciro eğrisinde 50. gün civarı 2.77e20, 60. gün 1.93e23.
  // Eşik 1e20'de kalırsa ilk prestij ~48. güne denk gelir — oyunun tam ortası,
  // istenen yer. DEĞİŞMEDİ.

  static const double prestigeThreshold = 1.0e20;

  /// Ciroya karşılık kazanılacak ham RP (çarpanlar hariç).
  /// DEĞİŞMEDİ — ama 3. aşamada 100 düğümün toplam ~1100 RP maliyetine göre
  /// yeniden doğrulanmalı.
  static int baseEarnableRp(double turnover) {
    if (turnover < prestigeThreshold) return 0;
    return (10.0 * math.sqrt(turnover / prestigeThreshold)).floor();
  }

  // ===========================================================================
  // İLERLEME HEDEFLERİ  (referans — görev/başarım hizalaması için)
  // ===========================================================================
  //
  // Simülatörden çıkan gün -> ciro eşleşmesi. Görev ve başarım kademelerini
  // 3. aşamada bu tabloya oturtacağız; şu an sadece referans.

  static const Map<int, double> turnoverByDay = <int, double>{
    1: 7.89e4,
    10: 2.37e9,
    20: 8.08e11,
    30: 5.45e14,
    40: 3.73e17,
    50: 2.77e20,
    60: 1.93e23,
    70: 1.37e26,
    80: 5.80e27,
    88: 3.82e28,
  };

  /// Verilen ciroda oyuncunun kabaca kaçıncı günde olduğu.
  /// Başarım/görev eşiklerini "N. güne denk gelsin" diye seçerken kullanılır.
  static int approximateDay(double turnover) {
    var lastDay = 1;
    for (final entry in turnoverByDay.entries) {
      if (turnover >= entry.value) lastDay = entry.key;
    }
    return lastDay;
  }
}
