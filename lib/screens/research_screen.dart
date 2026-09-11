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
        title: Text('research.app_bar_title'.tr(), style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.gold)),
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6), 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$currentRP RP',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'SpaceMono'),
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
              padding: EdgeInsets.only(left: 14, right: 14, top: MediaQuery.of(context).padding.top + kToolbarHeight + 18, bottom: 80),
              children: [
                Center(child: _buildTreeCard(rootNode, _nodes, isCenter: true, customWidth: 280)),
                _buildForkConnector(),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5)),
                            child: Center(child: Text('research.industry_col'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5)),
                            child: Center(child: Text('research.finance_col'.tr(), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900))),
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
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5))),
                    elevation: 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
                    },
                    child: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'scroll_bottom',
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5))),
                    elevation: 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
                    },
                    child: const Icon(Icons.arrow_downward_rounded, size: 20),
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
      bgColor = Colors.black.withValues(alpha: 0.5); 
    } else if (unlocked) {
      borderColor = isApex ? AppColors.neonCyan : AppColors.gold;
      bgColor = Colors.black.withValues(alpha: 0.5); 
    } else if (accessible) {
      borderColor = AppColors.gold.withValues(alpha: 0.3);
      bgColor = Colors.black.withValues(alpha: 0.4);
    } else {
      borderColor = Colors.white12;
      bgColor = Colors.black.withValues(alpha: 0.2); 
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        _showNodeDetailsModal(node, allNodes);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: customWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: unlocked ? 1.5 : 1.0),
              boxShadow: unlocked ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 3))] : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: unlocked ? Colors.black45 : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: unlocked ? AppColors.gold : Colors.transparent),
                      ),
                      child: Icon(
                        node.icon, size: 20,
                        color: accessible ? (unlocked ? AppColors.gold : Colors.white60) : Colors.white24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.category.toUpperCase(),
                            style: TextStyle(color: accessible ? AppColors.gold : Colors.white30, fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            maxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                            style: TextStyle(color: maxed ? AppColors.profit : (unlocked ? Colors.white : Colors.white54), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'),
                          ),
                        ],
                      ),
                    ),
                    if (!accessible) const Icon(Icons.lock_rounded, color: Colors.white24, size: 14),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  node.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: accessible ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, height: 1.15),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white10)
                  ),
                  child: Text(
                    node.isUnlocked ? node.currentEffectText : 'research.next_effect'.tr(params: {'effect': node.nextEffectText}),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: maxed ? AppColors.profit : (node.isUnlocked ? Colors.white : Colors.white60), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    maxed ? 'research.completed'.tr() : '${node.cost} RP',
                    style: TextStyle(color: maxed ? AppColors.profit : (accessible ? AppColors.gold : Colors.white30), fontSize: 10.5, fontWeight: FontWeight.w900),
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
      width: 20, height: 95, alignment: Alignment.center,
      child: Container(width: 2, height: double.infinity, color: (isLeftUnlocked || isRightUnlocked) ? AppColors.gold.withValues(alpha: 0.6) : Colors.white12),
    );
  }

  Widget _buildVerticalSpineConnector() {
    return Center(child: Container(width: 2, height: 14, color: Colors.white12));
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65), 
                border: const Border(top: BorderSide(color: AppColors.gold, width: 2)),
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
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: Icon(node.icon, color: AppColors.gold, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(node.title, style: AppTheme.titleStyle(fontSize: 20).copyWith(color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(node.category.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Text(
                        node.isMaxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('research.current_level'.tr(params: {'level': node.currentLevel.toString()}), style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(node.currentEffectText, style: TextStyle(color: node.isUnlocked ? Colors.white : Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                        const Divider(color: Colors.white12, height: 20, thickness: 1.5),
                        Text('research.next_level'.tr(params: {'level': (node.isMaxed ? node.maxLevel : node.currentLevel + 1).toString()}), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(node.nextEffectText, style: TextStyle(color: node.isMaxed ? Colors.white30 : AppColors.profit, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!accessible)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.loss.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.loss)),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded, color: AppColors.loss, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('research.lock_warning'.tr(), style: const TextStyle(color: AppColors.loss, fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: node.isMaxed ? AppColors.profit : (canAfford ? AppColors.gold : Colors.black45),
                        foregroundColor: canAfford || node.isMaxed ? AppColors.darkBrown : Colors.white30,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: canAfford ? AppColors.darkBrown : Colors.white12, width: canAfford ? 2 : 1)),
                        elevation: canAfford ? 4 : 0,
                      ),
                      onPressed: canAfford ? () {
                        HapticFeedback.mediumImpact();
                        AudioService.instance.playSfx('click.mp3');
                        Navigator.pop(context); 
                        context.read<GameState>().upgradeResearch(node.id); 
                      } : null,
                      child: Text(
                        node.isMaxed ? 'research.max_level_reached'.tr() : (!accessible ? 'research.btn_req_unmet'.tr() : 'research.btn_upgrade'.tr(params: {'cost': node.cost.toString()})),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                      ),
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
    final paint = Paint()..color = AppColors.gold.withValues(alpha: 0.6)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final path = Path();
    final midX = size.width / 2, leftX = size.width * 0.25, rightX = size.width * 0.75;
    path.moveTo(midX, 0); path.lineTo(midX, 10);
    path.moveTo(midX, 10); path.lineTo(leftX, 20); path.lineTo(leftX, size.height);
    path.moveTo(midX, 10); path.lineTo(rightX, 20); path.lineTo(rightX, size.height);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JoinLinesPainter extends CustomPainter {
  final bool isActive;
  JoinLinesPainter({required this.isActive});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isActive ? AppColors.gold.withValues(alpha: 0.6) : Colors.white12..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final path = Path();
    final midX = size.width / 2, leftX = size.width * 0.25, rightX = size.width * 0.75;
    path.moveTo(leftX, 0); path.lineTo(leftX, 10); path.lineTo(midX, 20);
    path.moveTo(rightX, 0); path.lineTo(rightX, 10); path.lineTo(midX, 20);
    path.lineTo(midX, size.height);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant JoinLinesPainter oldDelegate) => oldDelegate.isActive != isActive;
}