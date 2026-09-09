// lib/screens/stock_screen.dart
import 'dart:math';
import 'dart:ui';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('stock.title'.tr(), style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.gold)),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF14141C), Color(0xFF0A0A10)], // Premium Koyu Arkaplan
          ),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, bottom: 40),
          children: [
            // ANA PORTFÖY KARTI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text('stock.header_title'.tr().toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        Text(_formatBigNum(gameState.money, isMoney: true), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0,2))])),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.gold.withValues(alpha: 0.3))),
                          child: Text('stock.info_text'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // HİSSE SENETLERİ LİSTESİ
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final stock = stocks[index];
                final bool isUp = stock.history.last >= stock.history[max(0, stock.history.length - 2)];
                final Color trendColor = isUp ? AppColors.profit : AppColors.loss;
                final Color pnlColor = stock.netPnl >= 0 ? AppColors.profit : AppColors.loss;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5)),
                                child: Icon(stock.icon, color: AppColors.gold, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stock.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(_formatBigNum(stock.currentPrice, isMoney: true), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'SpaceMono')),
                                        const SizedBox(width: 4),
                                        Icon(isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: trendColor, size: 24),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('stock.owned_shares'.tr(params: {'amount': _formatBigNum(stock.ownedShares)}), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text('stock.net_pnl'.tr(params: {'amount': _formatBigNum(stock.netPnl, isMoney: true)}), style: TextStyle(color: pnlColor, fontSize: 12, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // GRAFİK EKRANI
                          Container(
                            height: 70, 
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7), 
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12, width: 1.5),
                            ),
                            child: CustomPaint(
                              painter: SparklinePainter(data: stock.history, lineColor: trendColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.profit.withValues(alpha: 0.15),
                                    foregroundColor: AppColors.profit,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.profit, width: 1.5)),
                                  ),
                                  onPressed: gameState.money >= stock.currentPrice ? () => context.read<GameState>().buyStock(stock.id) : null,
                                  child: Text('stock.buy_button'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                                    foregroundColor: AppColors.gold,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.gold, width: 1.5)),
                                  ),
                                  onPressed: stock.ownedShares > 0 ? () => context.read<GameState>().sellAllStock(stock.id) : null,
                                  child: Text('stock.sell_button'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
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
      ..strokeWidth = 2.5 
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
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.7) - (size.height * 0.15);

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