# Holding Tycoon — Mimari Analiz ve Denge Raporu

Proje hacmi: **12.648 satır Dart**, 20 dosya, 6 dil dosyası.
Derleme doğrulaması yapılamadı (ortamda Dart/Flutter SDK yok) — bu raporun tüm
sayısal sonuçları, oyunun ekonomi döngüsünü birebir yeniden uygulayan bir Python
simülatöründen çıkarıldı.

---

## 0. Arşivde 3 dosya bozuk

`holding_tycoon.rar` içindeki şu üç dosyanın veri bloğu okunamıyor (hem `unar`,
hem `7z`, hem `rarfile` aynı hatayı veriyor — arşiv oluşturulurken bozulmuş):

| Dosya | Boyut | Neden kritik |
|---|---|---|
| `lib/theme/app_theme.dart` | 4.744 B | **1. maddenin tam merkezi** — `AppColors`, `surfaceFor/softSurfaceFor/mutedSurfaceFor` burada |
| `lib/services/translation_service.dart` | 2.291 B | **4. maddenin tam merkezi** — `.tr()` motoru burada |
| `assets/translations/tr.json` | 1.370 B | Türkçe anahtarların tamamı |

Bu üçünü kullanım yerlerinden geri türettim (aşağıda teslim ediliyorlar), ama
**orijinallerinde benim göremediğim bir şey varsa kaybolur.** Elinde sağlam
kopya varsa yeniden yollaman en temizi.

Kullanım yerlerinden çıkardığım API yüzeyi (geri türetme buna dayanıyor):

```
AppColors: gold(54) profit(47) loss(30) textSecondary(28) neonCyan(26)
           textMuted(20) textPrimary(6) background(6) surface(5)
           surfaceElevated(1) darkSurface(1) darkBrown(1)
           surfaceFor(bool) softSurfaceFor(bool) mutedSurfaceFor(bool)
AppTheme:  tycoonTheme, titleStyle({double fontSize})
Translation: TranslationService.instance.loadLanguage(code) / .currentLanguage
             String.tr({Map<String,String>? params})   // "{param}" interpolasyonu
```

---

## 1. Koyu tema — okunabilirlik

Mevcut durum: koyu tema **yalnızca yüzey renklerine** bağlanmış. `GameState.useDarkTheme`
→ `AppColors.surfaceFor(dark)` zinciri çalışıyor, ama metin renkleri bu zincire
hiç bağlı değil.

`lib/` içinde sabit siyah kullanımının dökümü:

| Kullanım | Adet | Ne yapılmalı |
|---|---|---|
| `Border.all(color: Colors.black…)` | 128 | **Kalmalı** — cartoon dış çizgi kimliği |
| `Shadow/BoxShadow(color: Colors.black…)` | 45 | **Kalmalı** |
| `BorderSide(color: Colors.black…)` | 24 | **Kalmalı** |
| `TextStyle(color: Colors.black…)` | 57 | **Dönmeli** |
| `.copyWith(color: Colors.black…)` | 17 | **Dönmeli** |
| kalan (ikon `color:`, `CircularProgressIndicator` vs.) | ~27 | **Dönmeli** |

Yani ~**101 nokta** dönüşecek, 197 nokta olduğu gibi kalacak. Bunları körlemesine
`Colors.white` yapmak yanlış olur: altın/yeşil/kırmızı zemin üstündeki siyah yazı
her iki temada da doğru. Çözüm, "bu metin **yüzey** üstünde mi duruyor?" sorusunu
tek yerde cevaplayan bir token katmanı:

```dart
AppColors.onSurfaceFor(dark)   // yüzey üstü ana metin   : siyah  ↔ beyaz
AppColors.onSurfaceSoftFor(dark) // yüzey üstü ikincil    : siyah54 ↔ beyaz70
// altın/yeşil/kırmızı rozet üstündeki siyah -> Colors.black olarak KALIR
```

Ek bir engel: bu metinlerin çoğu `const TextStyle(...)` içinde. `const`'lar
kırılacak (`const` → normal), yoksa tema anında değişmez.

### Koyu mavi tonu

`AppColors.darkSurface` şu an koyu-gri/mavi bir ton. İstenen "daha koyu, yine
cartoon" mavi için önerim (aynı hue ailesinde, 3 kademe):

| Token | Yeni değer | Kullanım |
|---|---|---|
| `darkSurface` | `#14233D` | kart/panel zemini |
| `darkSurfaceSoft` | `#1D3155` | kart içi ikincil kutu |
| `darkSurfaceMuted` | `#0E1A2E` | slider oluğu, pasif alan |
| `darkBackground` | `#0A1220` | scaffold zemini |

