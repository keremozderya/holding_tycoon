# Aşama 2–5 — Değişiklik Özeti

Onay beklemeden devam ettim; verdiğim kararlar aşağıda işaretli. Hepsi kodda
da `// DEĞİŞTİ:` / `// YENİ:` yorumlarıyla gerekçeli.

## Verdiğim kararlar

| # | Soru | Karar | Gerekçe |
|---|---|---|---|
| 1 | "Bitirmek" ne demek? | 15 fabrika açık + hepsi 300. seviye | En uzun ve en ölçülebilir hedef; prestij ve unvan bunun içinde kalıyor |
| 2 | Ar-Ge birleştirme | **B** — 100 düğüm korundu | `node_100` apex'i, ekran yerleşimi ve kayıt formatı 100'e bağlı |
| 3 | Koyu mavi paleti | Rapordaki 4 ton uygulandı | Beyaz metinle 14.6:1 kontrast (WCAG AAA) |
| 4 | Eski kayıtlar | **Göç yazıldı**, sıfırlama yok | `balanceVersion` alanı + `_migrateEntryTierResearch()` |
| 5 | Bozuk 3 dosya | Geri türetilenler kullanıldı | Orijinal gelirse üzerine yazılabilir |

---

## Aşama 2 — Denge entegrasyonu + Ar-Ge birleştirme

### `lib/core/balance.dart` (yeni)
Tüm denge sabitleri tek merkezde. Kalibrasyon **koda yazılan formüllerle**
yeniden doğrulandı: **30 dk/gün → 88. gün**.

### `lib/providers/game_state.dart`
- `FactoryProduct.manualIncome / upgradeCost` → `Balance`'a devredildi
  (kilometre taşı ×2 / 10 seviye + bantlı maliyet)
- `_initDefaultFactories()` elle yazılmış 15 satırlık fiyat/gelir tablosu
  yerine `Balance.factoryPrice()` / `Balance.factoryBaseIncome()` ile üretiliyor
- Çevrimdışı: tavan 3 sa → 8 sa, verim %20 → %25
- **Ar-Ge birleştirme:**
  - `node_003` → "Giriş Seviyesi Sanayi Hattı", fabrika 1+2+3'ü birlikte etkiliyor
  - `node_005` → "Giriş Hattı Otomasyonu" (giriş tesislerinde maliyet indirimi)
  - `node_007` → "Giriş Hattı İhracatı" (giriş tesislerinde pasif gelir)
  - `_factoryResearchMultiplier`: `'1','2','3'` üçü de `node_003`'e bağlandı
  - `node_006 / 008 / 009 / 011` `parentIds`'leri yeniden bağlandı
- **Kayıt göçü:** `balanceVersion` alanı eklendi. Sürüm 1 kaydı açıldığında
  eski 003/005/007'nin **en yükseği** birleşik düğüme taşınıyor, diğer ikisine
  harcanmış RP oyuncuya **iade** ediliyor.

## Aşama 3 — Görev / başarım / RP hizalaması

**Görevler tek seferlikten günlüğe çevrildi.** Eskiden 4 görevin dördü de
(3 reklam / 1 çark / 20 tıklama / 3 borsa işlemi) ilk 10 dakikada bitiyor ve
bir daha görünmüyordu. Artık:
- `dailyAds / dailySpins / dailyClicks / dailyStocks` sayaçları
- gece yarısı otomatik sıfırlama (`_rolloverDailyTasks`), oyun açıkken de
  (`_processSecond` içinde 60 saniyede bir kontrol)
