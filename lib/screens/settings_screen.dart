// lib/screens/settings_screen.dart
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;
  bool _isLanguageExpanded = false;
  Timer? _musicSaveDebounce;
  Timer? _sfxSaveDebounce;

  final List<Map<String, String>> _languages = const [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
  ];

  @override
  void initState() { super.initState(); _loadSettings(); }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { _musicVolume = prefs.getDouble('music_volume') ?? 0.8; _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8; });
  }

  void _saveMusicVolume(double value) {
    setState(() => _musicVolume = value);
    AudioService.instance.setMusicVolume(value);
    _musicSaveDebounce?.cancel();
    _musicSaveDebounce = Timer(const Duration(milliseconds: 250), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('music_volume', value);
    });
  }

  void _saveSfxVolume(double value) {
    setState(() => _sfxVolume = value);
    AudioService.instance.setSfxVolume(value);
    _sfxSaveDebounce?.cancel();
    _sfxSaveDebounce = Timer(const Duration(milliseconds: 250), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sfx_volume', value);
      AudioService.instance.playSfx('click.mp3');
    });
  }

  @override
  void dispose() {
    _musicSaveDebounce?.cancel();
    _sfxSaveDebounce?.cancel();
    super.dispose();
  }

  Map<String, String> _getCurrentLangMap(String currentCode) {
    return _languages.firstWhere((lang) => lang['code'] == currentCode.toLowerCase(), orElse: () => _languages.first);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final currentLangMap = _getCurrentLangMap(gameState.language);

    return Scaffold(
      backgroundColor: AppColors.background, 
      appBar: AppBar(
        title: Text('settings.title'.tr(), style: AppTheme.titleStyle(fontSize: 22)),
        backgroundColor: Colors.transparent,
        centerTitle: true, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30, shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))]), 
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            Navigator.pop(context);
          }
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text('settings.sound_settings'.tr().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 16, shadows: [Shadow(color: Colors.black, offset: Offset(1,1))])),
          const SizedBox(height: 12),
          _buildVolumeCard(title: 'settings.music_volume'.tr(), value: _musicVolume, icon: Icons.music_note_rounded, onChanged: _saveMusicVolume),
          const SizedBox(height: 16),
          _buildVolumeCard(title: 'settings.sfx_volume'.tr(), value: _sfxVolume, icon: Icons.volume_up_rounded, onChanged: _saveSfxVolume),
          const SizedBox(height: 36),
          Text('settings.language_options'.tr().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 16, shadows: [Shadow(color: Colors.black, offset: Offset(1,1))])),
          const SizedBox(height: 12),
          _buildAnimatedLanguageAccordion(currentLangMap),
        ],
      ),
    );
  }

  Widget _buildAnimatedLanguageAccordion(Map<String, String> currentLangMap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () { 
              HapticFeedback.selectionClick();
              AudioService.instance.playSfx('click.mp3');
              setState(() { _isLanguageExpanded = !_isLanguageExpanded; }); 
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(12), color: const Color(0xFFF1F5F9)), child: Text(currentLangMap['flag']!, style: const TextStyle(fontSize: 32))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('settings.game_language'.tr().toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(currentLangMap['name']!.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ],
                  )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)),
                    child: AnimatedRotation(
                      turns: _isLanguageExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
              child: _isLanguageExpanded
                  ? Column(
                      children: [
                        const Divider(color: Colors.black, height: 1, thickness: 4),
                        ListView.separated(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _languages.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.black, height: 1, thickness: 2),
                          itemBuilder: (context, index) {
                            final lang = _languages[index];
                            final currentLang = context.read<GameState>().language;
                            final bool isSelected = currentLang == lang['code'];

                            return InkWell(
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                AudioService.instance.playSfx('click.mp3');
                                await context.read<GameState>().setLanguage(lang['code']!);
                                if (mounted) setState(() { _isLanguageExpanded = false; });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Row(
                                  children: [
                                    Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                                    const SizedBox(width: 16),
                                    Text(lang['name']!.toUpperCase(), style: TextStyle(color: isSelected ? AppColors.neonCyan : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                                    const Spacer(),
                                    if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.neonCyan, size: 28)
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard({required String title, required double value, required IconData icon, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)), child: Icon(icon, color: Colors.black, size: 28)),
              const SizedBox(width: 16),
              Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: Text('%${(value * 100).round()}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'SpaceMono'))),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.neonCyan, inactiveTrackColor: const Color(0xFFE2E8F0), thumbColor: AppColors.gold, trackHeight: 12, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4)),
            child: Slider(value: value, min: 0.0, max: 1.0, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