Cartoon kimliği korunuyor: doygunluk yüksek, gri değil; siyah kontur + sert
gölge üstünde duruyor. `#14233D` üstünde beyaz metnin kontrast oranı **14.6:1**
(WCAG AAA fazlasıyla geçiyor).

---

## 2. Ar-Ge ağacı — başlangıç fabrikası uyumsuzluğu

Tespit doğru ve sebebi net. Başlangıçta seçilen fabrikalar `1=Tekstil`,
`2=Mobilya`, `3=Tarım`. Ar-Ge ağacındaki karşılıkları ve bağımlılıkları:

```
node_001 (Holding Beratı)
└── node_002 (Ağır Sanayi Doktrini)
    ├── node_003  MOBİLYA   ──┬── node_005  TARIM
    │                         └── node_006  Gıda
    └── node_004  Süt        ──┬── node_007  TEKSTİL
                              └── node_008  Otomobil
```

Sonuç: oyuncu Tekstil seçtiyse kendi fabrikasının Ar-Ge'sine (`node_007`)
ulaşmak için önce **Mobilya**(003) + **Süt**(004) almak zorunda — ikisi de
sahip olmadığı fabrikalar. Tarım seçtiyse önce Mobilya almak zorunda.
`_factoryResearchMultiplier` haritası da bunu doğruluyor:

```dart
'1': 'node_007', '2': 'node_003', '3': 'node_005',   // üçü ayrı düğüm
```

### Önerilen çözüm

`node_003` / `node_005` / `node_007` üçünü **tek düğümde** birleştirmek:

```
node_003  "Giriş Seviyesi Sanayi Hattı"   → fabrika 1, 2 ve 3'ü birlikte etkiler
```

Boşalan iki id için iki seçenek var, karar senin:

- **A)** `node_005` ve `node_007` tamamen silinir, ağaç 98 düğüme iner.
- **B)** İkisi yeni içerikle doldurulur (ör. `node_005` → "Giriş Hattı Otomasyonu",
  `node_007` → "Giriş Hattı İhracatı") ve 100 düğüm korunur.

**B'yi öneriyorum** — 100 rakamı oyunun iskeletinde (`node_100` apex'i, Ar-Ge
ekranı kolon yerleşimi, kayıt dosyası) yer etmiş; silmek hem ekran düzenini
hem eski kayıtları bozar.