- hedefler `dailyTaskTargets = [3, 1, 60, 5]`
- RP ödülü 5+2 → 1+1 (günlük olduğu için; 90 günde 180 RP ≈ ağacın %4.6'sı)

**Başarım hedefleri yeni eğriye oturtuldu.** Eski tabloda:
- tıklama hedefi 5.000.000'du — 30 dk/gün × 90 gün ≈ **121.000** tıklama, yani
  son 4 kademe fiziksel olarak imkânsızdı
- ciro hedefi 5e33'tü — yeni eğride tavan 3.8e28
- toplam ürün seviyesi hedefi 7500'dü — teorik maksimum **4500**

**Başarım para ödülü** sabit `1500 × 2.2^tier` idi (son kademe 1.77e6);
88. günde saniyelik gelir 7.27e23 olduğu için ödül fiilen sıfırdı. Artık
oyuncunun kendi gelirine oranlı.

**Prestij RP formülü** `10 × √oran` → `12 × oran^0.30`. Eski üs çok dikti:
60. günde 439 RP, 70. günde 11.704 RP — 10 gün arayla 27 kat fark. Yeni formül
aynı aralığı 116 → 832'ye (7 kat) indiriyor. Doğrulama:

| Gün | Ciro | Prestij RP |
|---|---|---|
| 50 | 2.86e20 | 16 |
| 60 | 1.93e23 | 116 |
| 70 | 1.37e26 | 832 |
| 80 | 5.80e27 | 2.559 |
| 88 | 3.82e28 | 4.506 |

Ağacın tamamı 3.932 RP. ~4 prestij turuyla tam olarak karşılanıyor.

**Çark ödülleri** — istemediğin ama bulduğum bir denge kırığı: dilimler sabit
nakit veriyordu, en büyüğü **1e30**. Yeni ekonomide oyunun 88 günlük TOPLAM
cirosu 3.82e28 — yani tek çark çevirmesi oyunu anında bitiriyordu. Diğer uçta
10K, 30. günden sonra fark edilmiyordu. Dilimler artık "kaç saatlik pasif
gelir" cinsinden (1dk … 48sa), tabanları yeni oyuncu için korunuyor.

## Aşama 4 — Koyu tema okunabilirlik

459 siyah kullanımı bağlamına göre sınıflandırıldı:

| | Adet |
|---|---|
| **Dönüştü** (yüzey üstü metin/ikon) | 117 |
| Korundu: cartoon kontur / gölge | 202 |
| Korundu: `CustomPainter` çizimi | 68 |
| Korundu: altın/yeşil/kırmızı rozet üstü | 27 |
| Korundu: yarı saydam katman | 2 |

Ek olarak 27 sabit açık yüzey rengi (`0xFFF1F5F9`, `0xFFE2E8F0` vb.) ve
41 `Colors.white` yüzeyi temaya duyarlı hale getirildi.

**Neden statik `AppColors.isDark`?** Dönüşecek noktaların çoğu `const TextStyle`
içinde ve `BuildContext` kapsamda değil. Her birine `context.watch<GameState>()`
sokmak 12 ekranı yeniden yazmak demekti. Tema zaten uygulama genelinde tek bir
bayrak (MaterialApp'e tek `theme:` veriliyor, Flutter'ın `ThemeMode`'u
kullanılmıyor) — statik ayna mimariyle tutarlı. `GameState.setDarkTheme()` ve
`loadData()` bu aynayı besliyor.

`const` kırılması otomatik yapıldı: dinamik getter'ı kapsayan **77** `const`
ifadesi özyinelemeli olarak kaldırıldı, sonra sıfır ihlal kaldığı doğrulandı.

## Aşama 5 — Dil sistemi

`lib/services/translation_service.dart` yeniden yazıldı: iç içe anahtar,
`{param}` interpolasyonu, **yedek zinciri** (seçili dil → `en` → anahtarın
kendisi), `trList()` dizi desteği, dile göre sayı biçimlendirme ve debug
modunda **eksik anahtar raporu**.

6 dil dosyası dolduruldu:
- ~130 arayüz anahtarı × 6 dil
- 15 fabrika adı × 6 dil
- 75 ürün adı × 6 dil

`FactoryData.displayName` ve `FactoryProduct.displayName` eklendi; ekranlar
bunları kullanıyor.

**Dikkat edilen tuzak:** `ProductSvgIcon` ve `_ProductVectorPainter`, ürünü
**Türkçe adına göre** `switch` ile seçiyor. Bu yüzden çizim ve `ValueKey`
çağrıları kanonik `.name`'de bırakıldı; `.displayName` sadece `Text()` içinde
kullanılıyor. Otomatik dönüşüm önce burayı da değiştirmişti, geri alındı —
yoksa dil değiştirildiğinde tüm ürün ikonları kaybolurdu.

---

## Kalan iş

### 1. Ar-Ge düğüm metinleri (en büyük kalem)
100 düğüm × (başlık + açıklama + efekt) = **300 anahtar × 6 dil = 1.800 kayıt**.
Efekt metinleri `(lvl) => 'Tüm Fabrika Taban Geliri: +%${lvl * 3}'` biçiminde
closure — her biri `'research.node_001.effect'.tr(params: {'v': ...})` haline
gelmeli.

Altyapı hazır: yedek zinciri sayesinde bu anahtarlar JSON'a girene kadar oyun
Türkçe metinleri göstermeye devam eder, hiçbir yerde boş kutu çıkmaz.

### 2. Kalan ~70 arayüz metni
`map_screen` (53) ve `factory_screen` (45) içindeki metinlerin bir kısmı hâlâ
sabit. `TranslationService.missingKeys` debug modunda bunları listeliyor.

### 3. Font tanımı
`pubspec.yaml`'da `flutter: fonts:` bölümü yok — koddaki 49 `'SpaceMono'` ve
1 `'Rubik'` sessizce sistem fontuna düşüyor.

### 4. Derleme doğrulaması
**Bu ortamda Dart/Flutter SDK yoktu.** Sözdizimi kontrollerini elle yaptım
(`const` ihlali: 0, parantez dengesi orijinalle aynı, eksik import: 0) ama
`flutter analyze` çalıştırılmadı. İlk iş `flutter pub get && flutter analyze`.

### 5. UI'da görünmeyen mekanizma
Kilometre taşı çarpanı (her 10 seviyede ×2) tempoyu düzelten ana mekanizma ama
oyuncuya gösterilmiyor. `Balance.levelsToNextMilestone()` ve
`FactoryProduct.levelsToNextMilestone` hazır, ürün kartına bağlanmalı —
`factory.next_milestone` ve `factory.milestone_hit` anahtarları 6 dilde yazıldı.
