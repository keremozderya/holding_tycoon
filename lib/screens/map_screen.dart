import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../theme/app_theme.dart';
import '../widgets/achievements.dart'; 
import '../widgets/prestige_dialog.dart';
import '../widgets/tasks.dart'; 
import 'main_menu_screen.dart';
import 'research_screen.dart';
import 'stock_screen.dart';
import 'settings_screen.dart';

// --- TEMA RENKLERİ ---
const Color themeOceanBlue = Color(0xFF22CECE);
const Color themeIslandGreen = Color(0xFFA5C05B);
const Color themeSandYellow = Color(0xFFF3D78F);
const Color themeAsphaltDark = Color(0xFF2D2D2D);
const Color themeLighthouseRed = Color(0xFFD64D4D);

// --- 1. FLUTTER UI (Geleneksel ve Köşeli Arayüz) ---
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _holdingName = 'İlaç Fabrikası';
  int _holdingLogoIndex = 0; 
  double _currentTurnover = 2.45e20;
  final int _testHighestFactoryLevel = 30;

  final List<IconData> _defaultLogos = const [
    Icons.domain_rounded,
    Icons.account_balance_rounded,
    Icons.factory_rounded,
    Icons.rocket_launch_rounded,
    Icons.local_shipping_rounded,
    Icons.bolt_rounded,
  ];

  late final HoldingTycoonGame _game;

  @override
  void initState() {
    super.initState();
    // Arayüzdeki _holdingName değişkenini oyun motoruna besliyoruz
    _game = HoldingTycoonGame(holdingName: _holdingName);
    _loadHoldingData();
  }

  Future<void> _loadHoldingData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _holdingName = prefs.getString('holding_name') ?? 'Köse Holding';
      _holdingLogoIndex = prefs.getInt('holding_logo_index') ?? 0; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeOceanBlue,
      body: SafeArea(
        bottom: false,
        top: false, 
        child: Stack(
          children: [
            GameWidget(game: _game),

            // 1. Üst Bar ve Sarkan Para Cebi (Tek Parça Halinde)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopPanel(context),
            ),

            // 2. Alt Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildUnifiedBottomBar(context),
            ),
            
            // 3. Sağ Kenar Butonları
            Positioned(
              right: 16,
              top: 130, 
              child: _buildSideActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // --- BİRLEŞTİRİLMİŞ ÜST PANEL (Hatasız ve Net) ---
  Widget _buildTopPanel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTraditionalTopBar(context),
        // Transform (kaydırma) hilesini kaldırdık, doğrudan barın altına yapışık çiziliyor
        _buildMoneyPocket(), 
      ],
    );
  }

  // Sadece Üst Bar (İnceltilmiş ve Dolu Dolu)
  Widget _buildTraditionalTopBar(BuildContext context) {
    const Color classicBrown = Color(0xFF5D4037); 
    const Color lightBrown = Color(0xFF7A574A); 
    const Color darkBrown = Color(0xFF3D2821);

    IconData holdingIcon = _defaultLogos.isNotEmpty && _holdingLogoIndex >= 0 && _holdingLogoIndex < _defaultLogos.length 
        ? _defaultLogos[_holdingLogoIndex] 
        : Icons.domain_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB59A45), themeSandYellow, Color(0xFFF2DC8F)],
          stops: [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4), 
            blurRadius: 10, 
            offset: const Offset(0, 4) 
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              // DİKKAT: Üst ve alt paddingleri sıfıra yaklaştırdık! İçerik barı tam dolduracak.
              padding: const EdgeInsets.only(top: 6, bottom: 2, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildCircularLogo(holdingIcon),
                      const SizedBox(width: 10),
                      _buildHoldingTitle(_holdingName, classicBrown, 23), 
                    ],
                  ),
                  _buildHamburgerMenu(context), 
                ],
              ),
            ),
          ),
          
          Container(
            height: 4, 
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, 
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
              ),
            ),
          ),
          
          Container(
            height: 6, 
            decoration: const BoxDecoration(
              color: classicBrown,
              border: Border(
                top: BorderSide(color: lightBrown, width: 1.5), 
                bottom: BorderSide(color: darkBrown, width: 2.5), 
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- YENİ: BOLD VE TIMES NEW ROMAN TABELA (Sıfır Boşluklu) ---
  Widget _buildHoldingTitle(String text, Color color, double fontSize) {
    return Text(
      text, 
      style: TextStyle(
        fontFamily: 'Times New Roman', 
        color: color,
        fontSize: fontSize, 
        fontWeight: FontWeight.bold, 
        letterSpacing: 0.5, 
        height: 1.0, // YENİ: Fontun kendi görünmez satır yüksekliğini sildik, barı esnetemeyecek!
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.8), 
            offset: const Offset(1, 1),
            blurRadius: 0, 
          )
        ],
      ),
    );
  }

  // --- %100 GARANTİLİ VE SABİTLENMİŞ PARA CEBİ ---
  Widget _buildMoneyPocket() {
    return Center(
      child: Container(
        width: 150, // SABİT GENİŞLİK (Sıkışma ve ezilme ihtimalini yok eder)
        height: 38, // SABİT YÜKSEKLİK
        decoration: const BoxDecoration(
          color: Color(0xFF5D4037), // classicBrown
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)), 
          border: Border(
            bottom: BorderSide(color: Color(0xFF3D2821), width: 3), // darkBrown
            left: BorderSide(color: Color(0xFF7A574A), width: 2), // lightBrown
            right: BorderSide(color: Color(0xFF7A574A), width: 2), // lightBrown
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54, 
              blurRadius: 6, 
              offset: Offset(0, 4)
            )
          ],
        ),
        alignment: Alignment.center, // İçeriği kutunun tam merkezine çiviler
        child: const Directionality(
          textDirection: TextDirection.ltr, // Metin yönünü zorla belirler (Hataları önler)
          child: Material(
            color: Colors.transparent,
            child: Text(
              "\$ 1.500.000", // İkonu sildik, sembolü doğrudan metne ekledik
              style: TextStyle(
                color: themeSandYellow, // Kumsal sarısı bakiye
                fontSize: 18, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.2,
                decoration: TextDecoration.none, 
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible, // Taşsa bile görünmesini zorlar
            ),
          ),
        ),
      ),
    );
  }


  // --- BÜYÜK AMA BARA SIĞAN LOGO ---
  Widget _buildCircularLogo(IconData icon) {
    return Container(
      width: 38, // Bara tam oturması için 46'dan 44'e milimetrik ayar
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF3D2821), 
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB59A45), width: 2.5), 
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(1, 2))
        ],
      ),
      child: Center(
        child: _build3DTopIcon(icon, themeSandYellow, iconSize: 25),
      ),
    );
  }


  Widget _buildHamburgerMenu(BuildContext context) {
    const Color classicBrown = Color(0xFF5D4037); 
    
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: themeSandYellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: classicBrown, width: 3),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: _build3DTopIcon(Icons.menu_rounded, classicBrown),
        offset: const Offset(0, 50), 
        onSelected: (value) {
          if (value == 'settings') {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
          } else if (value == 'main_menu') {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainMenuScreen(isInitialLaunch: false)));
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_rounded, color: classicBrown),
                SizedBox(width: 10),
                Text('Ayarlar', style: TextStyle(color: classicBrown, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'main_menu',
            child: Row(
              children: [
                Icon(Icons.exit_to_app_rounded, color: Colors.red.shade700),
                SizedBox(width: 10),
                Text('Ana Menü', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DText(String text, Color color, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.6),
            offset: const Offset(1, 1),
            blurRadius: 0,
          )
        ],
      ),
    );
  }

  // --- DİNAMİK BOYUTLU 3D İKON ---
  Widget _build3DTopIcon(IconData icon, Color color, {double iconSize = 28}) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.6), 
            color,                           
            color.withValues(alpha: 0.3),    
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: Icon(
        icon, 
        size: iconSize, // Gelen dinamik boyutu (veya varsayılan 28'i) kullanır
        color: Colors.white, 
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(1.5, 2),
            blurRadius: 3, 
          )
        ],
      ),
    );
  }

  // --- ALT BAR TASARIMI ---
  Widget _buildUnifiedBottomBar(BuildContext context) {
    const Color classicBrown = Color(0xFF5D4037); 
    const Color lightBrown = Color(0xFF7A574A); 
    const Color darkBrown = Color(0xFF3D2821);  

    return Container(
      height: 95, 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB59A45), themeSandYellow, Color(0xFFF2DC8F)],
          stops: [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4), 
            blurRadius: 12, 
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 10, 
            decoration: const BoxDecoration(
              color: classicBrown,
              border: Border(
                top: BorderSide(color: lightBrown, width: 2.5), 
                bottom: BorderSide(color: darkBrown, width: 3.5), 
              ),
            ),
          ),
          
          Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
              ),
            ),
          ),
          
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5), 
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _build3DTab("Araştırmalar", Icons.science_rounded, themeOceanBlue, classicBrown, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResearchScreen()));
                    }),
                    _buildDeepGrooveDivider(), 
                    _build3DTab("Borsa", Icons.assessment_rounded, themeIslandGreen, classicBrown, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockScreen()));
                    }),
                    _buildDeepGrooveDivider(),
                    _build3DTab("Holding", Icons.location_city_rounded, classicBrown, classicBrown, () {}, glareOpacity: 0.2),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _build3DTab(String title, IconData icon, Color iconColor, Color textColor, VoidCallback onTap, {double glareOpacity = 0.9}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: glareOpacity), 
                    iconColor,                           
                    iconColor.withValues(alpha: 0.3),    
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              child: Icon(
                icon, 
                size: 36, 
                color: Colors.white, 
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(1.5, 2.5),
                    blurRadius: 4, 
                  )
                ],
              ),
            ), 
            const SizedBox(height: 6),
            Text(
              title, 
              textAlign: TextAlign.center,
              maxLines: 1, 
              style: TextStyle(
                color: textColor, 
                fontSize: 13, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    offset: const Offset(1, 1),
                    blurRadius: 0,
                  )
                ]
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepGrooveDivider() {
    return Container(
      height: 48,
      width: 4, 
      decoration: BoxDecoration(
        color: themeSandYellow,
        border: Border(
          left: BorderSide(color: Colors.black.withValues(alpha: 0.4), width: 2), 
          right: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2), 
        ),
      ),
    );
  }

  Widget _buildSideActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSideButton(
          icon: Icons.emoji_events_rounded,
          iconColor: themeSandYellow,
          hasNotification: false,
          onTap: () {
            _showDevTestMenu(context); 
          }
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.assignment_rounded,
          iconColor: themeOceanBlue,
          hasNotification: true, // YENİ: Bildirim ışığı burada yanıyor!
          onTap: () {
            TasksDialog.show(context, highestFactoryLevel: _testHighestFactoryLevel);
          }
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.stars_rounded,
          iconColor: themeLighthouseRed,
          hasNotification: false,
          onTap: () {
            // Prestij
          }
        ),
      ],
    );
  }

  void _showDevTestMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeAsphaltDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kerem bu menü niye var amk', style: TextStyle(color: themeSandYellow, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildMenuBtn(Icons.emoji_events_rounded, themeSandYellow, 'Başarımlar (Test)', () {
                Navigator.pop(context);
                AchievementsDialog.show(context);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuBtn(IconData icon, Color color, String title, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black26,
          foregroundColor: Colors.white,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: Icon(icon, color: color, size: 20),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: onTap,
      ),
    );
  }
} // <--- _MapScreenState SINIFI TAM OLARAK BURADA BİTİYOR!

