// lib/screens/stock_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../theme/app_theme.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  String _formatNum(double value) {
    double absVal = value.abs();

    if (absVal >= 1e33) return '${(absVal / 1e33).toStringAsFixed(2)} Dc';
    if (absVal >= 1e30) return '${(absVal / 1e30).toStringAsFixed(2)} No';
    if (absVal >= 1e27) return '${(absVal / 1e27).toStringAsFixed(2)} Oc';
    if (absVal >= 1e24) return '${(absVal / 1e24).toStringAsFixed(2)} Sp';
    if (absVal >= 1e21) return '${(absVal / 1e21).toStringAsFixed(2)} Sx';
    if (absVal >= 1e18) return '${(absVal / 1e18).toStringAsFixed(2)} Qi';
    if (absVal >= 1e15) return '${(absVal / 1e15).toStringAsFixed(2)} Qa';
    if (absVal >= 1e12) return '${(absVal / 1e12).toStringAsFixed(2)} T';
    if (absVal >= 1e9) return '${(absVal / 1e9).toStringAsFixed(2)} B';
    if (absVal >= 1e6) return '${(absVal / 1e6).toStringAsFixed(2)} M';
    if (absVal >= 1e3) return '${(absVal / 1e3).toStringAsFixed(1)} K';
    
    return absVal.toStringAsFixed(0);
  }

  double _parseInput(String input) {
    String cleaned = input.trim().toLowerCase().replaceAll(',', '.');
    if (cleaned.isEmpty) return 0.0;

    int letterIndex = cleaned.indexOf(RegExp(r'[a-z]'));

    if (letterIndex == -1) {
      return double.tryParse(cleaned) ?? 0.0;
    }

    double numberPart = double.tryParse(cleaned.substring(0, letterIndex)) ?? 0.0;
    String suffix = cleaned.substring(letterIndex);

    switch (suffix) {
      case 'k': return numberPart * 1e3;
      case 'm': return numberPart * 1e6;
      case 'b': return numberPart * 1e9;
      case 't': return numberPart * 1e12;
      case 'qa': return numberPart * 1e15;
      case 'qi': return numberPart * 1e18;
      case 'sx': return numberPart * 1e21;
      case 'sp': return numberPart * 1e24;
      case 'oc': return numberPart * 1e27;
      case 'no': return numberPart * 1e30;
      case 'dc': return numberPart * 1e33;
      default: return numberPart;
    }
  }

  void _showBuyDialog(BuildContext context, GameState state, Stock stock) {
    final TextEditingController amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border, width: 1.5)),
        title: Row(
          children: [
            Icon(stock.icon, color: stock.iconColor, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text('${stock.name} Yatırımı', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        // YENİ: Klavye açıldığında taşmayı engellemek için SingleChildScrollView eklendi
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Birim Fiyat:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('\$${_formatNum(stock.currentPrice)}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Yatırılacak Tutar:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  // YENİ: Harf klavyesini engellemek için sadece sayısal klavye açtırıyoruz
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,a-zA-Z]'))],
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.textMuted),
                    hintText: 'Miktar girin...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold)),
                  ),
                ),
                const SizedBox(height: 12),
                
                // YENİ: Kısaltma Butonları (Yatay kaydırılabilir)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSuffixButton('K', amountCtrl),
                      _buildSuffixButton('M', amountCtrl),
                      _buildSuffixButton('B', amountCtrl),
                      _buildSuffixButton('T', amountCtrl),
                      _buildSuffixButton('Qa', amountCtrl),
                      _buildSuffixButton('Qi', amountCtrl),
                      _buildSuffixButton('Sx', amountCtrl),
                      _buildSuffixButton('Sp', amountCtrl),
                      _buildSuffixButton('Oc', amountCtrl),
                      _buildSuffixButton('No', amountCtrl),
                      _buildSuffixButton('Dc', amountCtrl),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Hızlı Yatırım Butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickButton('25%', () => amountCtrl.text = _formatNum(state.money * 0.25).replaceAll(' ', '')),
                    _buildQuickButton('50%', () => amountCtrl.text = _formatNum(state.money * 0.50).replaceAll(' ', '')),
                    _buildQuickButton('MAX', () => amountCtrl.text = _formatNum(state.money).replaceAll(' ', '')),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              double inputAmount = _parseInput(amountCtrl.text); 
              
              if (inputAmount >= stock.currentPrice) {
                state.buyStockWithAmount(stock.id, inputAmount);
                Navigator.pop(c);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutar en az 1 hisse almaya yetmelidir!'), backgroundColor: AppColors.loss));
              }
            },
            // YENİ: EMİR VER yerine SATIN AL yazıldı
            child: const Text('SATIN AL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // YENİ: Text alanına basılan harfi (K, M, B vb.) ekleyen buton widget'ı
  Widget _buildSuffixButton(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(40, 32),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: AppColors.gold, // Harf rengini oyuna uygun altın sarısı yaptım
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          // Eğer içinde zaten harf varsa onu silip yenisini ekler, böylece "1.5km" gibi hatalar olmaz
          String current = ctrl.text.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
          if (current.isNotEmpty) {
            ctrl.text = '$current${label.toLowerCase()}';
            // İmleci yazının sonuna taşır
            ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
          }
        },
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('MENKUL KIYMETLER', style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // PORTFÖY ÖZETİ EKRANI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kullanılabilir Bakiye', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('\$${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.textSecondary, size: 32),
                )
              ],
            ),
          ),
          
          // HİSSE LİSTESİ
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: gameState.stocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final stock = gameState.stocks[index];
                
                bool isGoingUp = stock.history.isNotEmpty && stock.currentPrice >= stock.history.first;
                Color trendColor = isGoingUp ? AppColors.profit : AppColors.loss;

                String pnlSign = stock.netPnl >= 0 ? '+' : '-';
                String pnlFormatted = _formatNum(stock.netPnl);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: stock.iconColor.withValues(alpha: 0.3))),
                            child: Icon(stock.icon, color: stock.iconColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('\$${_formatNum(stock.currentPrice)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'SpaceMono')),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 60, height: 30,
                            child: CustomPaint(painter: SparklinePainter(history: stock.history, lineColor: trendColor)),
                          ),
                        ],
                      ),
                      
                      if (stock.ownedShares > 0) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.border, height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sahip Olunan', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                Text(_formatNum(stock.ownedShares), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Net Kâr/Zarar', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                Text(
                                  '$pnlSign\$$pnlFormatted',
                                  style: TextStyle(
                                    color: stock.netPnl >= 0 ? AppColors.profit : AppColors.loss, // DÜZELTİLEN YER
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 13
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.background, foregroundColor: AppColors.gold,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () => _showBuyDialog(context, gameState, stock),
                              child: const Text('AL', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (stock.ownedShares > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.border, foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () { gameState.sellAllStock(stock.id); },
                                child: const Text('TÜMÜNÜ SAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> history;
  final Color lineColor;

  SparklinePainter({required this.history, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    double maxVal = history.reduce(math.max);
    double minVal = history.reduce(math.min);
    if (maxVal == minVal) {
      maxVal += 1; minVal -= 1;
    }

    final path = Path();
    final stepX = size.width / (history.length > 1 ? history.length - 1 : 1);

    for (int i = 0; i < history.length; i++) {
      double normalizedY = (history[i] - minVal) / (maxVal - minVal);
      double x = i * stepX;
      double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}