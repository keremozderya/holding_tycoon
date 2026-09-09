// lib/screens/office_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({super.key});

  String _formatNum(double value) {
    if (value >= 1e33) return '${(value / 1e33).toStringAsFixed(2)} Dc';
    if (value >= 1e30) return '${(value / 1e30).toStringAsFixed(2)} No';
    if (value >= 1e27) return '${(value / 1e27).toStringAsFixed(2)} Oc';
    if (value >= 1e24) return '${(value / 1e24).toStringAsFixed(2)} Sp';
    if (value >= 1e21) return '${(value / 1e21).toStringAsFixed(2)} Sx';
    if (value >= 1e18) return '${(value / 1e18).toStringAsFixed(2)} Qi';
    if (value >= 1e15) return '${(value / 1e15).toStringAsFixed(2)} Qa';
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)} T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)} B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)} M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)} K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final staffList = gameState.officeStaff;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('YAZIHANE', style: AppTheme.titleStyle(fontSize: 22).copyWith(color: Colors.orangeAccent)),
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.orangeAccent, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Icon(Icons.business_center_rounded, color: Colors.orangeAccent, size: 48),
                const SizedBox(height: 12),
                const Text('Holding Merkezi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Yönetim kadronuzu güçlendirin. İşe aldığınız her profesyonel holdinginize kalıcı ve devasa avantajlar sağlayacaktır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Text('KASA: \$${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'SpaceMono')),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: staffList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: staff.isHired ? Colors.orangeAccent : AppColors.surfaceElevated, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Icon(staff.isHired ? Icons.how_to_reg_rounded : Icons.person_add_alt_1_rounded, color: staff.isHired ? Colors.orangeAccent : AppColors.textSecondary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(staff.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(staff.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: staff.isHired ? AppColors.border : Colors.orangeAccent,
                        foregroundColor: staff.isHired ? Colors.white30 : AppColors.darkBrown,
                        elevation: staff.isHired ? 0 : 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: staff.isHired || gameState.money < staff.hireCost ? null : () {
                        gameState.hireStaff(staff.id);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.surface, content: Text('${staff.title} işe alındı!', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))));
                      },
                      child: Text(
                        staff.isHired ? 'KADRODA' : 'İŞE AL\n\$${_formatNum(staff.hireCost)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}