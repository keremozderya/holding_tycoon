// lib/screens/research_screen.dart
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _canUnlock(ResearchNode node, List<ResearchNode> allNodes) {
    if (node.parentIds.isEmpty) return true;
    return node.parentIds.every((parentId) {
      final parent = allNodes.firstWhere(
        (n) => n.id == parentId,
        orElse: () => node,
      );
      return parent.isUnlocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final _nodes = gameState.researchNodes; 
    
    if (_nodes.isEmpty) return const Scaffold(backgroundColor: Color(0xFF14141C), body: Center(child: CircularProgressIndicator(color: AppColors.gold)));

    final rootNode = _nodes[0];
    final leftNodes = _nodes.sublist(1, 50);
    final rightNodes = _nodes.sublist(50, 99);
    final apexNode = _nodes[99];
    
    final currentRP = gameState.researchPoints;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('research.app_bar_title'.tr(), style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.gold)),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 24),
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            Navigator.pop(context);
          }
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6), 
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$currentRP RP',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'SpaceMono'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF14141C), Color(0xFF0A0A10)], 
          ),
        ),
        child: Stack(
          children: [
            ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(left: 14, right: 14, top: MediaQuery.of(context).padding.top + kToolbarHeight + 20, bottom: 80),
              children: [
                Center(child: _buildTreeCard(rootNode, _nodes, isCenter: true, customWidth: 280)),
                _buildForkConnector(),
                Row(
                  children: [
                    Expanded(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.gold, width: 2)),
                            child: Center(child: Text('research.industry_col'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.gold, width: 2)),
                            child: Center(child: Text('research.finance_col'.tr(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < 49; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTreeCard(leftNodes[i], _nodes)),
                      _buildCenterSpine(isLeftUnlocked: leftNodes[i].isUnlocked, isRightUnlocked: rightNodes[i].isUnlocked),
                      Expanded(child: _buildTreeCard(rightNodes[i], _nodes)),
                    ],
                  ),
                  if (i < 48) _buildVerticalSpineConnector(),
                ],
                _buildJoinConnector(isLeftMaxed: leftNodes.last.isUnlocked, isRightMaxed: rightNodes.last.isUnlocked),
                Center(child: _buildTreeCard(apexNode, _nodes, isCenter: true, isApex: true, customWidth: 300)),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'scroll_top',
                    backgroundColor: Colors.black,
                    foregroundColor: AppColors.gold,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.gold, width: 2)),
                    elevation: 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
                    },
                    child: const Icon(Icons.arrow_upward_rounded, size: 24),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'scroll_bottom',
                    backgroundColor: Colors.black,
                    foregroundColor: AppColors.gold,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.gold, width: 2)),
                    elevation: 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                    },
                    child: const Icon(Icons.arrow_downward_rounded, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeCard(ResearchNode node, List<ResearchNode> allNodes, {bool isCenter = false, bool isApex = false, double? customWidth}) {
    final bool accessible = _canUnlock(node, allNodes);
    final bool unlocked = node.isUnlocked;
    final bool maxed = node.isMaxed;

    Color borderColor;
    Color bgColor;

    if (maxed) {
      borderColor = AppColors.profit; 
      bgColor = Colors.black.withValues(alpha: 0.7); 
    } else if (unlocked) {
      borderColor = isApex ? AppColors.neonCyan : AppColors.gold;
      bgColor = Colors.black.withValues(alpha: 0.7); 
    } else if (accessible) {
      borderColor = AppColors.gold.withValues(alpha: 0.4);
      bgColor = Colors.black.withValues(alpha: 0.5);
    } else {
      borderColor = AppColors.border;
      bgColor = Colors.black.withValues(alpha: 0.3); 
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _showNodeDetailsModal(node, allNodes);
      },
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: customWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: borderColor, width: unlocked ? 2.5 : 1.5),
              boxShadow: unlocked ? [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: unlocked ? Colors.black : Colors.black45,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: unlocked ? AppColors.gold : AppColors.border, width: 2),
                      ),
                      child: Icon(
                        node.icon, size: 22,
                        color: accessible ? (unlocked ? AppColors.gold : Colors.white60) : Colors.white24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.category.toUpperCase(),
                            style: TextStyle(color: accessible ? AppColors.gold : Colors.white30, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            maxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                            style: TextStyle(color: maxed ? AppColors.profit : (unlocked ? Colors.white : Colors.white54), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                          ),
                        ],
                      ),
                    ),
                    if (!accessible) const Icon(Icons.lock_rounded, color: AppColors.border, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  node.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: accessible ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w900, height: 1.15),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.border, width: 1.5)
                  ),
                  child: Text(
                    node.isUnlocked ? node.currentEffectText : 'research.next_effect'.tr(params: {'effect': node.nextEffectText}),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: maxed ? AppColors.profit : (node.isUnlocked ? Colors.white : Colors.white60), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.black,
                    child: Text(
                      maxed ? 'research.completed'.tr() : '${node.cost} RP',
                      style: TextStyle(color: maxed ? AppColors.profit : (accessible ? AppColors.gold : Colors.white30), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterSpine({required bool isLeftUnlocked, required bool isRightUnlocked}) {
    return Container(
      width: 24, height: 105, alignment: Alignment.center,
      child: Container(width: 4, height: double.infinity, color: (isLeftUnlocked || isRightUnlocked) ? AppColors.gold : AppColors.border),
    );
  }

  Widget _buildVerticalSpineConnector() {
    return Center(child: Container(width: 4, height: 16, color: AppColors.border));
  }

  Widget _buildForkConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(size: const Size(double.infinity, 30), painter: ForkLinesPainter()),
    );
  }

  Widget _buildJoinConnector({required bool isLeftMaxed, required bool isRightMaxed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CustomPaint(size: const Size(double.infinity, 30), painter: JoinLinesPainter(isActive: isLeftMaxed && isRightMaxed)),
    );
  }

  void _showNodeDetailsModal(ResearchNode node, List<ResearchNode> allNodes) {
    final bool accessible = _canUnlock(node, allNodes);
    final int currentRP = context.read<GameState>().researchPoints;
    final bool canAfford = currentRP >= node.cost && !node.isMaxed && accessible;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8), 
                border: const Border(top: BorderSide(color: AppColors.gold, width: 4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.gold, width: 3),
                        ),
                        child: Icon(node.icon, color: AppColors.gold, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(node.title, style: AppTheme.titleStyle(fontSize: 22).copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(node.category.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: Colors.black,
                        child: Text(
                          node.isMaxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('research.current_level'.tr(params: {'level': node.currentLevel.toString()}), style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(node.currentEffectText, style: TextStyle(color: node.isUnlocked ? Colors.white : Colors.white54, fontSize: 15, fontWeight: FontWeight.w900)),
                        const Divider(color: AppColors.border, height: 24, thickness: 2),
                        Text('research.next_level'.tr(params: {'level': (node.isMaxed ? node.maxLevel : node.currentLevel + 1).toString()}), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(node.nextEffectText, style: TextStyle(color: node.isMaxed ? Colors.white30 : AppColors.profit, fontSize: 15, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!accessible)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.loss.withValues(alpha: 0.2), borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.loss, width: 2)),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded, color: AppColors.loss, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text('research.lock_warning'.tr(), style: const TextStyle(color: AppColors.loss, fontSize: 12, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    ),
                  ResearchHeavyButton(
                    width: double.infinity, height: 55,
                    color: node.isMaxed ? AppColors.profit : (canAfford ? AppColors.gold : AppColors.surfaceElevated),
                    shadowColor: node.isMaxed ? const Color(0xFF1B5E20) : (canAfford ? const Color(0xFF8B6B32) : Colors.black),
                    onPressed: canAfford ? () {
                      HapticFeedback.mediumImpact();
                      AudioService.instance.playSfx('click.mp3');
                      Navigator.pop(context); 
                      context.read<GameState>().upgradeResearch(node.id); 
                    } : null,
                    child: Text(
                      node.isMaxed ? 'research.max_level_reached'.tr() : (!accessible ? 'research.btn_req_unmet'.tr() : 'research.btn_upgrade'.tr(params: {'cost': node.cost.toString()})),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: canAfford || node.isMaxed ? AppColors.darkBrown : Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ForkLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold..strokeWidth = 4.0..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.miter;
    final path = Path();
    final midX = size.width / 2, leftX = size.width * 0.25, rightX = size.width * 0.75;
    path.moveTo(midX, 0); path.lineTo(midX, 15);
    path.moveTo(leftX, 15); path.lineTo(rightX, 15);
    path.moveTo(leftX, 15); path.lineTo(leftX, size.height);
    path.moveTo(rightX, 15); path.lineTo(rightX, size.height);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JoinLinesPainter extends CustomPainter {
  final bool isActive;
  JoinLinesPainter({required this.isActive});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isActive ? AppColors.gold : AppColors.border..strokeWidth = 4.0..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.miter;
    final path = Path();
    final midX = size.width / 2, leftX = size.width * 0.25, rightX = size.width * 0.75;
    path.moveTo(leftX, 0); path.lineTo(leftX, 15);
    path.moveTo(rightX, 0); path.lineTo(rightX, 15);
    path.moveTo(leftX, 15); path.lineTo(rightX, 15);
    path.moveTo(midX, 15); path.lineTo(midX, size.height);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant JoinLinesPainter oldDelegate) => oldDelegate.isActive != isActive;
}

class ResearchHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child; final Color color; final Color shadowColor; final double height; final double? width;
  const ResearchHeavyButton({super.key, required this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width});
  @override State<ResearchHeavyButton> createState() => _ResearchHeavyButtonState();
}
class _ResearchHeavyButtonState extends State<ResearchHeavyButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) { HapticFeedback.lightImpact(); AudioService.instance.playSfx('click.mp3'); setState(() => _isPressed = true); },
      onTapUp: isDisabled ? null : (_) { setState(() => _isPressed = false); widget.onPressed!(); },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0, top: 6, child: Container(decoration: BoxDecoration(color: isDisabled ? AppColors.border.withValues(alpha: 0.5) : widget.shadowColor, border: Border.all(color: Colors.black87, width: 2.5)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 6, left: 0, right: 0, top: _isPressed || isDisabled ? 6 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? AppColors.surfaceElevated : widget.color, border: Border.all(color: Colors.black87, width: 2.5)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}