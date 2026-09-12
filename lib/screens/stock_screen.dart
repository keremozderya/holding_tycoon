// lib/screens/stock_screen.dart
// ignore_for_file: prefer_const_declarations

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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3.0)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: stock.iconColor, width: 2)), 
              child: Icon(stock.icon, color: stock.iconColor, size: 24)
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(stock.name.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900))),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Birim Fiyat:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w900)),
                      Text('\$${_formatNum(stock.currentPrice)}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'SpaceMono')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('YATIRILACAK TUTAR:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,a-zA-Z]'))],
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.textMuted),
                    hintText: 'Miktar girin...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.gold, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                
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
                const SizedBox(height: 16),

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
            height: 45, width: 80, 
            color: AppColors.surfaceElevated, shadowColor: const Color(0xFF14161C), 
            onPressed: () { AudioService.instance.playSfx('click.mp3'); Navigator.pop(c); }, 
            child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 11))
          ),
          StockHeavyButton(
            height: 45, width: 120,
            color: AppColors.gold, shadowColor: const Color(0xFF8B6B32),
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
            child: const Text('SATIN AL', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuffixButton(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: StockHeavyButton(
        height: 38,
        width: 48,
        depth: 4.0, 
        color: Colors.black,
        shadowColor: AppColors.surfaceElevated,
        onPressed: () {
          HapticFeedback.selectionClick(); 
          AudioService.instance.playSfx('click.mp3');
          String current = ctrl.text.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
          if (current.isNotEmpty) {
            ctrl.text = '$current${label.toLowerCase()}';
            ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
          }
        },
        child: Text(label, style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onTap) {
    return Expanded(
      child: StockHeavyButton(
        height: 42,
        depth: 4.0, 
        color: AppColors.background,
        shadowColor: Colors.black,
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('MENKUL KIYMETLER', style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 24), 
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            Navigator.pop(context);
          }
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 3.0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kullanılabilir Bakiye', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.gold, width: 2)), child: Text('\$${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.textSecondary, size: 36),
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: gameState.stocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final stock = gameState.stocks[index];
                
                bool isGoingUp = stock.history.isNotEmpty && stock.currentPrice >= stock.history.first;
                Color trendColor = isGoingUp ? AppColors.profit : AppColors.loss;

                String pnlSign = stock.netPnl >= 0 ? '+' : '-';
                String pnlFormatted = _formatNum(stock.netPnl);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: stock.iconColor, width: 2)),
                            child: Icon(stock.icon, color: stock.iconColor, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock.name.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
                                const SizedBox(height: 6),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: Colors.black, child: Text('\$${_formatNum(stock.currentPrice)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2), color: Colors.black),
                            width: 85, height: 48,
                            child: CustomPaint(painter: SparklinePainter(history: stock.history, lineColor: trendColor)),
                          ),
                        ],
                      ),
                      
                      if (stock.ownedShares > 0) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.border, height: 1, thickness: 2)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sahip Olunan', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(_formatNum(stock.ownedShares), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'SpaceMono')),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Net Kâr/Zarar', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: Colors.black,
                                  child: Text(
                                    '$pnlSign\$$pnlFormatted',
                                    style: TextStyle(
                                      color: stock.netPnl >= 0 ? AppColors.profit : AppColors.loss,
                                      fontWeight: FontWeight.w900, 
                                      fontSize: 14,
                                      fontFamily: 'SpaceMono'
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: StockHeavyButton(
                              height: 48,
                              color: AppColors.background, shadowColor: Colors.black,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                AudioService.instance.playSfx('click.mp3');
                                _showBuyDialog(context, gameState, stock);
                              },
                              child: const Text('ALIM YAP', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                            ),
                          ),
                          if (stock.ownedShares > 0) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: StockHeavyButton(
                                height: 48,
                                color: AppColors.border, shadowColor: const Color(0xFF14161C),
                                onPressed: () { 
                                  HapticFeedback.mediumImpact(); 
                                  AudioService.instance.playSfx('cash.mp3');
                                  gameState.sellAllStock(stock.id); 
                                },
                                child: const Text('TÜMÜNÜ SAT', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
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
    
    final double padding = 4.0;
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
      ..strokeWidth = 1.5 
      ..strokeJoin = StrokeJoin.miter;

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
    this.depth = 6.0,
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
                color: isDisabled ? AppColors.border.withValues(alpha: 0.5) : widget.shadowColor, 
                border: Border.all(color: Colors.black87, width: 2.5)
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
                color: isDisabled ? AppColors.surfaceElevated : widget.color, 
                border: Border.all(color: Colors.black87, width: 2.5)
              ), 
              child: Center(child: widget.child)
            )
          ),
        ]),
      ),
    );
  }
}