// ============================================================================
// BUNDAN SONRAKİ SINIFLAR DIŞARIDA VE BAĞIMSIZ OLMALIDIR
// ============================================================================

class AnimatedSideButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool hasNotification; // YENİ PARAMETRE

  const AnimatedSideButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  State<AnimatedSideButton> createState() => _AnimatedSideButtonState();
}

class _AnimatedSideButtonState extends State<AnimatedSideButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), 
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color classicBrown = Color(0xFF5D4037);

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation, 
        child: Stack(
          clipBehavior: Clip.none, // Noktanın dışarı taşmasına izin verir
          children: [
            // ANA BUTON
            Container(
              width: 40, 
              height: 40,
              decoration: BoxDecoration(
                color: classicBrown,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7A574A), width: 1.5),
                boxShadow: [
                  BoxShadow(color: widget.iconColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 0)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(2, 3))
                ],
              ),
              child: Center(
                child: _buildSmall3DIcon(widget.icon, widget.iconColor),
              ),
            ),
            
            // YENİ: BİLDİRİM IŞIĞI (Sadece hasNotification true ise çalışır)
            if (widget.hasNotification)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: themeLighthouseRed, // Kırmızı bildirim
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: themeLighthouseRed.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmall3DIcon(IconData icon, Color color) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.6), color, color.withValues(alpha: 0.3)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: Icon(icon, size: 22, color: Colors.white, shadows: [
        Shadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(1, 1.5), blurRadius: 2)
      ]),
    );
  }
}

// --- FLAME OYUN MOTORU VE DALGALAR ---
class OpenSeaRipples extends Component {
  double _time = 0;
  final Paint _ripplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3.5;

  @override
  void update(double dt) {
    _time += dt * 0.6; 
  }

  @override
  void render(Canvas canvas) {
    for (double y = -200; y < 3400; y += 120) {
      for (double x = -100; x < 1200; x += 150) {
        
        double offsetX = math.sin(y * 3.2) * 60;
        double offsetY = math.cos(x * 2.1) * 40;

        double baseX = x + offsetX;
        double baseY = y + offsetY;

        double phase = _time + (baseX * 0.01) + (baseY * 0.015);
        double cycle = phase % (math.pi * 2);

        if (cycle < math.pi) {
          double alpha = math.sin(cycle);
          _ripplePaint.color = Colors.white.withValues(alpha: alpha * 0.35);

          double flowDrift = (cycle / math.pi) * 45.0; 
          double currentX = baseX - flowDrift; 

          Path ripple = Path();
          ripple.moveTo(currentX, baseY);
          ripple.quadraticBezierTo(
            currentX + 20, baseY + 5, 
            currentX + 40, baseY
          );

          canvas.drawPath(ripple, _ripplePaint);
        }
      }
    }
  }
}

class PerfectPngWaves extends Component {
  final Sprite mapSprite;
  final double mapWidth;
  final double mapHeight;
  
  double _time = 0;

  PerfectPngWaves({
    required this.mapSprite,
    required this.mapWidth,
    required this.mapHeight,
  });

  @override
  void update(double dt) {
    _time += dt * 0.12; 
  }

  @override
  void render(Canvas canvas) {
    Path fullScreen = Path()..addRect(Rect.fromLTWH(-500, -500, mapWidth + 1000, mapHeight + 1000));
    
    Path lighthouseMask = Path()..addOval(Rect.fromLTRB(965, 1340, 1300, 1540));
    Path bottomRocksMask = Path()..addOval(Rect.fromLTRB(-20, 2800, 120, 3100));
    Path topRocksMask = Path()..addOval(Rect.fromLTRB(-20, 400, 140, 600));

    Path safeWaterZone = Path.combine(PathOperation.difference, fullScreen, lighthouseMask);
    safeWaterZone = Path.combine(PathOperation.difference, safeWaterZone, bottomRocksMask);
    safeWaterZone = Path.combine(PathOperation.difference, safeWaterZone, topRocksMask);

    for (int i = 0; i < 3; i++) {
      double progress = ((_time * 0.5) - (i * 0.333)) % 1.0;
      if (progress < 0) progress += 1.0;

      double reversedProgress = 1.0 - progress;
      double spread = reversedProgress * 70.0; 

      double scaleX = (mapWidth + (spread * 2)) / mapWidth;
      double scaleY = (mapHeight + (spread * 2)) / mapHeight;

      double alpha = math.sin(reversedProgress * math.pi) * 0.45;
      if (alpha <= 0) continue;

      Color waveBaseColor = Color.lerp(Colors.white, themeOceanBlue, 0.25)!;
      
      final wavePaint = Paint()
        ..colorFilter = ColorFilter.mode(
          waveBaseColor.withValues(alpha: alpha), 
          BlendMode.srcIn
        );

      canvas.save();
      
      canvas.clipPath(safeWaterZone);
      
      double shallowShift = spread * 0.75; 
      
      canvas.translate((mapWidth / 2) + shallowShift, mapHeight / 2);
      canvas.scale(scaleX, scaleY);
      canvas.translate(-mapWidth / 2, -mapHeight / 2);

      mapSprite.render(
        canvas, 
        size: Vector2(mapWidth, mapHeight), 
        overridePaint: wavePaint
      );
      
      canvas.restore();
    }
  }
}

class HoldingTycoonGame extends FlameGame with PanDetector {
  
  String holdingName; // YENİ: Arayüzden gelen ismi tutacak değişken
  late final CameraComponent cam;
  final World mapWorld = World();

  double mapWidth = 1080.0;
  double mapHeight = 3000.0; // Resim boyutuna göre güncellenecek

  final double topPadding = 300.0;
  final double bottomPadding = 450.0;

  HoldingTycoonGame({this.holdingName = "KÖSE HOLDİNG"}) {
    cam = CameraComponent(world: mapWorld);
  }

  @override
  Color backgroundColor() => themeOceanBlue; 