Dokunulacak yerler: `_initDefaultResearchNodes` (3 satır),
`_factoryResearchMultiplier` (harita), `node_005`/`node_006`/`node_007`/`node_008`
`parentIds` listeleri, `research_screen.dart` kolon yerleşimi, `_loadResearchFromJson`
içine eski kayıt göçü (silinen düğümlerin seviyesi `node_003`'e devredilmeli).

---

## 3. Ekonomi — teşhis

### Kök neden: maliyet, gelirden **kat kat** hızlı büyüyor

```dart
manualIncome = baseIncome * 1.12^(level-1)    // gelir  ×1.12 / seviye
upgradeCost  = baseCost   * 1.32^level        // maliyet ×1.32 / seviye
```

Oran her seviyede `1.32 / 1.12 = 1.1786` katlanıyor:

| Seviye | Gelir ×  | Maliyet ×  | Maliyet/Gelir |
|---|---|---|---|
| 1  | 1,0   | 15,8      | 15,8 |
| 20 | 8,6   | 3.095     | 359 |
| 40 | 83,1  | 798.200   | 9.608 |
| 60 | 801,4 | 2,06e+08  | **256.900** |

Bunun somut sonucu: **bir ürünü 60. seviyeye çıkarmanın geri ödeme süresi,
hangi fabrika olursa olsun sabit 1.115 saat.** (Fab 1 için de, Fab 8 için de
aynı — çünkü oran fabrikadan bağımsız.) Yani fabrika içi geliştirme hiçbir
zaman kendini amorti etmiyor.

Tek gerçek ilerleme kaldıracı yeni fabrika açmak kalıyor ve o da gelirde
**60× / 13× / 17× / 21× / 25× / 30×** gibi sert sıçramalar yapıyor. Oyunun
"bazen sıkıcı bazen çok hızlı" hissinin kaynağı tam olarak bu:

> **duvar → sıçrama → duvar → sıçrama**

### Ayrıca: oyun mevcut haliyle bitirilemiyor

Simülatörü mevcut sabitlerle 90 gün × 30 dk çalıştırdım:

| Gün | Gelir/sn | Ciro | Açılan fabrika |
|---|---|---|---|
| 10 | 1,91e+02 | 4,27e+06 | 3 / 15 |
| 30 | 2,05e+04 | 1,03e+09 | 4 / 15 |
| 60 | 3,06e+06 | 1,55e+11 | 6 / 15 |
| **90** | **3,67e+08** | **2,97e+13** | **7 / 15** |

90 günün sonunda ciro **2,97e13**. İlk prestij eşiği `1e20` — yani **7 milyon kat**
uzakta. Fabrika 15'in fiyatı `5e29`, prestij eşiğinin **1 milyar katı**; prestij
olmadan zaten erişilemez. Mevcut tempoyla oyun 3 ayda değil, **yıllar** sürüyor.

---

## 4. Ekonomi — önerilen yeni model

Üç yapısal değişiklik:

**(a) Kilometre taşı çarpanı.** Her **10 seviyede gelir ×2**. Bu, etkin gelir
büyümesini `1.12 × 2^0.1 = 1.2004`'e çıkarır; maliyetle arasındaki makas
1.1786'dan **1.115**'e iner. Duvar kırılır, her 10. seviye görünür bir ödül olur.

**(b) Bantlı maliyet büyümesi.** Üst seviyelerde maliyet artışı yavaşlar —
oyunun son üçte birindeki grind'i kırar:

| Seviye bandı | Maliyet büyümesi |
|---|---|
| 0–29  | 1,339 |
| 30–44 | 1,299 |
| 45–59 | 1,259 |

**(c) Düzgün fabrika zinciri.** Gelir sıçraması her kademede sabit **×30**
(şu anki 13×–60× dağınıklığı yerine), fiyat = o fabrikanın taban maliyetinin
**12.000 katı**. Fabrika 15 artık prestij eşiğinin altında kalıyor.

### Kalibrasyon sonucu

```
inc_g = 1.12   cost_g = 1.339 (bantlı)   ms = her 10 lvl ×2
fac_inc_k = 30   fac_price_k = 12.000   offline: %25 verim / 8 saat tavan
```

**30 dk/gün oynayan oyuncu → 88. günde bitiriyor.** (Hedef: 90)

| Gün | Gelir/sn | Ciro | Fabrika | Toplam seviye | 10 günlük büyüme |
|---|---|---|---|---|---|
| 1  | 4,13e+01 | 7,89e+04 | 3  | 60   | — |
| 10 | 1,63e+05 | 2,37e+09 | 4  | 809  | — |
| 20 | 3,74e+07 | 8,08e+11 | 6  | 1456 | 341× |
| 30 | 2,78e+10 | 5,45e+14 | 8  | 2055 | 674× |
| 40 | 1,47e+13 | 3,73e+17 | 9  | 2563 | 685× |
| 50 | 1,18e+16 | 2,77e+20 | 11 | 3155 | 742× |
| 60 | 9,41e+18 | 1,93e+23 | 13 | 3743 | 699× |
| 70 | 7,45e+21 | 1,37e+26 | 15 | 4331 | 710× |
| 80 | 1,25e+23 | 5,80e+27 | 15 | 4473 | 42× |
| 88 | 7,27e+23 | 3,82e+28 | 15 | 4500 | 7× |

20–70. günler arasında büyüme **sabit ~700×/10 gün** (≈ 3,5 günde bir 10 kat).
Fabrika açılışları da düzgün dağılıyor: 10.gün 4 → 30.gün 8 → 50.gün 11 →
70.gün 15. Aradığın "ne sıkıcı ne aşırı hızlı" tempo bu.

Son 18 gün hâlâ bir kuyruk (max'lama aşaması) — bunu prestij/unvan hedefleriyle
doldurmayı öneriyorum, ham eğriyi daha da düzleştirmek yerine.

### Dayanıklılık

Tempo, oyuncu davranışındaki sapmalara karşı sağlam:

| Günlük süre | Bitiş |
|---|---|
| 15 dk | 111 gün |
| 20 dk | 102 gün |
| **30 dk** | **88 gün** |
| 45 dk | 73 gün |
| 60 dk | 64 gün |

(Mevcut modelde bu eğri kopuktu: `cost_g` 1,24 → 80 gün, 1,26 → 128 gün.
Yeni modelde aynı aralık 1,335 → 81 gün, 1,345 → 103 gün — çok daha yumuşak,
yani ileride ince ayar yapmak kolay.)

### Bağlı sistemler

Bu eğri sabitlenince şunlar da yeniden türetilmeli (henüz yapılmadı — 3. aşama):

- **Ar-Ge puanı (RP):** 100 düğümün toplam maliyeti ~1.100 RP. Prestij formülü
  `10 × √(ciro/1e20)` bu eğriye göre yeniden ölçeklenmeli, yoksa RP ya sel olur
  ya kıtlık.
- **Görevler:** 4 görev de tek seferlik (`statAdsWatched≥3`, `statWheelSpins≥1`,
  `statClicks≥20`, `statStocks≥3`) — 90 günlük bir oyun için ilk 10 dakikada
  biter. Günlük/haftalık döngüye çevrilmeli.
- **Başarımlar:** `achievementTargets` kademeleri ve
  `getAchievementMoneyReward = 1500 × 2.2^tier` yeni ciro eğrisine göre
  yeniden hizalanmalı.
- **Vergi:** `baseIncomePerSecond × periyot × oran` — gelir eğrisi değişince
  vergi yükü de otomatik değişir, oranın yeni eğride oyuncuyu boğmadığı
  doğrulanmalı.

---

## 5. Dil sistemi — mevcut durum

| | Sayı |
|---|---|
| Kodda `.tr()` çağrısı | 25 |
| Benzersiz çeviri anahtarı | 23 |
| Sabit kodlanmış metin (tahmini) | **~550** |

Yani oyunun **yaklaşık %4'ü** çevrilmiş durumda. Dağılım:

| Dosya | Sabit metin |
|---|---|
| `providers/game_state.dart` | ~370 (fabrika/ürün/Ar-Ge/hisse adları + açıklamalar) |
| `screens/map_screen.dart` | ~50 |
| `screens/factory_screen.dart` | ~48 |
| `screens/main_menu_screen.dart` | ~20 |
| `widgets/achievements.dart` | ~20 |
| `widgets/wheel.dart` | ~15 |
| diğer 6 dosya | ~27 |

`game_state.dart`'taki 370 metnin büyük kısmı **`effectBuilder` closure'ları** —
yani `(lvl) => 'Tüm Fabrika Taban Geliri: +%${lvl * 3}'` gibi parametreli
metinler. Bunlar düz string değil; her biri `'research.node_001.effect'.tr(params: {'v': ...})`
biçimine çevrilmeli. Mekanik ama 100 düğüm × (başlık + açıklama + efekt) = **300 anahtar**
sadece Ar-Ge için.

Toplam iş: ~550 anahtar × 6 dil = **~3.300 çeviri kaydı**.

---

## 6. Teslimat planı

| Aşama | İçerik | Durum |
|---|---|---|
| **1** | Analiz + denge modeli + temel dosyalar (`balance.dart`, `app_theme.dart`, `translation_service.dart`) | **bu teslimat** |
| **2** | Ar-Ge birleştirme + `game_state.dart` denge entegrasyonu | onay sonrası |
| **3** | Görev / başarım / RP / vergi yeniden hizalama | onay sonrası |
| **4** | 12 ekran dosyasında koyu tema metin taraması (~101 nokta) | onay sonrası |
| **5** | ~550 metnin anahtarlaştırılması + 6 dil JSON'u | onay sonrası |

Aşama 1'i bilerek önce verdim: 2–5'in **hepsi** bu üç dosyanın API'sine
yaslanıyor. Token isimleri veya denge sabitleri sonradan değişirse 12.000 satır
yeniden dokunulmak zorunda kalır.

---

## 7. Onayını beklediğim kararlar

1. **"Oyunu bitirmek" ne demek?** Modeli "15 fabrika açık + hepsi 300. seviye"
   olarak kalibre ettim. Alternatifler: ilk prestij, `node_100` (apex Ar-Ge),
   ya da `1e33` ciro unvanı. Bu tanım tüm eğriyi değiştirir.
2. **Ar-Ge birleştirmede A mı B mi?** (98 düğüm vs. 100 düğüm — B öneriyorum)
3. **Koyu mavi paleti** yukarıdaki 4 ton uygun mu?
4. **Eski kayıtlar:** Denge tamamen değişince mevcut oyuncu kayıtları anlamsız
   kalır (eski fiyatlarla alınmış seviyeler). Göç mü yazalım, yoksa sürüm
   atlayınca sıfırlama mı?
5. **Bozuk 3 dosyanın** orijinali sende var mı?
