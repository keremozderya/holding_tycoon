// lib/screens/research_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/prestige_dialog.dart';

class ResearchNode {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final int baseCost;
  final int maxLevel;
  int currentLevel;
  final List<String> parentIds;
  final String Function(int level) effectBuilder;

  ResearchNode({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.baseCost,
    required this.maxLevel,
    this.currentLevel = 0,
    required this.parentIds,
    required this.effectBuilder,
  });

  bool get isUnlocked => currentLevel > 0;
  bool get isMaxed => currentLevel >= maxLevel;

  int get cost => isMaxed ? baseCost * maxLevel : baseCost * (currentLevel + 1);

  String get currentEffectText => currentLevel == 0 ? 'Henüz Aktif Değil' : effectBuilder(currentLevel);
  String get nextEffectText => isMaxed ? 'Maksimum Seviyeye Ulaşıldı' : effectBuilder(currentLevel + 1);
}

ResearchNode _n(
  String id,
  String title,
  String category,
  String description,
  IconData icon,
  int baseCost,
  int maxLevel,
  List<String> parentIds,
  String Function(int lvl) effectBuilder, {
  int currentLevel = 0,
}) {
  return ResearchNode(
    id: id,
    title: title,
    category: category,
    description: description,
    icon: icon,
    baseCost: baseCost,
    maxLevel: maxLevel,
    currentLevel: currentLevel,
    parentIds: parentIds,
    effectBuilder: effectBuilder,
  );
}