  @override
  Future<void> onLoad() async {
    add(mapWorld);

    try {
      final mapSprite = await Sprite.load('map.png');
      
      double originalWidth = mapSprite.srcSize.x;
      double originalHeight = mapSprite.srcSize.y;
      mapHeight = mapWidth * (originalHeight / originalWidth);
      
      mapWorld.add(OpenSeaRipples());

      mapWorld.add(PerfectPngWaves(
        mapSprite: mapSprite, 
        mapWidth: mapWidth, 
        mapHeight: mapHeight
      ));

      // Asıl harita eklendi
      final mapComponent = SpriteComponent(
        sprite: mapSprite,
        size: Vector2(mapWidth, mapHeight),
      );
      mapWorld.add(mapComponent);
      
      // ==========================================
      // YENİ: İLK TEST BİNAMIZ (LİMAN)
      // ==========================================
      final ShipyardPort = ShipyardPortBuilding()
        // X ekseninde adanın tam ortası (mapWidth / 2)
        // Y ekseninde kıyı yüksekliği (Ben 600 verdim, senin png'deki su sınırına göre bu sayıyı 500, 650 falan yapıp tam kıyıya oturtabilirsin)
        ..position = Vector2(mapWidth / 2.46, 1760); 
      
      mapWorld.add(ShipyardPort);

      // ==========================================
      // YENİ: DEV FABRİKA (Haritanın iç/orta kısmına)
      // ==========================================
      final giantFactory = GiantFactoryBuilding(holdingName)
        ..position = Vector2(mapWidth * 0.31, 350); 

      mapWorld.add(giantFactory);
      // ==========================================

    } catch (e) {
      debugPrint("PNG YÜKLEME HATASI: $e");
    }

    cam.viewfinder.anchor = Anchor.topLeft;
    cam.viewfinder.position = Vector2(0, -topPadding);
    add(cam);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    cam.viewfinder.zoom = size.x / mapWidth;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final delta = info.delta.global;
    double newY = cam.viewfinder.position.y - (delta.y / cam.viewfinder.zoom);
    double maxScroll = mapHeight - (size.y / cam.viewfinder.zoom) + bottomPadding;
    cam.viewfinder.position = Vector2(0, newY.clamp(-topPadding, maxScroll > -topPadding ? maxScroll : -topPadding));
  }
}

// --- 4. TEST BİNASI: İZOMETRİK 3D HANGAR VE İSKELE ---
class AbandonedPortBuilding extends PositionComponent {
  AbandonedPortBuilding() {
    // Hem iskeleyi hem hangarı içine alacak kadar genişletildi
    size = Vector2(160, 160);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    // ==========================================
    // 1. DAHA SOLA UZAYAN İZOMETRİK GÖLGE (SHADOW)
    // ==========================================
    Path shadowPath = Path()
      ..moveTo(65, 135)  // Ön iskele ayağı
      ..lineTo(90, 130)  // Hangar ön alt köşe
      ..lineTo(140, 105) // Hangar sağ alt köşe
      ..lineTo(140, 65)  // Hangar sağ üst duvar
      ..lineTo(130, 30)  // Çatı arka zirve
      ..lineTo(80, 55)   // Çatı ön zirve
      ..lineTo(70, 50)   // İskele arka uç
      ..lineTo(20, 75)   // İskele sol uç (Denize uzanan kısım)
      ..lineTo(30, 115)  // Sol iskele ayağı
      ..close();

    canvas.save();
    // YENİ DÜZENLEME: X ekseninde (-35) yaparak gölgeyi iyice sola yatırdık!
    canvas.translate(-35, -10); 
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55) // Gölge sola uzadığı için daha soft/gerçekçi bir saydamlık
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4), // Kenar yumuşaklığı (blur) artırıldı
    );
    canvas.restore();

    // ==========================================
    // 2. DENİZE UZANAN 3D İSKELE (PIER)
    // ==========================================
    // İskele Ayakları (Suya batan beton/ahşap kazıklar)
    final pillarPaint = Paint()..color = const Color(0xFF1B1B1B)..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(30, 85), const Offset(30, 115), pillarPaint); // Sol uç ayak
    canvas.drawLine(const Offset(70, 105), const Offset(70, 135), pillarPaint); // Ön ayak
    canvas.drawLine(const Offset(110, 85), const Offset(110, 115), pillarPaint); // Sağ ayak (Hangara bitişik)

    // İskele Ahşap Zemin (Üst Yüzey)
    Path pierTop = Path()
      ..moveTo(20, 75)   // Sol uç
      ..lineTo(70, 100)  // Ön uç
      ..lineTo(120, 75)  // Sağ uç (Hangara girer)
      ..lineTo(70, 50)   // Arka uç
      ..close();
    canvas.drawPath(pierTop, Paint()..color = const Color(0xFF6D4C41));

    // İskele Sol Kalınlık (Derinlik)
    Path pierLeftEdge = Path()
      ..moveTo(20, 75)..lineTo(70, 100)..lineTo(70, 106)..lineTo(20, 81)..close();
    canvas.drawPath(pierLeftEdge, Paint()..color = const Color(0xFF4E342E));

    // İskele Sağ Kalınlık (Derinlik)
    Path pierRightEdge = Path()
      ..moveTo(70, 100)..lineTo(120, 75)..lineTo(120, 81)..lineTo(70, 106)..close();
    canvas.drawPath(pierRightEdge, Paint()..color = const Color(0xFF3E2723));

    // İskele Üzerinde Ahşap Çizgileri (Detay)
    final woodLinePaint = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 1;
    canvas.drawLine(const Offset(30, 70), const Offset(80, 95), woodLinePaint);
    canvas.drawLine(const Offset(40, 65), const Offset(90, 90), woodLinePaint);
    canvas.drawLine(const Offset(50, 60), const Offset(100, 85), woodLinePaint);

    // ==========================================
    // 3. ENDÜSTRİYEL TİCARİ HANGAR (A-FRAME)
    // ==========================================
    // Hangar Sol Duvar (İskeleye bakan, kapının olduğu yüz)
    Path hangarLeftWall = Path()
      ..moveTo(70, 120)..lineTo(90, 130)..lineTo(90, 90)..lineTo(70, 80)..close();
    canvas.drawPath(hangarLeftWall, Paint()..color = const Color(0xFF5A6673)); // Endüstriyel mat mavi-gri

    // Hangar Sağ Duvar (Karanlıkta kalan yüz)
    Path hangarRightWall = Path()
      ..moveTo(90, 130)..lineTo(140, 105)..lineTo(140, 65)..lineTo(90, 90)..close();
    canvas.drawPath(hangarRightWall, Paint()..color = const Color(0xFF3B444B));

    // Dev Sürgülü Hangar Kapısı (Sol Duvarda)
    Path hangarDoor = Path()
      ..moveTo(75, 112.5)..lineTo(85, 117.5)..lineTo(85, 95.5)..lineTo(75, 90.5)..close();
    canvas.drawPath(hangarDoor, Paint()..color = const Color(0xFF111111));

    // Kapı Altı Sarı-Siyah Güvenlik Şeridi
    Path warningStripe = Path()
      ..moveTo(75, 112.5)..lineTo(85, 117.5)..lineTo(85, 115)..lineTo(75, 110)..close();
    canvas.drawPath(warningStripe, Paint()..color = const Color(0xFFF9A825));

    // ==========================================
    // 4. HANGAR METAL ÇATISI (Oluklu Sac)
    // ==========================================
    // Çatı Sol Panel (Işık alan yüz)
    Path roofLeft = Path()
      ..moveTo(70, 80)..lineTo(80, 55)..lineTo(130, 30)..lineTo(120, 55)..close();
    canvas.drawPath(roofLeft, Paint()..color = const Color(0xFF90A4AE));

    // Çatı Sağ Panel (Gölgede kalan yüz)
    Path roofRight = Path()
      ..moveTo(90, 90)..lineTo(80, 55)..lineTo(130, 30)..lineTo(140, 65)..close();
    canvas.drawPath(roofRight, Paint()..color = const Color(0xFF78909C));

    // Çatı Zirve Demiri (Omurga)
    canvas.drawLine(
      const Offset(80, 55), 
      const Offset(130, 30), 
      Paint()..color = const Color(0xFF455A64)..strokeWidth = 3..strokeCap = StrokeCap.round
    );

    // ==========================================
    // 5. UFAK DETAY: İSKELEDE TİCARİ SANDIK (KUTU)
    // ==========================================
    Path crateTop = Path()..moveTo(35, 72)..lineTo(45, 77)..lineTo(50, 74)..lineTo(40, 69)..close();
    canvas.drawPath(crateTop, Paint()..color = const Color(0xFFD7CCC8));
    
    Path crateLeft = Path()..moveTo(35, 82)..lineTo(45, 87)..lineTo(45, 77)..lineTo(35, 72)..close();
    canvas.drawPath(crateLeft, Paint()..color = const Color(0xFF8D6E63));
    
    Path crateRight = Path()..moveTo(45, 87)..lineTo(50, 84)..lineTo(50, 74)..lineTo(45, 77)..close();
    canvas.drawPath(crateRight, Paint()..color = const Color(0xFF5D4037));
  }
}

