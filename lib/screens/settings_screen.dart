// lib/screens/settings_screen.dart
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import '../widgets/adaptive_widgets.dart';
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

  Widget _fitSingleLine(
    String value, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
    AlignmentGeometry alignment = Alignment.centerLeft,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        value,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        textAlign: textAlign,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final currentLangMap = _getCurrentLangMap(gameState.language);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: SizedBox(
          width: MediaQuery.of(context).size.width * 0.58,
          child: _fitSingleLine(
            'settings.title'.tr(),
            alignment: Alignment.center,
            textAlign: TextAlign.center,
            style: AppTheme.titleStyle(fontSize: 22),
          ),
        ),
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
          Align(
            alignment: Alignment.centerLeft,
            child: _fitSingleLine(
              'settings.sound_settings'.tr().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildVolumeCard(title: 'settings.music_volume'.tr(), value: _musicVolume, icon: Icons.music_note_rounded, onChanged: _saveMusicVolume),
          const SizedBox(height: 16),
          _buildVolumeCard(title: 'settings.sfx_volume'.tr(), value: _sfxVolume, icon: Icons.volume_up_rounded, onChanged: _saveSfxVolume),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: _fitSingleLine(
              'settings.appearance'.tr().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildThemeCard(gameState),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: _fitSingleLine(
              'settings.language_options'.tr().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildAnimatedLanguageAccordion(currentLangMap),
        ],
      ),
    );
  }

  Widget _buildThemeCard(GameState gameState) {
    final dark = gameState.useDarkTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(dark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.neonCyan, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)),
                child: const Icon(Icons.palette_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _fitSingleLine(
                  'settings.interface_theme'.tr().toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('settings.theme_description'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, height: 1.35)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildThemeChoice(gameState: gameState, darkChoice: false)),
              const SizedBox(width: 12),
              Expanded(child: _buildThemeChoice(gameState: gameState, darkChoice: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChoice({required GameState gameState, required bool darkChoice}) {
    final selected = gameState.useDarkTheme == darkChoice;
    final previewColor = darkChoice ? AppColors.darkSurface : Colors.white;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (selected) return;
        HapticFeedback.selectionClick();
        AudioService.instance.playSfx('click.mp3');
        await context.read<GameState>().setDarkTheme(darkChoice);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.softSurfaceFor(gameState.useDarkTheme),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: selected ? const [BoxShadow(color: Colors.black26, offset: Offset(0, 3))] : null,
        ),
        child: Column(
          children: [
            Container(
              height: 34,
              decoration: BoxDecoration(color: previewColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
              child: Center(
                child: Container(width: 26, height: 8, decoration: BoxDecoration(color: AppColors.neonCyan, borderRadius: BorderRadius.circular(4))),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[const Icon(Icons.check_circle_rounded, size: 18, color: Colors.black), const SizedBox(width: 6)],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      (darkChoice ? 'settings.dark' : 'settings.light').tr().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLanguageAccordion(Map<String, String> currentLangMap) {
    final dark = context.watch<GameState>().useDarkTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(dark), 
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
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(12), color: AppColors.softSurfaceFor(dark)), child: Text(currentLangMap['flag']!, style: const TextStyle(fontSize: 32))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fitSingleLine(
                        'settings.game_language'.tr().toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _fitSingleLine(
                        currentLangMap['name']!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(width: 12),
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
                                    Expanded(
                                      child: _fitSingleLine(
                                        lang['name']!.toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.neonCyan
                                              : AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
    final dark = context.watch<GameState>().useDarkTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(dark), 
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
              Expanded(
                child: _fitSingleLine(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softSurfaceFor(dark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  '%${(value * 100).round()}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.neonCyan, inactiveTrackColor: AppColors.mutedSurfaceFor(dark), thumbColor: AppColors.gold, trackHeight: 12, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4)),
            child: Slider(value: value, min: 0.0, max: 1.0, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
