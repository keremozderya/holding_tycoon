// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final bool isInitialLaunch;

  const MainMenuScreen({super.key, this.isInitialLaunch = false});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final List<IconData> _defaultLogos = const [
    Icons.domain_rounded,
    Icons.account_balance_rounded,
    Icons.factory_rounded,
    Icons.rocket_launch_rounded,
    Icons.local_shipping_rounded,
    Icons.bolt_rounded,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isInitialLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewGameDialog();
      });
    }
  }

  void _showNewGameDialog() {
    final TextEditingController nameController = TextEditingController(text: 'MyHolding');
    int selectedLogoIndex = 0;

    showDialog(
      context: context,
      barrierDismissible: !widget.isInitialLaunch,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Holdingini Kur',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Şirket İsmi', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: 'MyHolding',
                        hintStyle: const TextStyle(color: Colors.black26),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Holding Logosu Seç', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(_defaultLogos.length, (index) {
                        final bool isSelected = selectedLogoIndex == index;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setDialogState(() => selectedLogoIndex = index),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              _defaultLogos[index],
                              color: isSelected ? AppColors.gold : AppColors.textSecondary,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final String holdingName = nameController.text.trim().isEmpty
                          ? 'MyHolding'
                          : nameController.text.trim();

                      await prefs.setString('holding_name', holdingName);
                      await prefs.setInt('holding_logo_index', selectedLogoIndex);
                      await prefs.setBool('is_first_time', false);

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                    },
                    child: const Text(
                      'BAŞLA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65), // Arka planın karanlık mod filtresi (yazıların okunabilirliği için)
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Görseli
              Image.asset(
                'assets/images/logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Görsel yüklenemezse yedek ikon gösterir
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: const Icon(Icons.domain_rounded, size: 76, color: AppColors.gold),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'HOLDING TYCOON',
                style: AppTheme.titleStyle(fontSize: 32).copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Küresel Bir İmparatorluk Kur!',
                style: AppTheme.subtitleStyle(fontSize: 14).copyWith(color: AppColors.goldMuted),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    if (!widget.isInitialLaunch) ...[
                      _buildMenuButton(
                        label: 'OYUNA DÖN',
                        icon: Icons.play_arrow_rounded,
                        isPrimary: true,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const MapScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    _buildMenuButton(
                      label: 'YENİ OYUN',
                      icon: Icons.fiber_new_rounded,
                      isPrimary: widget.isInitialLaunch,
                      onPressed: _showNewGameDialog,
                    ),
                    const SizedBox(height: 14),
                    _buildMenuButton(
                      label: 'AYARLAR',
                      icon: Icons.settings_rounded,
                      isPrimary: false,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text('v0.1.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.gold : AppColors.surface.withValues(alpha: 0.9),
          foregroundColor: isPrimary ? Colors.white : AppColors.textPrimary,
          elevation: isPrimary ? 6 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary ? BorderSide.none : const BorderSide(color: AppColors.border),
          ),
        ),
        icon: Icon(icon, color: isPrimary ? Colors.white : AppColors.gold),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isPrimary ? Colors.white : AppColors.textPrimary,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}