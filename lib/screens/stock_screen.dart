// lib/screens/stock_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  String _formatBigNum(double value, {bool isMoney = false}) {
    if (value == 0) return isMoney ? '\$0' : '0';
    bool isNegative = value < 0;
    value = value.abs();
    
    String suffix = '';
    double formatted = value;

    if (value >= 1e18) { formatted = value / 1e18; suffix = 'Qi'; }
    else if (value >= 1e15) { formatted = value / 1e15; suffix = 'Qa'; }
    else if (value >= 1e12) { formatted = value / 1e12; suffix = 'T'; }
    else if (value >= 1e9) { formatted = value / 1e9; suffix = 'B'; }
    else if (value >= 1e6) { formatted = value / 1e6; suffix = 'M'; }
    else if (value >= 1e3) { formatted = value / 1e3; suffix = 'K'; }

    String result = formatted.toStringAsFixed(suffix.isEmpty ? 0 : 2);
    if (result.contains('.')) {
      result = result.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }

    String prefix = isNegative ? '-' : (isMoney && !isNegative && value > 0 && suffix.isNotEmpty ? '+' : '');
    String moneySymbol = isMoney ? '\$' : '';
    
    return '$prefix$moneySymbol$result$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final stocks = gameState.stocks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('stock.title'.tr(), style: AppTheme.titleStyle(fontSize: 18)),
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surfaceElevated, AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'stock.header_title'.tr(),
                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatBigNum(gameState.money, isMoney: true),
                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'stock.info_text'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
            itemCount: stocks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final stock = stocks[index];
              final bool isUp = stock.history.last >= stock.history[max(0, stock.history.length - 2)];
              final Color trendColor = isUp ? AppColors.profit : AppColors.loss;
              final Color pnlColor = stock.netPnl >= 0 ? AppColors.profit : AppColors.loss;

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: stock.iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: stock.iconColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(stock.icon, color: stock.iconColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stock.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(_formatBigNum(stock.currentPrice, isMoney: true), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 15)),
                                  const SizedBox(width: 4),
                                  Icon(isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: trendColor, size: 22),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'stock.owned_shares'.tr(params: {'amount': _formatBigNum(stock.ownedShares)}),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'stock.net_pnl'.tr(params: {'amount': _formatBigNum(stock.netPnl, isMoney: true)}),
                                style: TextStyle(color: pnlColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 80, 
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                      ),
                      child: CustomPaint(
                        painter: SparklinePainter(data: stock.history, lineColor: trendColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGameButton(
                            label: 'stock.buy_button'.tr(),
                            colors: const [Color(0xFF34D399), AppColors.profit],
                            isActive: gameState.money >= stock.currentPrice,
                            onTap: () => context.read<GameState>().buyStock(stock.id),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildGameButton(
                            label: 'stock.sell_button'.tr(),
                            colors: const [Color(0xFFFBBF24), AppColors.gold],
                            isActive: stock.ownedShares > 0,
                            onTap: () => context.read<GameState>().sellAllStock(stock.id),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton({required String label, required List<Color> colors, required bool isActive, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive ? colors : [AppColors.border, AppColors.surface], 
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: isActive ? [BoxShadow(color: colors.last.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  SparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0 
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal; 

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}