// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
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
    Icons.domain_rounded, Icons.account_balance_rounded, Icons.factory_rounded,
    Icons.rocket_launch_rounded, Icons.local_shipping_rounded, Icons.bolt_rounded,
  ];

  final List<Map<String, String>> _languages = const [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isInitialLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLanguageSelectionDialog();
      });
    }
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background, // Asfalt
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border, width: 3)),
          title: Text(
            'menu.select_language'.tr(),
            textAlign: TextAlign.center,
            style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.gold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 2),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                return ListTile(
                  tileColor: AppColors.surface, // Ahşap kart
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                  leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(lang['name']!, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.gold),
                  onTap: () async {
                    await context.read<GameState>().setLanguage(lang['code']!);
                    if (!context.mounted) return;
                    Navigator.pop(context); 
                    _showNewGameDialog();   
                  },
                );
              },
            ),
          ),
        );
      },
    );
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
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.border, width: 3)),
              title: Text('menu.setup_holding'.tr(), textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 24).copyWith(color: AppColors.gold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('menu.company_name'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true, fillColor: AppColors.surface, // Ahşap input
                        hintText: 'MyHolding', hintStyle: const TextStyle(color: AppColors.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('menu.choose_logo'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: List.generate(_defaultLogos.length, (index) {
                        final bool isSelected = selectedLogoIndex == index;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setDialogState(() => selectedLogoIndex = index),
                          child: Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.gold : AppColors.border, width: isSelected ? 3 : 2),
                            ),
                            child: Icon(_defaultLogos[index], color: isSelected ? AppColors.gold : AppColors.textMuted, size: 32),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.darkBrown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.darkBrown, width: 2)),
                      elevation: 6,
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final String holdingName = nameController.text.trim().isEmpty ? 'MyHolding' : nameController.text.trim();
                      await prefs.setString('holding_name', holdingName);
                      await prefs.setInt('holding_logo_index', selectedLogoIndex);
                      if (!context.mounted) return;
                      await context.read<GameState>().completeFirstLaunch();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MapScreen()));
                    },
                    child: Text('menu.start'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
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
    context.watch<GameState>();

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.oceanBlue, 
          image: DecorationImage(
            image: const AssetImage('assets/images/background.jpg'), 
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface, // Ahşap zemin
                  border: Border.all(color: AppColors.gold, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.domain_rounded, size: 84, color: AppColors.gold),
              ),
              const SizedBox(height: 24),
              Text('app_title'.tr(), style: AppTheme.titleStyle(fontSize: 40).copyWith(color: AppColors.gold, shadows: [const Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)])),
              const SizedBox(height: 8),
              Text('menu.subtitle'.tr(), style: AppTheme.subtitleStyle(fontSize: 16).copyWith(color: Colors.white, shadows: [const Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)])),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    if (!widget.isInitialLaunch) ...[
                      _buildMenuButton(label: 'menu.return_to_game'.tr(), icon: Icons.play_arrow_rounded, isPrimary: true, onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MapScreen())); }),
                      const SizedBox(height: 16),
                    ],
                    _buildMenuButton(label: 'menu.new_game'.tr(), icon: Icons.fiber_new_rounded, isPrimary: widget.isInitialLaunch, onPressed: _showNewGameDialog),
                    const SizedBox(height: 16),
                    _buildMenuButton(label: 'menu.settings'.tr(), icon: Icons.settings_rounded, isPrimary: false, onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())); }),
                  ],
                ),
              ),
              const Spacer(),
              const Text('v0.1.0', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({required String label, required IconData icon, required VoidCallback onPressed, bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity, height: 60, // Kalın, gösterişli Tycoon butonları
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.gold : AppColors.surface, // Altın veya Ahşap
          foregroundColor: isPrimary ? AppColors.darkBrown : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isPrimary ? AppColors.darkBrown : AppColors.border, width: 3),
          ),
        ),
        icon: Icon(icon, color: isPrimary ? AppColors.darkBrown : AppColors.gold, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        onPressed: onPressed,
      ),
    );
  }
}