// --- HAREKETLİ VE DAĞILAN DUMAN PARTİKÜL SINIFI ---
class SmokeParticle {
  Vector2 position;
  Vector2 velocity; // YENİ: Her dumanın kendine has savrulma hızı
  double radius;
  double life;
  double maxLife;

  SmokeParticle(this.position, this.velocity, this.radius, this.maxLife) : life = maxLife;
}

// --- 5. YENİ BİNA: DEV SANAYİ FABRİKASI (AAA DETAYLI) ---
class GiantFactoryBuilding extends PositionComponent {
  final String holdingName; // YENİ: Holding ismini alacak değişken
  final List<SmokeParticle> _particles = [];
  double _timer = 0;
  double _smokeTimer = 0;
  final math.Random _rnd = math.Random();

  GiantFactoryBuilding(this.holdingName) { // Kurucu metoda eklendi
    size = Vector2(300, 240); 
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    _smokeTimer += dt;

    if (_smokeTimer > 0.4) { 
      _smokeTimer = _rnd.nextDouble() * 0.2; 
      _particles.add(SmokeParticle(
        Vector2(240 + (_rnd.nextDouble() * 8 - 4), -45), 
        Vector2(-20 - _rnd.nextDouble() * 25, -35 - _rnd.nextDouble() * 25),
        5.0 + _rnd.nextDouble() * 4.0,
        2.0 + _rnd.nextDouble() * 1.5
      ));
    }

    for (int i = _particles.length - 1; i >= 0; i--) {
      var p = _particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        _particles.removeAt(i);
      } else {
        p.position.x += p.velocity.x * dt; 
        p.position.y += p.velocity.y * dt; 
        p.radius += dt * 22;     
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. GÖLGE
    Path shadowPath = Path()..moveTo(100, 180)..lineTo(260, 100)..lineTo(255, -50)..lineTo(225, -50)..lineTo(180, 0)..lineTo(20, 80)..lineTo(20, 140)..close();
    canvas.save();
    canvas.translate(-50, -10);
    canvas.drawPath(shadowPath, Paint()..color = Colors.black.withValues(alpha: 0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.restore();

    // ==========================================
    // 2. YENİ: DUVAR BOYUNCA UZANAN DİKEY ÇİZGİLİ BOŞ OTOPARK
    // ==========================================
    // Asfalt zemin sağ duvarın ön köşesinden tankere kadar uzanır
    Path parkingAsphalt = Path()
      ..moveTo(100, 180) // Duvar ön köşe
      ..lineTo(230, 115) // Duvar arka köşe (Tankerden hemen önce)
      ..lineTo(280, 140) // Dış arka köşe (Derinlik)
      ..lineTo(150, 205) // Dış ön köşe
      ..close();
    canvas.drawPath(parkingAsphalt, Paint()..color = const Color(0xFF263238));

    // Dikey (Duvara dik açıyla) park şeritleri
    final linePaint = Paint()..color = const Color(0xFFFBC02D).withValues(alpha: 0.8)..strokeWidth = 1.5;
    
    // Duvar boyunca her 20 pikselde bir duvara dik sarı park çizgisi çeker
    for (int i = 1; i <= 6; i++) {
      double startX = 100.0 + (i * 20); 
      double startY = 180.0 - (i * 10); 
      
      // Çizgiler duvardan dışarıya (izometrik dışa) doğru uzar
      double endX = startX + 40;
      double endY = startY + 20;
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }

    // 3. YÜKSELTİLMİŞ YAKIT TANKERİ
    final legPaint = Paint()..color = const Color(0xFF37474F)..strokeWidth = 2;
    canvas.drawLine(const Offset(265, 70), const Offset(265, 95), legPaint);
    canvas.drawLine(const Offset(285, 60), const Offset(285, 85), legPaint);
    canvas.drawLine(const Offset(270, 75), const Offset(270, 100), legPaint);
    canvas.drawLine(const Offset(290, 65), const Offset(290, 90), legPaint);
    canvas.drawOval(Rect.fromLTWH(260, 40, 35, 40), Paint()..color = const Color(0xFF90A4AE)); 
    canvas.drawOval(Rect.fromLTWH(265, 45, 30, 30), Paint()..color = const Color(0xFFCFD8DC)); 
    canvas.drawLine(const Offset(260, 60), const Offset(295, 60), Paint()..color = const Color(0xFF546E7A)..strokeWidth = 1.5); 

    // 4. ANA DUVARLAR VE KAPILAR
    canvas.drawPath(Path()..moveTo(100, 180)..lineTo(20, 140)..lineTo(20, 80)..lineTo(100, 120)..close(), Paint()..color = const Color(0xFF78909C));
    canvas.drawPath(Path()..moveTo(100, 180)..lineTo(260, 100)..lineTo(260, 40)..lineTo(100, 120)..close(), Paint()..color = const Color(0xFF455A64));
    
    canvas.drawPath(Path()..moveTo(22, 139)..lineTo(98, 177)..lineTo(98, 174)..lineTo(22, 136)..close(), Paint()..color = const Color(0xFFF57F17));
    double glowIntensity = (math.sin(_timer * 3) + 1) / 2; 
    final insideGlow = Paint()..color = Color.lerp(const Color(0xFF263238), const Color(0xFFD84315), glowIntensity * 0.7)!;
    canvas.drawPath(Path()..moveTo(90, 175)..lineTo(80, 170)..lineTo(80, 140)..lineTo(90, 145)..close(), insideGlow);
    canvas.drawPath(Path()..moveTo(70, 165)..lineTo(60, 160)..lineTo(60, 130)..lineTo(70, 135)..close(), insideGlow);
    canvas.drawPath(Path()..moveTo(50, 155)..lineTo(40, 150)..lineTo(40, 120)..lineTo(50, 125)..close(), insideGlow);

    // 5. SAĞ DUVAR PENCERELERİ VE BORU
    canvas.drawLine(const Offset(105, 165), const Offset(255, 90), Paint()..color = const Color(0xFF2E3D45)..strokeWidth = 4);
    final windowPaint = Paint()..color = const Color(0xFFFBC02D);
    canvas.drawPath(Path()..moveTo(120, 160)..lineTo(130, 155)..lineTo(130, 140)..lineTo(120, 145)..close(), windowPaint);
    canvas.drawPath(Path()..moveTo(160, 140)..lineTo(170, 135)..lineTo(170, 120)..lineTo(160, 125)..close(), windowPaint);
    canvas.drawPath(Path()..moveTo(200, 120)..lineTo(210, 115)..lineTo(210, 100)..lineTo(200, 105)..close(), windowPaint);

    // 6. YAN DUVAR ÇERÇEVELİ TABELA 
    Path signBoardFrame = Path()..moveTo(115, 125)..lineTo(225, 70)..lineTo(225, 45)..lineTo(115, 100)..close();
    canvas.drawPath(signBoardFrame, Paint()..color = const Color(0xFF111111));
    Path signBoardInner = Path()..moveTo(118, 121)..lineTo(222, 69)..lineTo(222, 49)..lineTo(118, 101)..close();
    canvas.drawPath(signBoardInner, Paint()..color = const Color(0xFF263238));

    final textPainter = TextPainter(
      text: TextSpan(
        text: holdingName.toUpperCase(),
        style: const TextStyle(color: Color(0xFFFBC02D), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(110, 130); 
    canvas.skew(0, -0.5); 
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    // ==========================================
    // 7. YENİ: UZUNLAMASINA BOYDAN BOYA DEV CAM TAVAN
    // ==========================================
    // Alt Çatı Zemin 
    canvas.drawPath(Path()..moveTo(100, 120)..lineTo(260, 40)..lineTo(180, 0)..lineTo(20, 80)..close(), Paint()..color = const Color(0xFF37474F));
    
    // Üst (İkinci Kat) Çatı Ana Gövdesi
    canvas.drawPath(Path()..moveTo(100, 100)..lineTo(60, 80)..lineTo(60, 55)..lineTo(100, 75)..close(), Paint()..color = const Color(0xFF90A4AE));
    canvas.drawPath(Path()..moveTo(100, 100)..lineTo(220, 40)..lineTo(220, 15)..lineTo(100, 75)..close(), Paint()..color = const Color(0xFF607D8B));
    canvas.drawPath(Path()..moveTo(100, 75)..lineTo(220, 15)..lineTo(180, -5)..lineTo(60, 55)..close(), Paint()..color = const Color(0xFF455A64));

    // Üst Çatıyı Kaplayan Dev Cam Tavan (Havalandırmalara kadar uzanır)
    final glassPaint = Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.5);
    final glassFrame = Paint()..color = const Color(0xFF263238)..strokeWidth = 2..style = PaintingStyle.stroke;

    Path massiveGlass = Path()
      ..moveTo(65, 57.5)   // Sol ön köşe
      ..lineTo(95, 72.5)   // Sağ ön köşe
      ..lineTo(180, 30)    // Sağ arka köşe (Havalandırmanın başladığı sınır)
      ..lineTo(150, 15)    // Sol arka köşe 
      ..close();
    
    canvas.drawPath(massiveGlass, glassPaint); 
    canvas.drawPath(massiveGlass, glassFrame);

    // Çapraz çelik destek çıtaları (Camı 4 panele böler)
    canvas.drawLine(const Offset(80, 65), const Offset(165, 22.5), glassFrame); // Ana dikey omurga
    canvas.drawLine(const Offset(86.25, 46.875), const Offset(116.25, 61.875), glassFrame); // Yatay 1
    canvas.drawLine(const Offset(107.5, 36.25), const Offset(137.5, 51.25), glassFrame);    // Yatay 2
    canvas.drawLine(const Offset(128.75, 25.625), const Offset(158.75, 40.625), glassFrame); // Yatay 3

    // 8. 3 BOYUTLU HAVALANDIRMA ÜNİTELERİ (Cam tavanın bitişinde)
    // Ünite 1 
    canvas.drawPath(Path()..moveTo(160, 20)..lineTo(170, 25)..lineTo(170, 15)..lineTo(160, 10)..close(), Paint()..color = const Color(0xFF78909C)); 
    canvas.drawPath(Path()..moveTo(170, 25)..lineTo(180, 20)..lineTo(180, 10)..lineTo(170, 15)..close(), Paint()..color = const Color(0xFF607D8B)); 
    canvas.drawPath(Path()..moveTo(160, 10)..lineTo(170, 15)..lineTo(180, 10)..lineTo(170, 5)..close(), Paint()..color = const Color(0xFF90A4AE)); 
    canvas.drawOval(Rect.fromCenter(center: const Offset(170, 10), width: 12, height: 6), Paint()..color = const Color(0xFF212121)); 

    // Ünite 2 
    canvas.drawPath(Path()..moveTo(180, 10)..lineTo(190, 15)..lineTo(190, 5)..lineTo(180, 0)..close(), Paint()..color = const Color(0xFF78909C));
    canvas.drawPath(Path()..moveTo(190, 15)..lineTo(200, 10)..lineTo(200, 0)..lineTo(190, 5)..close(), Paint()..color = const Color(0xFF607D8B));
    canvas.drawPath(Path()..moveTo(180, 0)..lineTo(190, 5)..lineTo(200, 0)..lineTo(190, -5)..close(), Paint()..color = const Color(0xFF90A4AE));
    canvas.drawOval(Rect.fromCenter(center: const Offset(190, 0), width: 12, height: 6), Paint()..color = const Color(0xFF212121)); 

    // 9. BACA VE DUMANLAR
    canvas.drawPath(Path()..moveTo(240, 57.5)..lineTo(225, 50)..lineTo(225, -50)..lineTo(240, -42.5)..close(), Paint()..color = const Color(0xFFECEFF1));
    canvas.drawPath(Path()..moveTo(240, 57.5)..lineTo(255, 50)..lineTo(255, -50)..lineTo(240, -42.5)..close(), Paint()..color = const Color(0xFFB0BEC5));
    canvas.drawPath(Path()..moveTo(240, 27.5)..lineTo(225, 20)..lineTo(225, 0)..lineTo(240, 7.5)..close(), Paint()..color = const Color(0xFFD32F2F));
    canvas.drawPath(Path()..moveTo(240, 27.5)..lineTo(255, 20)..lineTo(255, 0)..lineTo(240, 7.5)..close(), Paint()..color = const Color(0xFFB71C1C));
    canvas.drawPath(Path()..moveTo(240, -12.5)..lineTo(225, -20)..lineTo(225, -40)..lineTo(240, -32.5)..close(), Paint()..color = const Color(0xFFD32F2F));
    canvas.drawPath(Path()..moveTo(240, -12.5)..lineTo(255, -20)..lineTo(255, -40)..lineTo(240, -32.5)..close(), Paint()..color = const Color(0xFFB71C1C));
    canvas.drawPath(Path()..moveTo(240, -42.5)..lineTo(255, -50)..lineTo(240, -57.5)..lineTo(225, -50)..close(), Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(const Offset(250, -53), 3, Paint()..color = Colors.red.withValues(alpha: (math.sin(_timer * 8) > 0) ? 1.0 : 0.2));

    for (var p in _particles) {
      canvas.drawCircle(Offset(p.position.x, p.position.y), p.radius, Paint()..color = Colors.white.withValues(alpha: (p.life / p.maxLife) * 0.7)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }
}

// --- 4. YENİ BİNA: ALT VE ÜST SINIRI EŞİTLENMİŞ ÇATILAR VE SIFIR HATA ---
class ShipyardPortBuilding extends PositionComponent {
  double _timer = 0;

  ShipyardPortBuilding() {
    size = Vector2(360, 220); 
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(1.45, 1.45); 

    // ==========================================
    // 1. GÖLGE 
    // ==========================================
    Path shadowPath = Path()..moveTo(80, 110)..lineTo(210, 140)..lineTo(240, 100)..lineTo(120, 40)..lineTo(40, 80)..close();
    canvas.save();
    canvas.translate(-45, -15);
    canvas.drawPath(shadowPath, Paint()..color = Colors.black.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.restore();

    // ==========================================
    // 2. ÇAPA VE ZİNCİR
    // ==========================================
    final ironPaint = Paint()..color = const Color(0xFF1C262B)..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawOval(Rect.fromCenter(center: const Offset(30, 120), width: 7, height: 9), Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = const Color(0xFF1C262B));
    canvas.drawLine(const Offset(30, 124), const Offset(30, 145), ironPaint);
    canvas.drawLine(const Offset(22, 132), const Offset(38, 132), ironPaint);
    canvas.drawPath(Path()..moveTo(20, 140)..quadraticBezierTo(30, 150, 30, 145)..moveTo(40, 140)..quadraticBezierTo(30, 150, 30, 145), Paint()..color = const Color(0xFF1C262B)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final chainPaint = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for(int i=0; i<5; i++) canvas.drawOval(Rect.fromCenter(center: Offset(32 + (i*2), 125 + (i*3.5)), width: 3, height: 5), chainPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(30, 146), width: 22, height: 9), Paint()..color = const Color(0xFFD7CCC8)); 
    canvas.drawOval(Rect.fromCenter(center: const Offset(30, 148), width: 16, height: 6), Paint()..color = const Color(0xFFBCAAA4));

    // ==========================================
    // 3. SU DALGALARI VE AYAKLAR
    // ==========================================
    double maxRadius = 14.0;
    double r1 = (_timer * 12) % maxRadius; 
    double a1 = (1.0 - (r1 / maxRadius)).clamp(0.0, 1.0); 
    final ripplePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: a1 * 0.7);
    canvas.drawOval(Rect.fromCenter(center: const Offset(190, 148), width: r1 * 2, height: r1), ripplePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(210, 138), width: r1 * 2, height: r1), ripplePaint);

    void draw3DPillar(double cx, double cy, double h) {
      canvas.drawRect(Rect.fromLTWH(cx - 3, cy, 3, h), Paint()..color = const Color(0xFF4E342E)); 
      canvas.drawRect(Rect.fromLTWH(cx, cy, 3, h), Paint()..color = const Color(0xFF261A17)); 
      canvas.drawRect(Rect.fromLTWH(cx - 3, cy + h - 10, 3, 10), Paint()..color = const Color(0xFF558B2F)); 
      canvas.drawRect(Rect.fromLTWH(cx, cy + h - 10, 3, 10), Paint()..color = const Color(0xFF2E7D32)); 
    }
    draw3DPillar(190, 135, 25); draw3DPillar(210, 125, 25); draw3DPillar(150, 115, 25); draw3DPillar(170, 105, 20); 

    // ==========================================
    // 4. İNCE AHŞAP AVLU VE LİMAN DETAYLARI
    // ==========================================
    final woodPaint = Paint()..color = const Color(0xFF5D4037);
    final woodSideLeft = Paint()..color = const Color(0xFF4E342E); 
    final woodSideRight = Paint()..color = const Color(0xFF261A17); 
    
    double depth = 4.0; 
    
    canvas.drawPath(Path()..moveTo(150, 115)..lineTo(190, 135)..lineTo(190, 135 + depth)..lineTo(150, 115 + depth)..close(), woodSideLeft);
    canvas.drawPath(Path()..moveTo(190, 135)..lineTo(210, 125)..lineTo(210, 125 + depth)..lineTo(190, 135 + depth)..close(), woodSideRight);
    canvas.drawPath(Path()..moveTo(110, 115)..lineTo(130, 125)..lineTo(130, 125 + depth)..lineTo(110, 115 + depth)..close(), woodSideLeft);
    canvas.drawPath(Path()..moveTo(130, 125)..lineTo(150, 115)..lineTo(150, 115 + depth)..lineTo(130, 125 + depth)..close(), woodSideRight);

    Path deck = Path()..moveTo(110, 115)..lineTo(130, 125)..lineTo(170, 105)..lineTo(200, 120)..lineTo(240, 100)..lineTo(220, 90)..lineTo(180, 110)..lineTo(150, 95)..close();
    Path pier = Path()..moveTo(150, 115)..lineTo(170, 105)..lineTo(210, 125)..lineTo(190, 135)..close();
    canvas.drawPath(deck, woodPaint); canvas.drawPath(pier, woodPaint);
    canvas.drawPath(pier, Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0xFF8D6E63));
    canvas.drawPath(deck, Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0xFF8D6E63));

    void drawTireStack(double x, double y) {
      for (int i = 0; i < 3; i++) {
        double ty = y - (i * 2.5);
        canvas.drawOval(Rect.fromCenter(center: Offset(x, ty), width: 8, height: 4), Paint()..color = const Color(0xFF111111));
        canvas.drawOval(Rect.fromCenter(center: Offset(x, ty), width: 4, height: 2), Paint()..color = const Color(0xFF333333));
      }
    }
    drawTireStack(188, 133); 
    drawTireStack(208, 124); 

    void drawBarrel(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x - 3, y - 5, 6, 6), Paint()..color = const Color(0xFF1565C0)); 
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 1), width: 6, height: 3), Paint()..color = const Color(0xFF0D47A1)); 
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 5), width: 6, height: 3), Paint()..color = const Color(0xFF1976D2)); 
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 5), width: 4, height: 2), Paint()..color = const Color(0xFF111111)); 
    }
    drawBarrel(135, 114);
    drawBarrel(142, 112);
    drawBarrel(138, 116);

    // ==========================================
    // 5. BÜYÜK HANGAR (DUVAR VE ÇATI KÜÇÜK HANGAR İLE BİREBİR EŞİTLENDİ)
    // ==========================================
    // Duvar yükseklikleri tam 35 birime sabitlendi (Alt sınırlar hizalandı)
    canvas.drawPath(Path()..moveTo(80, 25)..lineTo(180, 75)..lineTo(180, 110)..lineTo(80, 60)..close(), Paint()..color = const Color(0xFFFAFAFA)); 
    canvas.drawPath(Path()..moveTo(120, 5)..lineTo(220, 55)..lineTo(220, 90)..lineTo(120, 40)..close(), Paint()..color = const Color(0xFFB0BEC5)); 
    canvas.drawPath(Path()..moveTo(180, 110)..lineTo(220, 90)..lineTo(220, 55)..lineTo(180, 75)..close(), Paint()..color = const Color(0xFFCFD8DC)); 
    
    final blueStripe = Paint()..color = const Color(0xFF1565C0);
    canvas.drawPath(Path()..moveTo(80, 40)..lineTo(180, 90)..lineTo(180, 85)..lineTo(80, 35)..close(), blueStripe); 
    canvas.drawPath(Path()..moveTo(180, 90)..lineTo(220, 70)..lineTo(220, 65)..lineTo(180, 85)..close(), blueStripe); 
    
    // Çatı Tepe Noktası (-25 birim) Küçük Hangar ile aynı eğime getirildi
    canvas.drawPath(Path()..moveTo(180, 75)..lineTo(220, 55)..lineTo(200, 40)..close(), Paint()..color = const Color(0xFF546E7A)); 
    canvas.drawPath(Path()..moveTo(80, 25)..lineTo(180, 75)..lineTo(200, 40)..lineTo(100, -10)..close(), Paint()..color = const Color(0xFF90A4AE)); 
    canvas.drawPath(Path()..moveTo(120, 5)..lineTo(220, 55)..lineTo(200, 40)..lineTo(100, -10)..close(), Paint()..color = const Color(0xFF78909C)); 

    // Havalandırma tam olarak sırt (ridge) çizgisine oturtuldu (Havada uçmaz)
    Path ventTop = Path()..moveTo(156, 8)..lineTo(146, 13)..lineTo(156, 18)..lineTo(166, 13)..close();
    Path ventLeft = Path()..moveTo(146, 13)..lineTo(156, 18)..lineTo(156, 28)..lineTo(146, 23)..close();
    Path ventRight = Path()..moveTo(156, 18)..lineTo(166, 13)..lineTo(166, 23)..lineTo(156, 28)..close();
    canvas.drawPath(ventLeft, Paint()..color = const Color(0xFF78909C));
    canvas.drawPath(ventRight, Paint()..color = const Color(0xFF546E7A));
    canvas.drawPath(ventTop, Paint()..color = const Color(0xFF90A4AE));
    
    double beaconAlpha = (math.sin(_timer * 5) + 1) / 2;
    canvas.drawOval(Rect.fromLTWH(153, 11, 6, 4), Paint()..color = const Color(0xFF111111)); // Fan
    canvas.drawCircle(const Offset(156, 8), 2.5, Paint()..color = Colors.red.withValues(alpha: beaconAlpha));
    canvas.drawCircle(const Offset(156, 8), 1, Paint()..color = Colors.white.withValues(alpha: beaconAlpha));

    // BÜYÜK HANGAR İÇİ: TEKNE BURNU
    Path mainDoor = Path()..moveTo(185, 107.5)..lineTo(205, 97.5)..lineTo(205, 72.5)..lineTo(185, 82.5)..close();
    canvas.drawPath(mainDoor, Paint()..color = const Color(0xFF070707)); 
    canvas.save(); canvas.clipPath(mainDoor);
    canvas.drawPath(Path()..moveTo(195, 102)..lineTo(186, 95)..lineTo(186, 85)..lineTo(195, 92)..close(), Paint()..color = const Color(0xFF8E0000)); 
    canvas.drawPath(Path()..moveTo(195, 102)..lineTo(204, 97)..lineTo(204, 87)..lineTo(195, 92)..close(), Paint()..color = const Color(0xFFD32F2F)); 
    canvas.drawPath(Path()..moveTo(195, 92)..lineTo(186, 85)..lineTo(186, 82)..lineTo(195, 89)..close(), Paint()..color = const Color(0xFFB0BEC5)); 
    canvas.drawPath(Path()..moveTo(195, 92)..lineTo(204, 87)..lineTo(204, 84)..lineTo(195, 89)..close(), Paint()..color = const Color(0xFFFAFAFA)); 
    canvas.drawPath(Path()..moveTo(195, 89)..lineTo(186, 82)..lineTo(195, 75)..lineTo(204, 84)..close(), Paint()..color = const Color(0xFF5D4037));
    canvas.drawPath(Path()..moveTo(195, 84)..lineTo(191, 81)..lineTo(191, 76)..lineTo(195, 79)..close(), Paint()..color = const Color(0xFF263238));
    canvas.drawPath(Path()..moveTo(195, 84)..lineTo(200, 80)..lineTo(200, 75)..lineTo(195, 79)..close(), Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(const Offset(195, 87), 1, Paint()..color = const Color(0xFFB0BEC5));
    canvas.restore(); 

    canvas.drawOval(Rect.fromCenter(center: const Offset(212, 85), width: 6, height: 8), Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0xFFE64A19));
    canvas.drawOval(Rect.fromCenter(center: const Offset(212, 85), width: 6, height: 8), Paint()..style=PaintingStyle.stroke..strokeWidth=0.5..color=Colors.white);

    // ==========================================
    // 6. KÜÇÜK HANGAR
    // ==========================================
    canvas.drawPath(Path()..moveTo(40, 45)..lineTo(110, 80)..lineTo(110, 115)..lineTo(40, 80)..close(), Paint()..color = const Color(0xFFFAFAFA));
    canvas.drawPath(Path()..moveTo(80, 25)..lineTo(150, 60)..lineTo(150, 95)..lineTo(80, 60)..close(), Paint()..color = const Color(0xFFB0BEC5));
    canvas.drawPath(Path()..moveTo(110, 115)..lineTo(150, 95)..lineTo(150, 60)..lineTo(110, 80)..close(), Paint()..color = const Color(0xFFCFD8DC));
    
    canvas.drawPath(Path()..moveTo(40, 65)..lineTo(110, 100)..lineTo(110, 95)..lineTo(40, 60)..close(), blueStripe);
    canvas.drawPath(Path()..moveTo(110, 100)..lineTo(150, 80)..lineTo(150, 75)..lineTo(110, 95)..close(), blueStripe);

    canvas.drawPath(Path()..moveTo(110, 80)..lineTo(150, 60)..lineTo(130, 45)..close(), Paint()..color = const Color(0xFF546E7A)); 
    canvas.drawPath(Path()..moveTo(40, 45)..lineTo(110, 80)..lineTo(130, 45)..lineTo(60, 10)..close(), Paint()..color = const Color(0xFF90A4AE)); 
    canvas.drawPath(Path()..moveTo(80, 25)..lineTo(150, 60)..lineTo(130, 45)..lineTo(60, 10)..close(), Paint()..color = const Color(0xFF78909C)); 

    Path sVentTop = Path()..moveTo(96, 18)..lineTo(84, 24)..lineTo(96, 30)..lineTo(108, 24)..close();
    Path sVentLeft = Path()..moveTo(84, 24)..lineTo(96, 30)..lineTo(96, 40)..lineTo(84, 34)..close();
    Path sVentRight = Path()..moveTo(96, 30)..lineTo(108, 24)..lineTo(108, 34)..lineTo(96, 40)..close();
    canvas.drawPath(sVentLeft, Paint()..color = const Color(0xFF78909C));
    canvas.drawPath(sVentRight, Paint()..color = const Color(0xFF546E7A));
    canvas.drawPath(sVentTop, Paint()..color = const Color(0xFF90A4AE));

    canvas.drawPath(Path()..moveTo(120, 110)..lineTo(140, 100)..lineTo(140, 80)..lineTo(120, 90)..close(), Paint()..color = const Color(0xFF546E7A));
    for (int i = 1; i <= 4; i++) {
      canvas.drawLine(Offset(120, 110 - (i * 4)), Offset(140, 100 - (i * 4)), Paint()..color = const Color(0xFF37474F)..strokeWidth = 0.5);
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(115, 95), width: 5, height: 7), Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0xFFE64A19));
    canvas.drawOval(Rect.fromCenter(center: const Offset(115, 95), width: 5, height: 7), Paint()..style=PaintingStyle.stroke..strokeWidth=0.5..color=Colors.white);

    // ==========================================
    // 7. ROTA VE KÖPÜK SİSTEMİ
    // ==========================================
    int cycleIndex = (_timer / 120).floor(); 
    double cycleTime = _timer % 120;
    math.Random rnd = math.Random(cycleIndex); 
    int shipType = rnd.nextInt(3); 
    
    bool runsTopRightToBottomLeft = (cycleIndex % 2 == 0); 

    final shipColors = [const Color(0xFFB71C1C), const Color(0xFF1565C0), const Color(0xFF546E7A), const Color(0xFFE65100)];
    Color hullColor = shipColors[cycleIndex % shipColors.length];

    if (cycleTime <= 100) {
      Vector2 startPos, endPos, dockPos;
      
      if (runsTopRightToBottomLeft) {
        startPos = Vector2(890, -115);
        endPos = Vector2(-310, 485);
        dockPos = Vector2(255, 170); 
      } else {
        startPos = Vector2(-350, 280);
        endPos = Vector2(890, 280);
        dockPos = Vector2(235, 205); 
      }

      double px = 0, py = 0;
      bool isMoving = false;

      if (cycleTime < 40) { 
        isMoving = true;
        double p = cycleTime / 40;
        double ease = 1.0 - (1.0 - p) * (1.0 - p); 
        px = startPos.x + (dockPos.x - startPos.x) * ease;
        py = startPos.y + (dockPos.y - startPos.y) * ease;
      } else if (cycleTime < 60) { 
        px = dockPos.x;
        py = dockPos.y;
      } else { 
        isMoving = true;
        double p = (cycleTime - 60) / 40;
        double ease = p * p; 
        px = dockPos.x + (endPos.x - dockPos.x) * ease;
        py = dockPos.y + (endPos.y - dockPos.y) * ease;
      }

      py += math.sin(_timer * 1.5) * 2.5; 
      
      if (isMoving) {
        for (int i = 0; i < 10; i++) {
          double foamAge = (_timer * 40 - (i * 6)) % 40; 
          if (foamAge < 0) foamAge += 40;
          double foamEase = foamAge / 40;
          double foamR = 2 + (foamEase * 12); 
          double foamA = (1.0 - foamEase).clamp(0.0, 1.0); 

          final foamPaint = Paint()..color = Colors.white.withValues(alpha: foamA * 0.5);
          
          double wakeX = runsTopRightToBottomLeft ? foamAge * 2.0 : -foamAge * 2.0;
          double wakeY = -foamAge * 1.0; 
          double sternX = runsTopRightToBottomLeft ? 40 : -40; 
          double sternY = -20;

          canvas.drawOval(Rect.fromCenter(center: Offset(px + sternX + wakeX, py + sternY + wakeY), width: foamR * 2, height: foamR), foamPaint);
        }
      }

      canvas.save();
      canvas.translate(px, py);
      
      if (!runsTopRightToBottomLeft) {
        canvas.scale(-1.0, 1.0); 
      }

      canvas.rotate(math.cos(_timer * 1.0) * 0.015); 
      canvas.scale(0.35, 0.35); 
      _drawRealisticShip(canvas, shipType, hullColor);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawRealisticShip(Canvas canvas, int type, Color hullColor) {
    Offset proj(double x, double y, double z) => Offset(-2 * x + 2 * y, x + y - z);

    void drawBox(double x, double y, double z, double l, double w, double h, Color c) {
      Path topFace = Path()..moveTo(proj(x, y, z+h).dx, proj(x, y, z+h).dy)..lineTo(proj(x+l, y, z+h).dx, proj(x+l, y, z+h).dy)..lineTo(proj(x+l, y+w, z+h).dx, proj(x+l, y+w, z+h).dy)..lineTo(proj(x, y+w, z+h).dx, proj(x, y+w, z+h).dy)..close();
      Path leftFace = Path()..moveTo(proj(x+l, y, z).dx, proj(x+l, y, z).dy)..lineTo(proj(x+l, y+w, z).dx, proj(x+l, y+w, z).dy)..lineTo(proj(x+l, y+w, z+h).dx, proj(x+l, y+w, z+h).dy)..lineTo(proj(x+l, y, z+h).dx, proj(x+l, y, z+h).dy)..close();
      Path rightFace = Path()..moveTo(proj(x, y+w, z).dx, proj(x, y+w, z).dy)..lineTo(proj(x+l, y+w, z).dx, proj(x+l, y+w, z).dy)..lineTo(proj(x+l, y+w, z+h).dx, proj(x+l, y+w, z+h).dy)..lineTo(proj(x, y+w, z+h).dx, proj(x, y+w, z+h).dy)..close();

      int r = c.red, g = c.green, b = c.blue;
      Color cLeft = Color.fromARGB(255, (r*0.6).toInt(), (g*0.6).toInt(), (b*0.6).toInt());
      Color cRight = Color.fromARGB(255, (r*0.8).toInt(), (g*0.8).toInt(), (b*0.8).toInt());

      canvas.drawPath(topFace, Paint()..color = c..style = PaintingStyle.fill); canvas.drawPath(topFace, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 0.5);
      canvas.drawPath(leftFace, Paint()..color = cLeft..style = PaintingStyle.fill); canvas.drawPath(leftFace, Paint()..color = cLeft..style = PaintingStyle.stroke..strokeWidth = 0.5);
      canvas.drawPath(rightFace, Paint()..color = cRight..style = PaintingStyle.fill); canvas.drawPath(rightFace, Paint()..color = cRight..style = PaintingStyle.stroke..strokeWidth = 0.5);
      
      final outlinePaint = Paint()..style=PaintingStyle.stroke..strokeWidth=0.8..color=Colors.black38;
      canvas.drawPath(topFace, outlinePaint); canvas.drawPath(leftFace, outlinePaint); canvas.drawPath(rightFace, outlinePaint);
    }

    void drawHull(double x, double y, double z, double l, double w, double h, double bowL, Color c) {
      Path backFace = Path()..moveTo(proj(x, y, z).dx, proj(x, y, z).dy)..lineTo(proj(x, y+w, z).dx, proj(x, y+w, z).dy)..lineTo(proj(x, y+w, z+h).dx, proj(x, y+w, z+h).dy)..lineTo(proj(x, y, z+h).dx, proj(x, y, z+h).dy)..close();
      Path leftHull = Path()..moveTo(proj(x+l, y, z).dx, proj(x+l, y, z).dy)..lineTo(proj(x, y, z).dx, proj(x, y, z).dy)..lineTo(proj(x, y, z+h).dx, proj(x, y, z+h).dy)..lineTo(proj(x+l, y, z+h).dx, proj(x+l, y, z+h).dy)..close();
      Path rightHull = Path()..moveTo(proj(x, y+w, z).dx, proj(x, y+w, z).dy)..lineTo(proj(x+l, y+w, z).dx, proj(x+l, y+w, z).dy)..lineTo(proj(x+l, y+w, z+h).dx, proj(x+l, y+w, z+h).dy)..lineTo(proj(x, y+w, z+h).dx, proj(x, y+w, z+h).dy)..close();
      
      Offset bowTipBottom = proj(x+l+bowL, y+w/2, z), bowTipTop = proj(x+l+bowL, y+w/2, z+h);
      Offset startLeftBottom = proj(x+l, y, z), startLeftTop = proj(x+l, y, z+h);
      Offset startRightBottom = proj(x+l, y+w, z), startRightTop = proj(x+l, y+w, z+h);

      Path leftSoftBow = Path()..moveTo(startLeftBottom.dx, startLeftBottom.dy)..cubicTo(proj(x+l+bowL*0.5, y, z).dx, proj(x+l+bowL*0.5, y, z).dy, proj(x+l+bowL*0.8, y+w*0.1, z).dx, proj(x+l+bowL*0.8, y+w*0.1, z).dy, bowTipBottom.dx, bowTipBottom.dy)..lineTo(bowTipTop.dx, bowTipTop.dy)..cubicTo(proj(x+l+bowL*0.8, y+w*0.1, z+h).dx, proj(x+l+bowL*0.8, y+w*0.1, z+h).dy, proj(x+l+bowL*0.5, y, z+h).dx, proj(x+l+bowL*0.5, y, z+h).dy, startLeftTop.dx, startLeftTop.dy)..close();
      Path rightSoftBow = Path()..moveTo(startRightBottom.dx, startRightBottom.dy)..cubicTo(proj(x+l+bowL*0.5, y+w, z).dx, proj(x+l+bowL*0.5, y+w, z).dy, proj(x+l+bowL*0.8, y+w*0.9, z).dx, proj(x+l+bowL*0.9, y+w*0.9, z).dy, bowTipBottom.dx, bowTipBottom.dy)..lineTo(bowTipTop.dx, bowTipTop.dy)..cubicTo(proj(x+l+bowL*0.8, y+w*0.9, z+h).dx, proj(x+l+bowL*0.8, y+w*0.9, z+h).dy, proj(x+l+bowL*0.5, y+w, z+h).dx, proj(x+l+bowL*0.5, y+w, z+h).dy, startRightTop.dx, startRightTop.dy)..close();
      Path topDeck = Path()..moveTo(proj(x, y, z+h).dx, proj(x, y, z+h).dy)..lineTo(proj(x+l, y, z+h).dx, proj(x+l, y, z+h).dy)..cubicTo(proj(x+l+bowL*0.5, y, z+h).dx, proj(x+l+bowL*0.5, y, z+h).dy, proj(x+l+bowL*1.0, y+w*0.3, z+h).dx, proj(x+l+bowL*1.0, y+w*0.3, z+h).dy, bowTipTop.dx, bowTipTop.dy)..cubicTo(proj(x+l+bowL*1.0, y+w*0.7, z+h).dx, proj(x+l+bowL*1.0, y+w*0.7, z+h).dy, proj(x+l+bowL*0.5, y+w, z+h).dx, proj(x+l+bowL*0.5, y+w, z+h).dy, proj(x+l, y+w, z+h).dx, proj(x+l, y+w, z+h).dy)..lineTo(proj(x, y+w, z+h).dx, proj(x, y+w, z+h).dy)..close();

      int r = c.red, g = c.green, b = c.blue;
      Color cBack = Color.fromARGB(255, (r*0.5).toInt(), (g*0.5).toInt(), (b*0.5).toInt());
      Color cLeft = Color.fromARGB(255, (r*0.6).toInt(), (g*0.6).toInt(), (b*0.6).toInt());
      Color cRight = Color.fromARGB(255, (r*0.8).toInt(), (g*0.8).toInt(), (b*0.8).toInt());

      canvas.drawPath(backFace, Paint()..color = cBack..style = PaintingStyle.fill); canvas.drawPath(backFace, Paint()..color = cBack..style = PaintingStyle.stroke..strokeWidth = 0.5);
      canvas.drawPath(leftHull, Paint()..color = cLeft..style = PaintingStyle.fill); canvas.drawPath(leftHull, Paint()..color = cLeft..style = PaintingStyle.stroke..strokeWidth = 0.5);
      canvas.drawPath(rightHull, Paint()..color = cRight..style = PaintingStyle.fill); canvas.drawPath(rightHull, Paint()..color = cRight..style = PaintingStyle.stroke..strokeWidth = 0.5);
      canvas.drawPath(leftSoftBow, Paint()..color = cLeft..style = PaintingStyle.fill); canvas.drawPath(leftSoftBow, Paint()..color = cLeft..style = PaintingStyle.stroke..strokeWidth = 0.5);
      canvas.drawPath(rightSoftBow, Paint()..color = Color.fromARGB(255, (r*0.9).toInt(), (g*0.9).toInt(), (b*0.9).toInt())..style = PaintingStyle.fill); canvas.drawPath(rightSoftBow, Paint()..color = Color.fromARGB(255, (r*0.9).toInt(), (g*0.9).toInt(), (b*0.9).toInt())..style = PaintingStyle.stroke..strokeWidth = 0.5);
      canvas.drawPath(topDeck, Paint()..color = c..style = PaintingStyle.fill); canvas.drawPath(topDeck, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 0.5);
      
      canvas.drawPath(topDeck, Paint()..style=PaintingStyle.stroke..strokeWidth=0.5..color=Colors.black54);
    }

    if (type == 0) { // DEV KONTEYNER GEMİSİ
      drawHull(-70, -16, -5, 120, 32, 24, 45, hullColor); 
      drawBox(-66, -14, 8, 112, 28, 2, const Color(0xFF546E7A)); 
      
      drawBox(-62, -12, 10, 20, 24, 16, const Color(0xFFECEFF1));
      drawBox(-60, -12.1, 14, 10, 24.2, 8, Colors.lightBlue[300]!); 
      drawBox(-58, -14, 26, 14, 28, 14, const Color(0xFFFAFAFA));
      drawBox(-56, -14.1, 30, 8, 28.2, 6, Colors.lightBlue[200]!); 
      
      drawBox(-60, -15, 40, 18, 30, 2, const Color(0xFF90A4AE));
      drawBox(-54, -2, 42, 3, 3, 10, Colors.orange); 
      
      drawBox(-53, -6, 48, 4, 4, 10, const Color(0xFF111111)); 
      for(int i=0; i<6; i++) {
        double smokeAge = (_timer * 15 - (i * 15)) % 90; 
        if (smokeAge < 0) smokeAge += 90;
        double smokeEase = smokeAge / 90;
        double smokeR = 3.0 + (smokeEase * 8.0); 
        double smokeA = (1.0 - smokeEase).clamp(0.0, 1.0); 
        
        final smokePaint = Paint()..color = Colors.white.withValues(alpha: smokeA * 0.6);
        canvas.drawCircle(proj(-51, -4, 58 + smokeAge*0.8), smokeR, smokePaint); 
      }
      
      final cColors = [const Color(0xFF1565C0), const Color(0xFF2E7D32), const Color(0xFFE65100), const Color(0xFF6A1B9A)];
      void drawCont(double cx, double cy, double cz, Color cc) => drawBox(cx, cy, cz, 24, 10, 10, cc); 
      
      drawCont(-38, -12, 10, cColors[0]); drawCont(-38, 2, 10, cColors[1]); drawCont(-38, -5, 20, cColors[2]); 
      drawCont(-10, -12, 10, cColors[3]); drawCont(-10, 2, 10, cColors[0]);
      drawCont(18, -12, 10, cColors[1]); drawCont(18, 2, 10, cColors[2]);
      drawCont(18, -12, 20, cColors[3]); drawCont(18, 2, 20, cColors[0]);
    } 
    else if (type == 1) { // KARGO/VİNÇ GEMİSİ
      drawHull(-40, -11, 0, 75, 22, 14, 35, const Color(0xFF2E7D32)); 
      drawBox(-35, -10, 14, 70, 20, 2, const Color(0xFF78909C)); 
      drawBox(-35, -8, 16, 15, 16, 18, const Color(0xFFECEFF1)); 
      drawBox(-25, -7, 26, 5, 14, 4, Colors.lightBlueAccent); 
      drawBox(-10, -5, 16, 15, 10, 3, const Color(0xFF455A64));
      drawBox(15, -5, 16, 15, 10, 3, const Color(0xFF455A64));
      drawBox(8, 0, 16, 4, 4, 25, Colors.orange); 
      drawBox(8, -5, 41, 25, 2, 2, Colors.orange); 
    }
    else { // RÖMORKÖR
      drawHull(-20, -9, 0, 30, 18, 12, 20, const Color(0xFF1565C0));
      drawBox(-15, -8, 12, 28, 16, 2, const Color(0xFFFBC02D));
      drawBox(-5, -6, 14, 16, 12, 14, Colors.white);
      drawBox(0, -7, 28, 18, 14, 2, Colors.white);
      drawBox(3, -5, 18, 5, 10, 8, Colors.lightBlueAccent); 
      drawBox(-2, -3, 30, 4, 4, 10, Colors.black87); 
    }
  }
}