// lib/screens/research_screen.dart
// ignore_for_file: discarded_futures, prefer_const_constructors, unnecessary_import, no_leading_underscores_for_local_identifiers

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
    
    if (_nodes.isEmpty) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: Colors.black)));

    final rootNode = _nodes[0];
    final leftNodes = _nodes.sublist(1, 50);
    final rightNodes = _nodes.sublist(50, 99);
    final apexNode = _nodes[99];
    
    final currentRP = gameState.researchPoints;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('research.app_bar_title'.tr(), style: AppTheme.titleStyle(fontSize: 24).copyWith(color: Colors.black, shadows: [])),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 32),
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            Navigator.pop(context);
          }
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science_rounded, color: Colors.black, size: 24),
                const SizedBox(width: 8),
                Text(
                  '$currentRP RP',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'SpaceMono'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)], 
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))]),
                        child: Center(child: Text('research.industry_col'.tr().toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))]),
                        child: Center(child: Text('research.finance_col'.tr().toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                Center(child: _buildTreeCard(apexNode, _nodes, isCenter: true, isApex: true, customWidth: 320)),
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
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black, width: 3)),
                    elevation: 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
                    },
                    child: const Icon(Icons.arrow_upward_rounded, size: 28),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'scroll_bottom',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black, width: 3)),
                    elevation: 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                    },
                    child: const Icon(Icons.arrow_downward_rounded, size: 28),
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

    Color borderColor = Colors.black;
    Color bgColor;

    if (maxed) {
      bgColor = AppColors.profit; 
    } else if (unlocked) {
      bgColor = isApex ? AppColors.neonCyan : AppColors.gold;
    } else if (accessible) {
      bgColor = Colors.white;
    } else {
      bgColor = const Color(0xFFCBD5E1); 
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _showNodeDetailsModal(node, allNodes);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: customWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 0, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: accessible ? Colors.white : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Icon(
                    node.icon, size: 28,
                    color: accessible ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.category.toUpperCase(),
                        style: TextStyle(color: accessible ? Colors.black87 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        maxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                        style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                      ),
                    ],
                  ),
                ),
                if (!accessible) const Icon(Icons.lock_rounded, color: Colors.black54, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              node.title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accessible ? Colors.black : Colors.black54, fontSize: 15, fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accessible ? Colors.white : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2)
              ),
              child: Text(
                node.isUnlocked ? node.currentEffectText : 'research.next_effect'.tr(params: {'effect': node.nextEffectText}),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  maxed ? 'research.completed'.tr() : '${node.cost} RP',
                  style: TextStyle(color: maxed ? AppColors.profit : (accessible ? AppColors.gold : Colors.white70), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterSpine({required bool isLeftUnlocked, required bool isRightUnlocked}) {
    return Container(
      width: 24, height: 135, alignment: Alignment.center,
      child: Container(width: 6, height: double.infinity, color: (isLeftUnlocked || isRightUnlocked) ? AppColors.gold : Colors.black),
    );
  }

  Widget _buildVerticalSpineConnector() {
    return Center(child: Container(width: 6, height: 24, color: Colors.black));
  }

  Widget _buildForkConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CustomPaint(size: const Size(double.infinity, 40), painter: ForkLinesPainter()),
    );
  }

  Widget _buildJoinConnector({required bool isLeftMaxed, required bool isRightMaxed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: CustomPaint(size: const Size(double.infinity, 40), painter: JoinLinesPainter(isActive: isLeftMaxed && isRightMaxed)),
    );
  }

  void _showNodeDetailsModal(ResearchNode node, List<ResearchNode> allNodes) {
    final bool accessible = _canUnlock(node, allNodes);
    final int currentRP = context.read<GameState>().researchPoints;
    final bool canAfford = currentRP >= node.cost && !node.isMaxed && accessible;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, -10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 4),
                    ),
                    child: Icon(node.icon, color: Colors.black, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(node.title, style: AppTheme.titleStyle(fontSize: 24).copyWith(color: Colors.black, shadows: [])),
                        const SizedBox(height: 6),
                        Text(node.category.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      node.isMaxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('research.current_level'.tr(params: {'level': node.currentLevel.toString()}), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(node.currentEffectText, style: TextStyle(color: node.isUnlocked ? Colors.black : Colors.black54, fontSize: 16, fontWeight: FontWeight.w900)),
                    const Divider(color: Colors.black, height: 32, thickness: 3),
                    Text('research.next_level'.tr(params: {'level': (node.isMaxed ? node.maxLevel : node.currentLevel + 1).toString()}), style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(node.nextEffectText, style: TextStyle(color: node.isMaxed ? Colors.black38 : AppColors.profit, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!accessible)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: AppColors.loss, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Text('research.lock_warning'.tr(), style: const TextStyle(color: AppColors.loss, fontSize: 14, fontWeight: FontWeight.w900))),
                    ],
                  ),
                ),
              ResearchHeavyButton(
                width: double.infinity, height: 65,
                color: node.isMaxed ? AppColors.profit : (canAfford ? AppColors.gold : const Color(0xFFE2E8F0)),
                shadowColor: node.isMaxed ? Colors.green.shade800 : (canAfford ? Colors.orange.shade700 : Colors.grey.shade400),
                onPressed: canAfford ? () {
                  HapticFeedback.mediumImpact();
                  AudioService.instance.playSfx('click.mp3');
                  Navigator.pop(context); 
                  context.read<GameState>().upgradeResearch(node.id); 
                } : null,
                child: Text(
                  node.isMaxed ? 'research.max_level_reached'.tr() : (!accessible ? 'research.btn_req_unmet'.tr() : 'research.btn_upgrade'.tr(params: {'cost': node.cost.toString()})),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0, color: canAfford || node.isMaxed ? Colors.black : Colors.black38),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ForkLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeWidth = 6.0..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    final path = Path();
    final midX = size.width / 2, leftX = size.width * 0.25, rightX = size.width * 0.75;
    path.moveTo(midX, 0); path.lineTo(midX, 20);
    path.moveTo(leftX, 20); path.lineTo(rightX, 20);
    path.moveTo(leftX, 20); path.lineTo(leftX, size.height);
    path.moveTo(rightX, 20); path.lineTo(rightX, size.height);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JoinLinesPainter extends CustomPainter {
  final bool isActive;
  JoinLinesPainter({required this.isActive});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isActive ? AppColors.gold : Colors.black..strokeWidth = 6.0..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    final path = Path();
    final midX = size.width / 2, leftX = size.width * 0.25, rightX = size.width * 0.75;
    path.moveTo(leftX, 0); path.lineTo(leftX, 20);
    path.moveTo(rightX, 0); path.lineTo(rightX, 20);
    path.moveTo(leftX, 20); path.lineTo(rightX, 20);
    path.moveTo(midX, 20); path.lineTo(midX, size.height);
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
          Positioned(bottom: 0, left: 0, right: 0, top: 8, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade400 : widget.shadowColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 4)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 8, left: 0, right: 0, top: _isPressed || isDisabled ? 8 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 4)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}