List<ResearchNode> build100Nodes() {
  return [
    _n('node_001', 'Holding Beratı', 'Temel', 'Tüm fabrikaların taban üretim gelirini kalıcı olarak artırır.', Icons.account_balance_rounded, 1, 1, [],
      (lvl) => 'Tüm Fabrika Taban Geliri: +%${lvl * 3}', currentLevel: 1),

    _n('node_002', 'Ağır Sanayi Doktrini', 'Sanayi', 'Fabrika geliştirme maliyetlerini kalıcı olarak düşürür.', Icons.factory_rounded, 2, 5, ['node_001'],
      (lvl) => 'Fabrika Geliştirme Maliyeti: -%${lvl * 3}'),
    _n('node_003', 'Mobilya Seri Üretimi', 'Fabrika', 'Mobilya fabrikası üretim hattının kârını artırır.', Icons.chair_rounded, 3, 5, ['node_002'],
      (lvl) => 'Mobilya Fabrikası Geliri: +%${lvl * 5}'),
    _n('node_004', 'Pastörizasyon Hatları', 'Fabrika', 'Süt ürünleri fabrikası üretim hattının kârını artırır.', Icons.local_drink_rounded, 3, 5, ['node_002'],
      (lvl) => 'Süt Ürünleri Fabrikası Geliri: +%${lvl * 5}'),
    _n('node_005', 'Otomatik Sulama', 'Fabrika', 'Tarım fabrikası üretim hattının kârını artırır.', Icons.agriculture_rounded, 4, 5, ['node_003'],
      (lvl) => 'Tarım Fabrikası Geliri: +%${lvl * 5}'),
    _n('node_006', 'Pres Çelik Kapı', 'Fabrika', 'Çelik kapı fabrikası üretim hattının kârını artırır.', Icons.door_front_door_rounded, 4, 5, ['node_003'],
      (lvl) => 'Çelik Kapı Fabrikası Geliri: +%${lvl * 5}'),
    _n('node_007', 'Mekanik Dokuma', 'Fabrika', 'Tekstil fabrikası üretim hattının kârını artırır.', Icons.checkroom_rounded, 4, 5, ['node_004'],
      (lvl) => 'Tekstil Fabrikası Geliri: +%${lvl * 5}'),
    _n('node_008', 'Karoser Robot Hattı', 'Fabrika', 'Otomobil fabrikası üretim hattının kârını artırır.', Icons.directions_car_rounded, 4, 5, ['node_004'],
      (lvl) => 'Otomobil Fabrikası Geliri: +%${lvl * 5}'),
    _n('node_009', 'Derin Kuyu Sondajı', 'Fabrika', 'Maden fabrikası üretim hattının kârını artırır.', Icons.landslide_rounded, 5, 5, ['node_005'],
      (lvl) => 'Maden Fabrikası Geliri: +%${lvl * 6}'),
    _n('node_010', 'Yarı İletken Baskı', 'Fabrika', 'Elektronik fabrikası üretim hattının kârını artırır.', Icons.memory_rounded, 5, 5, ['node_006'],
      (lvl) => 'Elektronik Fabrikası Geliri: +%${lvl * 6}'),
    _n('node_011', 'Nöral Ağ Optimizasyonu', 'Fabrika', 'Yapay zeka geliştirme fabrikasının kârını artırır.', Icons.psychology_rounded, 6, 5, ['node_007'],
      (lvl) => 'Yapay Zeka Fabrikası Geliri: +%${lvl * 7}'),
    _n('node_012', 'Genetik Rekombinasyon', 'Fabrika', 'Biyoteknoloji fabrikası üretim hattının kârını artırır.', Icons.biotech_rounded, 6, 5, ['node_008'],
      (lvl) => 'Biyoteknoloji Fabrikası Geliri: +%${lvl * 7}'),
    _n('node_013', 'Tokamak Manyetik Alanı', 'Fabrika', 'Füzyon enerji fabrikası üretim hattının kârını artırır.', Icons.bolt_rounded, 7, 5, ['node_009', 'node_010'],
      (lvl) => 'Füzyon Enerji Fabrikası Geliri: +%${lvl * 8}'),
    _n('node_014', 'Yörünge İtki Sistemleri', 'Fabrika', 'Uzay sanayii fabrikası üretim hattının kârını artırır.', Icons.rocket_launch_rounded, 8, 5, ['node_011', 'node_012'],
      (lvl) => 'Uzay Sanayii Fabrikası Geliri: +%${lvl * 10}'),
    _n('node_015', 'Sanayi Kartel Sinerjisi', 'Sanayi', 'Tüm 12 fabrikanın taban gelirine toplu çarpan sağlar.', Icons.hub_rounded, 10, 3, ['node_013', 'node_014'],
      (lvl) => 'Tüm 12 Fabrikanın Geliri: +%${lvl * 10}'),

    _n('node_016', 'İndirimli Tedarik', 'Maliyet', 'Fabrika geliştirme maliyet çarpanını tabandan aşağı çeker.', Icons.trending_down_rounded, 4, 3, ['node_002'],
      (lvl) => 'Maliyet Çarpanı: ${(1.15 - lvl * 0.005).toStringAsFixed(3)}x'),
    _n('node_017', 'Toplu Malzeme Siparişi', 'Maliyet', 'Toplu alım anlaşmaları ile tesis geliştirme maliyetini kırar.', Icons.shopping_cart_rounded, 6, 3, ['node_016'],
      (lvl) => 'Ekstra Geliştirme İndirimi: -%${lvl * 4}'),
    _n('node_018', 'Küresel Tedarik Zinciri', 'Maliyet', 'Uluslararası navlun anlaşmaları ile kurulum masraflarını düşürür.', Icons.public_rounded, 8, 3, ['node_017'],
      (lvl) => 'Tesis Kurulum Maliyet İndirimi: -%${lvl * 6}'),
    _n('node_019', 'Üretim Standartlaşması', 'Kazanç', 'Üretme kazancı çarpanını taban değerin üzerine çıkarır.', Icons.trending_up_rounded, 5, 3, ['node_016'],
      (lvl) => 'Üretme Kazancı Çarpanı: ${(1.03 + lvl * 0.002).toStringAsFixed(3)}x'),
    _n('node_020', 'Yalın Kaizen Felsefesi', 'Kazanç', 'Sürekli iyileştirme prensibi ile ürün katsayılarını yükseltir.', Icons.speed_rounded, 7, 3, ['node_019'],
      (lvl) => 'Ürün Üretim Kazanç Bonusu: +%${lvl * 5}'),
    _n('node_021', 'Sürekli Akış Bandı', 'Pasif', 'Saniyelik pasif gelir oranını üretim kazancının yarısından yukarı taşır.', Icons.timer_rounded, 6, 3, ['node_019'],
      (lvl) => 'Saniyelik Gelir Oranı: %${50 + lvl * 3}'),
    _n('node_022', 'Vardiyasız Çalışma', 'Pasif', 'Tesislerin saniyelik pasif gelir akışını kademeli artırır.', Icons.all_inclusive_rounded, 8, 3, ['node_021'],
      (lvl) => 'Saniyelik Pasif Gelir İlavesi: +%${lvl * 3}'),
    _n('node_023', 'Tam Otonom Tesis', 'Pasif', 'İnsansız üretim ile saniyelik gelir çarpanını katlar.', Icons.smart_toy_rounded, 12, 3, ['node_022'],
      (lvl) => 'Otonom Pasif Gelir Çarpanı: +%${lvl * 10}'),

    _n('node_024', 'Hurda Değerleme', 'Yıkım', 'Fabrika yıkıldığında geri ödenen harcama oranını artırır.', Icons.recycling_rounded, 4, 2, ['node_023'],
      (lvl) => 'Fabrika Yıkım İadesi: %${50 + lvl * 5}'),
    _n('node_025', 'Sigortalı Söküm', 'Yıkım', 'Gelişmiş söküm teknikleriyle yıkım bedeli iadesini yükseltir.', Icons.shield_rounded, 6, 2, ['node_024'],
      (lvl) => 'Yıkım İadesi Kurtarma Oranı: %${60 + lvl * 5}'),
    _n('node_026', 'Kentsel Dönüşüm', 'Yıkım', 'Yıkılan tesis arazisinin geri kazanım değerini artırır.', Icons.location_city_rounded, 8, 2, ['node_025'],
      (lvl) => 'Kentsel Dönüşüm İade Oranı: %${70 + lvl * 5}'),
    _n('node_027', 'Sıfır Zarar Tasfiyesi', 'Yıkım', 'Yıkım iade oranını maksimum seviyeye çıkarır.', Icons.price_check_rounded, 12, 1, ['node_026'],
      (lvl) => 'Maksimum Yıkım İadesi: %80'),

    _n('node_028', '2. Ürün Ar-Ge\'si', 'Ürün', 'Lvl 30\'da açılan 2. ürünlerin üretim kazancını artırır.', Icons.auto_awesome_motion_rounded, 6, 3, ['node_027'],
      (lvl) => '2. Ürün Üretim Kazancı: +%${lvl * 10}'),
    _n('node_029', '3. Ürün İmalatı', 'Ürün', 'Lvl 60\'ta açılan 3. ürünlerin üretim kazancını artırır.', Icons.layers_rounded, 8, 3, ['node_028'],
      (lvl) => '3. Ürün Üretim Kazancı: +%${lvl * 15}'),
    _n('node_030', '4. Ürün Montajı', 'Ürün', 'Lvl 90\'da açılan 4. ürünlerin üretim kazancını artırır.', Icons.view_in_ar_rounded, 10, 3, ['node_029'],
      (lvl) => '4. Ürün Üretim Kazancı: +%${lvl * 20}'),
    _n('node_031', '5. Amiral Gemisi', 'Ürün', 'Lvl 120\'de açılan 5. ürünlerin üretim kazancını artırır.', Icons.star_rounded, 14, 3, ['node_030'],
      (lvl) => '5. Ürün Üretim Kazancı: +%${lvl * 25}'),
    _n('node_032', 'Kalıp Standardizasyonu', 'Ürün', 'Yeni açılan ürünlerin ilk seviye geliştirme masrafını düşürür.', Icons.architecture_rounded, 10, 2, ['node_031'],
      (lvl) => 'Yeni Ürün Başlangıç Maliyeti: -%${lvl * 15}'),

    _n('node_033', 'İK İşe Alım Ağı', 'Yönetim', 'Fabrikalara yönetici atama ve sözleşme bedelini azaltır.', Icons.badge_rounded, 5, 3, ['node_032'],
      (lvl) => 'Yönetici Atama Maliyeti: -%${lvl * 10}'),
    _n('node_034', 'Headhunter Sözleşmesi', 'Yönetim', 'Üst düzey yönetici transfer masraflarını düşürür.', Icons.person_search_rounded, 8, 3, ['node_033'],
      (lvl) => 'Yönetici Lisans İndirimi: -%${lvl * 15}'),
    _n('node_035', 'Usta Başı Disiplini', 'Yönetim', '1. yöneticinin fabrikaya sağladığı üretim gelirini artırır.', Icons.engineering_rounded, 6, 3, ['node_034'],
      (lvl) => '1. Yönetici Gelir Gücü: +%${lvl * 12}'),
    _n('node_036', 'Tesis Müdürü', 'Yönetim', '2. yöneticinin fabrikadaki maliyet indirim etkisini artırır.', Icons.manage_accounts_rounded, 8, 3, ['node_035'],
      (lvl) => '2. Yönetici İndirim Gücü: +%${lvl * 15}'),
    _n('node_037', 'Genel Koordinatör', 'Yönetim', '3. yöneticinin üretim hızlandırma çarpanını artırır.', Icons.supervisor_account_rounded, 10, 3, ['node_036'],
      (lvl) => '3. Yönetici Hız Çarpanı: +%${lvl * 20}'),
    _n('node_038', 'Plaza Mimari Dönüşümü', 'Yönetim', 'Yazıhaneden plazaya geçişte yöneticileri güçlendirir.', Icons.apartment_rounded, 16, 1, ['node_037'],
      (lvl) => 'Plaza Yöneticilerine Kalıcı Güçlendirme: +%25'),

    _n('node_039', 'İmar Ruhsatı (1-4)', 'Arsa', '1-4 numaralı sanayi arsalarının satın alma bedelini düşürür.', Icons.map_rounded, 6, 2, ['node_038'],
      (lvl) => '1-4 Nolu Arsa Maliyeti: -%${lvl * 15}'),
    _n('node_040', 'Sanayi Teşviki (5-8)', 'Arsa', '5-8 numaralı sanayi arsalarının satın alma bedelini düşürür.', Icons.landscape_rounded, 8, 2, ['node_039'],
      (lvl) => '5-8 Nolu Arsa Maliyeti: -%${lvl * 20}'),
    _n('node_041', 'Serbest Bölge (9-12)', 'Arsa', '9-12 numaralı ileri sanayi arsalarının satın alma bedelini düşürür.', Icons.domain_add_rounded, 12, 2, ['node_040'],
      (lvl) => '9-12 Nolu Arsa Maliyeti: -%${lvl * 25}'),
    _n('node_042', '12 Parsel Tam Kapasite', 'Arsa', 'Tüm parseller faaliyete geçtiğinde büyük holding kârı verir.', Icons.select_all_rounded, 18, 1, ['node_041'],
      (lvl) => '12 Arsa Dolduğunda Toplam Holding Geliri: +%30'),
    _n('node_043', 'Seviye 50 Eşiği', 'Seviye', 'Lvl 50\'ye ulaşan her fabrika tüm holdinge ek getiri sağlar.', Icons.looks_one_rounded, 6, 2, ['node_042'],
      (lvl) => 'Lvl 50 Fabrika Başına Holding Geliri: +%${lvl * 2}'),
    _n('node_044', 'Seviye 100 Eşiği', 'Seviye', 'Lvl 100\'e ulaşan her fabrika tüm holdinge ek getiri sağlar.', Icons.looks_two_rounded, 8, 2, ['node_043'],
      (lvl) => 'Lvl 100 Fabrika Başına Holding Geliri: +%${lvl * 3}'),
    _n('node_045', 'Seviye 150 Eşiği', 'Seviye', 'Lvl 150\'ye ulaşan fabrikaların geliştirme maliyetini kırar.', Icons.looks_3_rounded, 10, 2, ['node_044'],
      (lvl) => 'Lvl 150 Fabrika Maliyet İndirimi: -%${lvl * 2}'),
    _n('node_046', 'Seviye 200 Eşiği', 'Seviye', 'Lvl 200\'e ulaşan her fabrika için büyük üretim primi verir.', Icons.looks_4_rounded, 12, 2, ['node_045'],
      (lvl) => 'Lvl 200 Fabrika Gelir Bonusu: +%${lvl * 5}'),
    _n('node_047', 'Seviye 250 Eşiği', 'Seviye', 'Lvl 250 fabrikalar prestij tasfiyesinde ilave RP üretir.', Icons.looks_5_rounded, 16, 2, ['node_046'],
      (lvl) => 'Lvl 250 Fabrika Prestij RP Katkısı: +%${lvl * 3}'),
    _n('node_048', 'Seviye 300 Maksimum', 'Seviye', 'Fabrika 300. seviyeye ulaştığında saf kâr çarpanı kilitlenir.', Icons.workspace_premium_rounded, 25, 1, ['node_047'],
      (lvl) => 'Lvl 300 Fabrikaya Özel Saf 2.0x Gelir Çarpanı'),
    _n('node_049', 'Çırak-Usta Tasarımı', 'Seviye', 'Her 50 seviye görsel değişiminde geçici üretim takviyesi verir.', Icons.palette_rounded, 12, 2, ['node_048'],
      (lvl) => 'Görsel Değişim Gelir Boost: ${(1.0 + lvl * 0.25).toStringAsFixed(2)}x'),
    _n('node_050', 'Sanayi Sütun Zirvesi', 'Apex Kol 1', 'Kol 1 Apex: Tüm fabrikaların taban üretim katsayısını kalıcı katlar.', Icons.military_tech_rounded, 40, 1, ['node_049'],
      (lvl) => 'Sanayi Sütun Zirvesi: Taban Gelir Kalıcı +%50'),

    _n('node_051', 'Finansal Mühendislik', 'Finans', '5 saatte bir tahakkuk eden temel vergi borcu oranını düşürür.', Icons.account_balance_wallet_rounded, 2, 5, ['node_001'],
      (lvl) => 'Vergi Borcu Oranı: %${(10.0 - lvl * 0.2).toStringAsFixed(1)}'),
    _n('node_052', 'Gider Muhasebesi', 'Vergi', 'Verginin tahakkuk etme periyodunu uzatarak nakit akışını rahatlatır.', Icons.receipt_long_rounded, 4, 3, ['node_051'],
      (lvl) => 'Vergi Tahakkuk Periyodu: ${(5.0 + lvl * 0.5).toStringAsFixed(1)} Saat'),
    _n('node_053', 'Kurumlar Vergisi Muafiyeti', 'Vergi', 'Hesaplanan toplam vergi borcundan doğrudan kesinti yapar.', Icons.security_rounded, 6, 3, ['node_052'],
      (lvl) => 'Vergi Borcu İndirim Kalkanı: -%${lvl * 3}'),
    _n('node_054', 'Holding Vergi Tavanı', 'Vergi', 'Vergi borcu oranını en dip seviyeye kilitler.', Icons.verified_user_rounded, 10, 1, ['node_053'],
      (lvl) => 'Vergi Oranı Taban Sınırı: %8.0 (Kilitli)'),
    _n('node_055', 'Sadık Mükellef Primi', 'Vergi', '12 saat içinde ödenen verginin sağladığı gelir bonusunu artırır.', Icons.alarm_on_rounded, 4, 3, ['node_054'],
      (lvl) => 'Erken Ödeme Gelir Bonusu: %${20 + lvl * 3}'),
    _n('node_056', 'Mali Teşvik Protokolü', 'Vergi', 'Erken vergi ödeme bonusunun aktif kalma süresini uzatır.', Icons.hourglass_top_rounded, 6, 3, ['node_055'],
      (lvl) => 'Erken Ödeme Bonus Süresi: ${30 + lvl * 10} Dakika'),
    _n('node_057', 'Altın Mükellef Rozeti', 'Vergi', 'Vergisini aksatmayan holdinge ilave gelir çarpanı sağlar.', Icons.stars_rounded, 10, 2, ['node_056'],
      (lvl) => 'Erken Ödeme İlave Çarpanı: +%${lvl * 10}'),
    _n('node_058', 'Uzlaşma Masası', 'Vergi', '12 saat ödenmeyen vergide saat başı işleyen faiz oranını kırar.', Icons.handshake_rounded, 6, 2, ['node_057'],
      (lvl) => 'Saat Başı Gecikme Faizi: %${(0.10 - lvl * 0.02).toStringAsFixed(2)}'),
    _n('node_059', 'Haciz Erteleme Kararı', 'Vergi', 'En değerli fabrikanın haciz ile satılma süresini uzatır.', Icons.gavel_rounded, 8, 2, ['node_058'],
      (lvl) => 'Fabrika Haciz Erteleme Süresi: ${72 + lvl * 24} Saat'),
    _n('node_060', 'Vergi Barışı Lobiciliği', 'Vergi', 'Çark çevrildiğinde vergi affı çıkma olasılığını yükseltir.', Icons.campaign_rounded, 12, 2, ['node_059'],
      (lvl) => 'Çarktan Vergi Affı Çıkma Şansı: +%${lvl * 25}'),

    _n('node_061', 'Broker Lisansı', 'Borsa', 'Borsada hisse satarken kesilen işlem komisyonunu düşürür.', Icons.candlestick_chart_rounded, 4, 3, ['node_060'],
      (lvl) => 'Borsa Satış Komisyonu: %${(0.50 - lvl * 0.08).toStringAsFixed(2)}'),
    _n('node_062', 'Doğrudan Piyasa Erişimi', 'Borsa', 'Aracı komisyonlarını daha da aşağı çeker.', Icons.query_stats_rounded, 6, 3, ['node_061'],
      (lvl) => 'Satış Komisyonu İlave İndirimi: -%${(lvl * 0.05).toStringAsFixed(2)}'),
    _n('node_063', 'Kurumsal İletim Masası', 'Borsa', 'Hisse senedi alımlarında doğrudan komisyon iadesi üretir.', Icons.broadcast_on_personal_rounded, 8, 3, ['node_062'],
      (lvl) => 'Hisse Alım Nakit İadesi: %${(lvl * 0.2).toStringAsFixed(1)}'),
    _n('node_064', 'Sıfır Komisyon Ayrıcalığı', 'Borsa', 'Borsa komisyon oranını taban seviyeye sabitler.', Icons.money_off_rounded, 12, 1, ['node_063'],
      (lvl) => 'Minimum Komisyon: %0.10 (Kilitli)'),
    _n('node_065', 'Piyasa Derinliği', 'Borsa', '7 şirketin 5 saniyede bir işleyen %51 kâr eğilimini artırır.', Icons.trending_up_rounded, 6, 3, ['node_064'],
      (lvl) => '7 Şirketin Kâr Eğilimi: %${(51.0 + lvl * 0.4).toStringAsFixed(1)}'),
    _n('node_066', 'Algoritmik Fiyatlama', 'Borsa', 'Hisselerin kâr artış hızını ve getiri tavanını büyütür.', Icons.terminal_rounded, 8, 3, ['node_065'],
      (lvl) => 'Hisse Değer Artış İvmesi: +%${lvl * 5}'),
    _n('node_067', 'Piyasa Yapıcı Tekeli', 'Borsa', 'Borsa şirketlerinin kâr olasılığını zirveye taşır.', Icons.balance_rounded, 14, 2, ['node_066'],
      (lvl) => 'Hisse Kâr Eğilimi Tavanı: %${(52.2 + lvl * 0.4).toStringAsFixed(1)}'),
    _n('node_068', 'Portföy Temettü Havuzu', 'Borsa', 'Elde tutulan hisselerden saat başı pasif nakit üretir.', Icons.savings_rounded, 8, 3, ['node_067'],
      (lvl) => 'Saatlik Pasif Temettü Getirisi: %${(lvl * 0.2).toStringAsFixed(1)}'),
    _n('node_069', 'İmtiyazlı Borsa Payı', 'Borsa', 'Saatlik hisse temettü oranını kademeli yükseltir.', Icons.card_membership_rounded, 12, 2, ['node_068'],
      (lvl) => 'Saatlik Hisse Temettü Oranı: +%${(lvl * 0.3).toStringAsFixed(1)}'),
    _n('node_070', 'SVG Terminal Analitiği', 'Borsa', 'SVG grafiğinde dipten alımlarda sermaye primi sağlar.', Icons.show_chart_rounded, 16, 1, ['node_069'],
      (lvl) => 'Dipten Alımlarda Anında %5 Sermaye Primi'),

    _n('node_071', 'Yatırımcı Çantası', 'Fırsat', 'Ekranda beliren para çantasındaki nakit miktarını artırır.', Icons.business_center_rounded, 4, 3, ['node_070'],
      (lvl) => 'Para Çantası Nakit Artışı: +%${lvl * 25}'),
    _n('node_072', 'Girişim Sermayesi', 'Fırsat', 'Para çantasındaki ödül miktarını ek çarpanla büyütür.', Icons.work_rounded, 6, 3, ['node_071'],
      (lvl) => 'Para Çantası Nakit Çarpanı: +%${lvl * 30}'),
    _n('node_073', 'Melek Yatırımcı Ziyareti', 'Fırsat', 'Para çantasının ekranda daha sık çıkmasını sağlar.', Icons.timer_3_rounded, 8, 3, ['node_072'],
      (lvl) => 'Para Çantası Çıkış Sıklığı: +%${lvl * 20}'),
    _n('node_074', 'Altın Şans Çarkı', 'Çark', 'Çarktaki nakit ödüllerin taban büyüklüğünü artırır.', Icons.casino_rounded, 6, 3, ['node_073'],
      (lvl) => 'Çark Nakit Ödül Taban Değeri: +%${lvl * 25}'),
    _n('node_075', 'Büyük İkramiye Odası', 'Çark', 'Çarkta 3x çanta ve 2x boost gelme olasılığını yükseltir.', Icons.auto_awesome_rounded, 10, 2, ['node_074'],
      (lvl) => '3x Çanta & 2x Boost Şans Artışı: +%${lvl * 20}'),
    _n('node_076', 'Enerji Takviyesi', 'Boost', '3 dakikalık 2x gelir boost süresini uzatır.', Icons.battery_charging_full_rounded, 6, 2, ['node_075'],
      (lvl) => '2x Gelir Boost Süresi: ${3 + lvl} Dakika'),
    _n('node_077', 'Vardiya Seferberliği', 'Boost', '2x gelir boost süresine ilave dakikalar ekler.', Icons.more_time_rounded, 8, 2, ['node_076'],
      (lvl) => 'Boost Süresi İlavesi: +$lvl Dakika'),
    _n('node_078', 'Aşırı Yükleme', 'Boost', '2x boost çarpanının katsayısını kalıcı olarak artırır.', Icons.electric_bolt_rounded, 14, 1, ['node_077'],
      (lvl) => 'Gelir Boost Çarpanı Kalıcı 2.5x Olarak Uygulanır'),

    _n('node_079', 'Acil Durum Fonu', 'Kriz', 'Lojistik krizini parayla önleme bedelini (xx\$) düşürür.', Icons.emergency_rounded, 5, 3, ['node_078'],
      (lvl) => 'Kriz Önleme Bedeli İndirimi: -%${lvl * 20}'),
    _n('node_080', 'Kriz Sigortası', 'Kriz', 'Lojistik krizini savuşturma masraflarını kırar.', Icons.health_and_safety_rounded, 8, 2, ['node_079'],
      (lvl) => 'Kriz Önleme Ek İndirimi: -%${lvl * 25}'),
    _n('node_081', 'Hızlı Kriz Çözümü', 'Kriz', 'Kabul edilen gelir yarılanması kriz süresini kısaltır.', Icons.timelapse_rounded, 10, 2, ['node_080'],
      (lvl) => 'Kabul Edilen Kriz Süresi: ${30 - lvl * 8} Dakika'),
    _n('node_082', 'Dış Ticaret Ataşeliği', 'İhracat', 'İhracat anlaşması fırsatındaki gelir bonusunu artırır.', Icons.flight_takeoff_rounded, 6, 3, ['node_081'],
      (lvl) => 'İhracat Fırsatı Gelir Bonusu: +%${10 + lvl * 5}'),
    _n('node_083', 'İhracat Koridoru', 'İhracat', 'İhracat anlaşması fırsatının aktif kalma süresini uzatır.', Icons.local_shipping_rounded, 8, 2, ['node_082'],
      (lvl) => 'İhracat Fırsatı Süresi: ${10 + lvl * 5} Dakika'),
    _n('node_084', 'Global Pazar Radarı', 'Fırsat', 'Ekrana gelen fırsat ve krizlerin sıklığını artırır.', Icons.radar_rounded, 12, 2, ['node_083'],
      (lvl) => 'Fırsat & Kriz Belirme Sıklığı: +%${lvl * 25}'),
    _n('node_085', 'Otonom Gece Vardiyası', 'AFK', 'Oyunda değilken kazanılan saniyelik geliri artırır.', Icons.bedtime_rounded, 6, 3, ['node_084'],
      (lvl) => 'Çevrimdışı Saniyelik Gelir Bonusu: +%${lvl * 20}'),
    _n('node_086', 'Kasa Birikim Deposu', 'AFK', 'Çevrimdışı gelir toplama süresi sınırını uzatır.', Icons.lock_clock_rounded, 8, 2, ['node_085'],
      (lvl) => 'Maksimum Çevrimdışı Süre: ${6 + lvl * 3} Saat'),
    _n('node_087', 'Sürekli Holding Faaliyeti', 'AFK', 'Çevrimdışı süre sınırına ilave saatler ekler.', Icons.update_rounded, 12, 2, ['node_086'],
      (lvl) => 'Çevrimdışı Süre İlavesi: +${lvl * 4} Saat'),
    _n('node_088', 'Sponsorlu Üçlü Kazanç', 'AFK', 'Dönüşte reklamla alınan 2x çevrimdışı bonusunu 3x yapar.', Icons.video_call_rounded, 16, 1, ['node_087'],
      (lvl) => 'Reklamla Alınan 2x AFK Bonusu 3x Olarak Verilir'),

    _n('node_089', 'Prestij Ar-Ge İvmesi', 'Prestij', '100 Qi prestijinde ciroya oranla kazanılan RP miktarını artırır.', Icons.science_rounded, 10, 3, ['node_088'],
      (lvl) => 'Kazanılan Ar-Ge Puanı (RP): +%${lvl * 15}'),
    _n('node_090', 'Patent Konsorsiyumu', 'Prestij', 'Prestij tasfiyesinde kazanılan RP\'ye ek çarpan sağlar.', Icons.biotech_rounded, 14, 3, ['node_089'],
      (lvl) => 'Kazanılan RP İlavesi: +%${lvl * 25}'),
    _n('node_091', 'Düşünce Kuruluşu', 'Prestij', 'Prestij tasfiyesinden gelen RP çarpanını ikiye katlar.', Icons.psychology_alt_rounded, 20, 2, ['node_090'],
      (lvl) => 'Kazanılan RP Çarpanı: +%${lvl * 50}'),
    _n('node_092', 'Melek Sermaye Mirası', 'Prestij', 'Prestij yapıp sıfırlandıktan sonra hazır nakit hibesi verir.', Icons.monetization_on_rounded, 10, 2, ['node_091'],
      (lvl) => 'Başlangıç Nakit Hibesi: \$${lvl * 1000000}'),
    _n('node_093', 'Hazır Arsa Hibesi', 'Prestij', 'Prestij sonrası sanayi arsalarının bedelsiz açık başlamasını sağlar.', Icons.add_business_rounded, 14, 2, ['node_092'],
      (lvl) => 'Prestij Sonrası İlk ${lvl * 2} Arsa Bedelsiz Açık'),
    _n('node_094', 'Endüstriyel Miras', 'Prestij', 'Prestij sonrası ilk fabrikayı seviyesi ve 2. ürünü açık başlatır.', Icons.corporate_fare_rounded, 18, 1, ['node_093'],
      (lvl) => 'İlk Fabrika Doğrudan Seviye 30 Başlar'),
    _n('node_095', 'Girişimci Unvanı', 'Unvan', 'Kazanılan her ciro rütbesi için kalıcı ciro primi sağlar.', Icons.military_tech_outlined, 12, 2, ['node_094'],
      (lvl) => 'Her Ciro Rütbesi İçin Gelir Bonusu: +%${lvl * 5}'),
    _n('node_096', 'Galaktik Tycoon', 'Unvan', 'Lvl 6 Galaktik Tycoon ve üzeri rütbelere dev gelir çarpanı verir.', Icons.military_tech_sharp, 18, 2, ['node_095'],
      (lvl) => 'Lvl 6+ Rütbelere Özel Gelir Çarpanı: +%${lvl * 10}'),
    _n('node_097', '10^33 İvmelendiricisi', 'Unvan', '10^33 unvanına yaklaşırken gelir çarpanlarını katlar.', Icons.all_inclusive_rounded, 25, 1, ['node_096'],
      (lvl) => '10^33 Hedefine Yaklaşırken Ciro Katsayıları 1.5x Katlanır'),
    _n('node_098', 'Otomatik Tasfiye Protokolü', 'Prestij', 'Prestij yaparken vergi borcu engelini tek tuşla otomatik çözer.', Icons.assignment_turned_in_rounded, 20, 1, ['node_097'],
      (lvl) => 'Vergi Borcu Varsa Otomatik Affettirilir'),
    _n('node_099', 'Sermaye Sütun Zirvesi', 'Apex Kol 2', 'Kol 2 Apex: Borsa, kâr ve nakit akışını kalıcı olarak ikiye katlar.', Icons.account_balance_rounded, 40, 1, ['node_098'],
      (lvl) => 'Borsa ve Nakit Akışı Kalıcı 2.0x'),

    _n('node_100', 'Dünyaların Sahibi', 'Apex', '10^33 Ciroya Giden Zirve: Tüm sistemleri maksimum verimle taçlandırır.', Icons.diamond_rounded, 100, 1, ['node_050', 'node_099'],
      (lvl) => '10^33 Zirvesi: Maliyetler -%50, Saniyelik Gelir 5x ve Prestij RP Kazanımı 3x!'),
  ];
}

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  int _researchPoints = 75;
  double _currentTurnover = 2.45e20;

  final ScrollController _scrollController = ScrollController();
  late List<ResearchNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = build100Nodes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _canUnlock(ResearchNode node) {
    if (node.parentIds.isEmpty) return true;
    return node.parentIds.every((parentId) {
      final parent = _nodes.firstWhere(
        (n) => n.id == parentId,
        orElse: () => node,
      );
      return parent.isUnlocked;
    });
  }

  void _upgradeNode(ResearchNode node) {
    if (_researchPoints >= node.cost && !node.isMaxed && _canUnlock(node)) {
      setState(() {
        _researchPoints -= node.cost;
        node.currentLevel++;
      });
      Navigator.pop(context);
      _showNodeDetailsModal(node);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootNode = _nodes[0];
    final leftNodes = _nodes.sublist(1, 50);
    final rightNodes = _nodes.sublist(50, 99);
    final apexNode = _nodes[99];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AR-GE TEKNOLOJİ AĞACI', style: AppTheme.titleStyle(fontSize: 17)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.gold),
            tooltip: 'Holding Tasfiyesi (Prestij)',
            onPressed: () {
              PrestigeDialog.show(
                context,
                currentTurnover: _currentTurnover,
                onPrestigeConfirmed: () {
                  setState(() {
                    final ratio = _currentTurnover / 1.0e20;
                    final int rp = (10 * math.sqrt(ratio)).floor();
                    _researchPoints += rp;
                    _currentTurnover = 0;
                  });
                },
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_researchPoints RP',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            children: [
              Center(
                child: _buildTreeCard(
                  rootNode,
                  isCenter: true,
                  customWidth: 280,
                ),
              ),
              _buildForkConnector(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          '🏭 SANAYİ & OPERASYON',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          '📈 FİNANS & BORSA',
                          style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < 49; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTreeCard(leftNodes[i]),
                    ),
                    _buildCenterSpine(
                      isLeftUnlocked: leftNodes[i].isUnlocked,
                      isRightUnlocked: rightNodes[i].isUnlocked,
                    ),
                    Expanded(
                      child: _buildTreeCard(rightNodes[i]),
                    ),
                  ],
                ),
                if (i < 48) _buildVerticalSpineConnector(),
              ],
              _buildJoinConnector(
                isLeftMaxed: leftNodes.last.isUnlocked,
                isRightMaxed: rightNodes.last.isUnlocked,
              ),
              Center(
                child: _buildTreeCard(
                  apexNode,
                  isCenter: true,
                  isApex: true,
                  customWidth: 300,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'scroll_top',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.gold,
                  elevation: 4,
                  tooltip: 'Başa Dön',
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'scroll_bottom',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.gold,
                  elevation: 4,
                  tooltip: 'Zirveye İn (Dünyaların Sahibi)',
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: const Icon(Icons.arrow_downward_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeCard(
    ResearchNode node, {
    bool isCenter = false,
    bool isApex = false,
    double? customWidth,
  }) {
    final bool accessible = _canUnlock(node);
    final bool unlocked = node.isUnlocked;
    final bool maxed = node.isMaxed;

    Color borderColor;
    Color bgColor;

    if (maxed) {
      borderColor = AppColors.profit;
      bgColor = const Color(0xFFF0FDF4);
    } else if (unlocked) {
      borderColor = isApex ? const Color(0xFFB38B38) : AppColors.gold;
      bgColor = AppColors.surface;
    } else if (accessible) {
      borderColor = AppColors.gold.withValues(alpha: 0.5);
      bgColor = AppColors.surface;
    } else {
      borderColor = AppColors.border.withValues(alpha: 0.5);
      bgColor = AppColors.surfaceElevated.withValues(alpha: 0.5);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showNodeDetailsModal(node),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: customWidth,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: unlocked ? (isApex ? 2.5 : 1.8) : 1.0,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: (maxed ? AppColors.profit : AppColors.gold).withValues(alpha: isApex ? 0.25 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: unlocked ? AppColors.background : Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: unlocked ? AppColors.gold.withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    node.icon,
                    size: 20,
                    color: accessible
                        ? (unlocked ? AppColors.gold : AppColors.textSecondary)
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.category.toUpperCase(),
                        style: TextStyle(
                          color: accessible ? AppColors.gold : AppColors.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        maxed ? 'MAKS' : '${node.currentLevel}/${node.maxLevel}',
                        style: TextStyle(
                          color: maxed ? AppColors.profit : (unlocked ? AppColors.textPrimary : AppColors.textMuted),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!accessible)
                  const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              node.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accessible ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Text(
                node.isUnlocked ? node.currentEffectText : 'Sonraki: ${node.nextEffectText}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: maxed ? AppColors.profit : (node.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                maxed ? 'TAMAMLANDI' : '${node.cost} RP',
                style: TextStyle(
                  color: maxed ? AppColors.profit : (accessible ? AppColors.gold : AppColors.textMuted),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterSpine({required bool isLeftUnlocked, required bool isRightUnlocked}) {
    return Container(
      width: 20,
      height: 95,
      alignment: Alignment.center,
      child: Container(
        width: 2,
        height: double.infinity,
        color: (isLeftUnlocked || isRightUnlocked) ? AppColors.gold.withValues(alpha: 0.4) : AppColors.border,
      ),
    );
  }

  Widget _buildVerticalSpineConnector() {
    return Center(
      child: Container(
        width: 2,
        height: 14,
        color: AppColors.border,
      ),
    );
  }

  Widget _buildForkConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(
        size: const Size(double.infinity, 30),
        painter: ForkLinesPainter(),
      ),
    );
  }

  Widget _buildJoinConnector({required bool isLeftMaxed, required bool isRightMaxed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CustomPaint(
        size: const Size(double.infinity, 30),
        painter: JoinLinesPainter(
          isActive: isLeftMaxed && isRightMaxed,
        ),
      ),
    );
  }

  void _showNodeDetailsModal(ResearchNode node) {
    final bool accessible = _canUnlock(node);
    final bool canAfford = _researchPoints >= node.cost && !node.isMaxed && accessible;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Icon(node.icon, color: AppColors.gold, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(node.title, style: AppTheme.titleStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          node.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    node.isMaxed ? 'MAKS' : '${node.currentLevel}/${node.maxLevel}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                node.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mevcut Seviye (${node.currentLevel}. Seviye)',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        if (node.isUnlocked)
                          const Icon(Icons.check_circle_rounded, color: AppColors.profit, size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.currentEffectText,
                      style: TextStyle(
                        color: node.isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    Text(
                      'Sonraki Seviye (${node.isMaxed ? node.maxLevel : node.currentLevel + 1}. Seviye)',
                      style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.nextEffectText,
                      style: TextStyle(
                        color: node.isMaxed ? AppColors.textMuted : AppColors.profit,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!accessible)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.loss.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_rounded, color: AppColors.loss, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bu araştırmayı açmak için üst basamaktaki öncül yükseltmeyi tamamlayın.',
                          style: TextStyle(color: AppColors.loss, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: node.isMaxed
                        ? AppColors.profit
                        : (canAfford ? AppColors.gold : AppColors.surfaceElevated),
                    foregroundColor: canAfford ? Colors.white : AppColors.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: canAfford ? 3 : 0,
                  ),
                  onPressed: canAfford ? () => _upgradeNode(node) : null,
                  child: Text(
                    node.isMaxed
                        ? 'MAKSİMUM SEVİYEYE ULAŞILDI'
                        : (!accessible ? 'ÖNCEKİ YÜKSELTMEYİ TAMAMLAYIN' : 'GELİŞTİR (${node.cost} RP)'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ForkLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midX = size.width / 2;
    final leftX = size.width * 0.25;
    final rightX = size.width * 0.75;

    path.moveTo(midX, 0);
    path.lineTo(midX, 10);

    path.moveTo(midX, 10);
    path.lineTo(leftX, 20);
    path.lineTo(leftX, size.height);

    path.moveTo(midX, 10);
    path.lineTo(rightX, 20);
    path.lineTo(rightX, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JoinLinesPainter extends CustomPainter {
  final bool isActive;
  JoinLinesPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? AppColors.gold : AppColors.border
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midX = size.width / 2;
    final leftX = size.width * 0.25;
    final rightX = size.width * 0.75;

    path.moveTo(leftX, 0);
    path.lineTo(leftX, 10);
    path.lineTo(midX, 20);

    path.moveTo(rightX, 0);
    path.lineTo(rightX, 10);
    path.lineTo(midX, 20);

    path.lineTo(midX, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant JoinLinesPainter oldDelegate) => oldDelegate.isActive != isActive;
}