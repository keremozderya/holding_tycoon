// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;
  bool _isLanguageExpanded = false;

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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicVolume = prefs.getDouble('music_volume') ?? 0.8;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
    });
  }

  Future<void> _saveMusicVolume(double value) async {
    setState(() => _musicVolume = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', value);
  }

  Future<void> _saveSfxVolume(double value) async {
    setState(() => _sfxVolume = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', value);
  }

  Map<String, String> _getCurrentLangMap(String currentCode) {
    return _languages.firstWhere(
      (lang) => lang['code'] == currentCode.toLowerCase(),
      orElse: () => _languages.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final currentLangMap = _getCurrentLangMap(gameState.language);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('settings.title'.tr(), style: AppTheme.titleStyle(fontSize: 20)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text(
            'settings.sound_settings'.tr(),
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _buildVolumeCard(
            title: 'settings.music_volume'.tr(),
            value: _musicVolume,
            icon: Icons.music_note_rounded,
            onChanged: _saveMusicVolume,
          ),
          const SizedBox(height: 12),
          _buildVolumeCard(
            title: 'settings.sfx_volume'.tr(),
            value: _sfxVolume,
            icon: Icons.volume_up_rounded,
            onChanged: _saveSfxVolume,
          ),
          const SizedBox(height: 32),
          Text(
            'settings.language_options'.tr(),
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnimatedLanguageAccordion(currentLangMap),
        ],
      ),
    );
  }

  Widget _buildAnimatedLanguageAccordion(Map<String, String> currentLangMap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isLanguageExpanded
              ? AppColors.gold.withValues(alpha: 0.6)
              : AppColors.border,
          width: _isLanguageExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _isLanguageExpanded = !_isLanguageExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Text(currentLangMap['flag']!, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings.game_language'.tr(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currentLangMap['name']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedRotation(
                      turns: _isLanguageExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.gold,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isLanguageExpanded
                  ? Column(
                      children: [
                        const Divider(color: AppColors.border, height: 1),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _languages.length,
                          separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (context, index) {
                            final lang = _languages[index];
                            final currentLang = context.read<GameState>().language;
                            final bool isSelected = currentLang == lang['code'];

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  await context.read<GameState>().setLanguage(lang['code']!);
                                  setState(() {
                                    _isLanguageExpanded = false;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  child: Row(
                                    children: [
                                      Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 14),
                                      Text(
                                        lang['name']!,
                                        style: TextStyle(
                                          color: isSelected ? AppColors.gold : AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.gold,
                                          size: 20,
                                        )
                                      else
                                        const Icon(
                                          Icons.circle_outlined,
                                          color: AppColors.textMuted,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard({
    required String title,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '%${(value * 100).round()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}