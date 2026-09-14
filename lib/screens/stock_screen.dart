// lib/screens/stock_screen.dart
// ignore_for_file: discarded_futures, prefer_const_declarations

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/audio_service.dart';
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
    if (absVal > 0 && absVal < 10) return absVal.toStringAsFixed(1);
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

  Future<void> _showBuyDialog(BuildContext context, GameState state, Stock stock) async {
    final TextEditingController amountCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.black, width: 4.0)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(color: stock.iconColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: stock.iconColor, width: 3)), 
              child: Icon(stock.icon, color: stock.iconColor, size: 28)
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(stock.name.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Birim Fiyat:', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w900)),
                      Text('\$${_formatNum(stock.currentPrice)}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'SpaceMono')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('YATIRILACAK TUTAR:', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,a-zA-Z]'))],
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'SpaceMono'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.black, size: 28),
                    hintText: 'Miktar girin...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black, width: 3)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.neonCyan, width: 3)),
                  ),
                ),
                const SizedBox(height: 20),
                
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
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickButton('25%', () { HapticFeedback.selectionClick(); AudioService.instance.playSfx('click.mp3'); amountCtrl.text = _formatNum(state.money * 0.25).replaceAll(' ', ''); }),
                    const SizedBox(width: 8),
                    _buildQuickButton('50%', () { HapticFeedback.selectionClick(); AudioService.instance.playSfx('click.mp3'); amountCtrl.text = _formatNum(state.money * 0.50).replaceAll(' ', ''); }),
                    const SizedBox(width: 8),
                    _buildQuickButton('MAX', () { HapticFeedback.selectionClick(); AudioService.instance.playSfx('click.mp3'); amountCtrl.text = _formatNum(state.money).replaceAll(' ', ''); }),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          StockHeavyButton(
            height: 55, width: 100, 
            color: Colors.white, shadowColor: Colors.grey.shade400, 
            onPressed: () { AudioService.instance.playSfx('click.mp3'); Navigator.pop(c); }, 
            child: const Text('İPTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14))
          ),
          StockHeavyButton(
            height: 55, width: 140,
            color: AppColors.gold, shadowColor: Colors.orange.shade700,
            onPressed: () {
              double inputAmount = _parseInput(amountCtrl.text); 
              if (inputAmount >= stock.currentPrice) {
                HapticFeedback.mediumImpact(); 
                AudioService.instance.playSfx('cash.mp3');
                state.buyStockWithAmount(stock.id, inputAmount);
                Navigator.pop(c);
              } else {
                HapticFeedback.heavyImpact();
                AudioService.instance.playSfx('click.mp3');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutar en az 1 hisse almaya yetmelidir!', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.loss));
              }
            },
            child: const Text('SATIN AL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
    amountCtrl.dispose();
  }

  Widget _buildSuffixButton(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: StockHeavyButton(
        height: 48,
        width: 56,
        depth: 6.0, 
        color: const Color(0xFFF1F5F9),
        shadowColor: Colors.grey.shade400,
        onPressed: () {
          HapticFeedback.selectionClick(); 
          AudioService.instance.playSfx('click.mp3');
          String current = ctrl.text.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
          if (current.isNotEmpty) {
            ctrl.text = '$current${label.toLowerCase()}';
            ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
          }
        },
        child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onTap) {
    return Expanded(
      child: StockHeavyButton(
        height: 48,
        depth: 6.0, 
        color: AppColors.neonCyan,
        shadowColor: Colors.blue.shade700,
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black26, offset: Offset(1,1))])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('MENKUL KIYMETLER', style: AppTheme.titleStyle(fontSize: 22)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30, shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))]), 
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            Navigator.pop(context);
          }
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 4.0),
              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kullanılabilir Bakiye', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)), child: Text('\$${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 40),
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: gameState.stocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final stock = gameState.stocks[index];
                
                bool isGoingUp = stock.history.isNotEmpty && stock.currentPrice >= stock.history.first;
                Color trendColor = isGoingUp ? AppColors.profit : AppColors.loss;

                String pnlSign = stock.netPnl >= 0 ? '+' : '-';
                String pnlFormatted = _formatNum(stock.netPnl);

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black, width: 4), boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 6))]),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: stock.iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: stock.iconColor, width: 3)),
                            child: Icon(stock.icon, color: stock.iconColor, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock.name.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
                                const SizedBox(height: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: Text('\$${_formatNum(stock.currentPrice)}', style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(12), color: const Color(0xFFF8FAFC)),
                            width: 100, height: 60,
                            child: CustomPaint(painter: SparklinePainter(history: stock.history, lineColor: trendColor)),
                          ),
                        ],
                      ),
                      
                      if (stock.ownedShares > 0) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.black, height: 1, thickness: 3)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sahip Olunan', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Text(_formatNum(stock.ownedShares), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'SpaceMono')),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Net Kâr/Zarar', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: stock.netPnl >= 0 ? AppColors.profit.withValues(alpha: 0.15) : AppColors.loss.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: stock.netPnl >= 0 ? AppColors.profit : AppColors.loss, width: 2)),
                                  child: Text(
                                    '$pnlSign\$$pnlFormatted',
                                    style: TextStyle(
                                      color: stock.netPnl >= 0 ? AppColors.profit : AppColors.loss,
                                      fontWeight: FontWeight.w900, 
                                      fontSize: 16,
                                      fontFamily: 'SpaceMono'
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: StockHeavyButton(
                              height: 55,
                              color: AppColors.neonCyan, shadowColor: Colors.blue.shade700,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                AudioService.instance.playSfx('click.mp3');
                                _showBuyDialog(context, gameState, stock);
                              },
                              child: const Text('ALIM YAP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0, shadows: [Shadow(color: Colors.black26, offset: Offset(1,1))])),
                            ),
                          ),
                          if (stock.ownedShares > 0) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: StockHeavyButton(
                                height: 55,
                                color: AppColors.loss, shadowColor: Colors.red.shade900,
                                onPressed: () { 
                                  HapticFeedback.mediumImpact(); 
                                  AudioService.instance.playSfx('cash.mp3');
                                  gameState.sellAllStock(stock.id); 
                                },
                                child: const Text('TÜMÜNÜ SAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0, shadows: [Shadow(color: Colors.black26, offset: Offset(1,1))])),
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
    
    final double padding = 6.0;
    final double drawWidth = size.width - (padding * 2);
    final double drawHeight = size.height - (padding * 2);
    
    final stepX = drawWidth / (history.length > 1 ? history.length - 1 : 1);

    for (int i = 0; i < history.length; i++) {
      double normalizedY = (history[i] - minVal) / (maxVal - minVal);
      double x = padding + (i * stepX);
      double y = size.height - padding - (normalizedY * drawHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 // Thicker line for cartoon look
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}

class StockHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; 
  final Widget child; 
  final Color color; 
  final Color shadowColor; 
  final double height; 
  final double? width;
  final double depth;
  
  const StockHeavyButton({
    super.key, 
    required this.onPressed, 
    required this.child, 
    required this.color, 
    required this.shadowColor, 
    this.height = 50, 
    this.width,
    this.depth = 8.0,
  });
  
  @override 
  State<StockHeavyButton> createState() => _StockHeavyButtonState();
}

class _StockHeavyButtonState extends State<StockHeavyButton> {
  bool _isPressed = false;
  
  @override 
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) { 
        HapticFeedback.lightImpact(); 
        AudioService.instance.playSfx('click.mp3'); 
        setState(() => _isPressed = true); 
      },
      onTapUp: isDisabled ? null : (_) { 
        setState(() => _isPressed = false); 
        widget.onPressed!(); 
      },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(children: [
          Positioned(
            bottom: 0, left: 0, right: 0, top: widget.depth, 
            child: Container(
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey : widget.shadowColor, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 3)
              )
            )
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 60), 
            bottom: _isPressed || isDisabled ? 0 : widget.depth, 
            left: 0, right: 0, 
            top: _isPressed || isDisabled ? widget.depth : 0, 
            child: Container(
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey.shade300 : widget.color, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 3)
              ), 
              child: Center(child: widget.child)
            )
          ),
        ]),
      ),
    );
  }
}
