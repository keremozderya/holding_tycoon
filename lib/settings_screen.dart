import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;
  String _selectedLanguage = 'TR';

  final List<Map<String, String>> _languages = const [
    {'code': 'TR', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'EN', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'DE', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ES', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'FR', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'IT', 'name': 'Italiano', 'flag': '🇮🇹'},
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
      _selectedLanguage = prefs.getString('language') ?? 'TR';
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

  Future<void> _saveLanguage(String langCode) async {
    setState(() => _selectedLanguage = langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ayarlar', style: AppTheme.titleStyle(fontSize: 20)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'SES AYARLARI',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          _buildVolumeCard(
            title: 'Müzik Sesi',
            value: _musicVolume,
            icon: Icons.music_note_rounded,
            onChanged: _saveMusicVolume,
          ),
          const SizedBox(height: 12),
          _buildVolumeCard(
            title: 'Efekt Sesleri',
            value: _sfxVolume,
            icon: Icons.volume_up_rounded,
            onChanged: _saveSfxVolume,
          ),
          const SizedBox(height: 30),
          const Text(
            'DİL SEÇİMİ',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final bool isSelected = _selectedLanguage == lang['code'];
                return ListTile(
                  leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    lang['name']!,
                    style: TextStyle(
                      color: isSelected ? AppColors.gold : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.gold)
                      : const Icon(Icons.circle_outlined, color: Colors.white24),
                  onTap: () => _saveLanguage(lang['code']!),
                );
              },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
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
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '%${(value * 100).round()}',
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withValues(alpha: 0.2),
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