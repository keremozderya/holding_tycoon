// lib/screens/research_screen.dart
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
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
    
    // Veriler artık tek kaynak olan GameState'ten alınıyor!
    final _nodes = gameState.researchNodes; 
    
    // Eğer node'lar boş gelirse (uygulama ilk başlatılıyor veya veri yükleniyorsa) boş ekran göster
    if (_nodes.isEmpty) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.gold)));

    final rootNode = _nodes[0];
    final leftNodes = _nodes.sublist(1, 50);
    final rightNodes = _nodes.sublist(50, 99);
    final apexNode = _nodes[99];
    
    final currentRP = gameState.researchPoints;

    return Scaffold(
      backgroundColor: AppColors.background, 
      appBar: AppBar(
        title: Text('research.app_bar_title'.tr(), style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.gold)),
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.border, 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold, width: 1.5),
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
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            children: [
              Center(child: _buildTreeCard(rootNode, _nodes, isCenter: true, customWidth: 280)),
              _buildForkConnector(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 2)),
                      child: Center(child: Text('research.industry_col'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900))),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 2)),
                      child: Center(child: Text('research.finance_col'.tr(), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900))),
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
              const SizedBox(height: 80),
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
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.gold,
                  elevation: 4,
                  onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic),
                  child: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'scroll_bottom',
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.gold,
                  elevation: 4,
                  onPressed: () => _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic),
                  child: const Icon(Icons.arrow_downward_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
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
      bgColor = AppColors.surface; 
    } else if (unlocked) {
      borderColor = isApex ? AppColors.neonCyan : AppColors.gold;
      bgColor = AppColors.surface; 
    } else if (accessible) {
      borderColor = AppColors.gold.withValues(alpha: 0.5);
      bgColor = AppColors.surface;
    } else {
      borderColor = AppColors.border;
      bgColor = Colors.black26; 
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showNodeDetailsModal(node, allNodes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: customWidth,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: unlocked ? 2.0 : 1.5),
          boxShadow: unlocked ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 3))] : [],
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
                    color: unlocked ? AppColors.border : Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: unlocked ? AppColors.gold : Colors.transparent),
                  ),
                  child: Icon(
                    node.icon, size: 20,
                    color: accessible ? (unlocked ? AppColors.gold : AppColors.textSecondary) : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.category.toUpperCase(),
                        style: TextStyle(color: accessible ? AppColors.gold : AppColors.textMuted, fontSize: 8.5, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        maxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                        style: TextStyle(color: maxed ? AppColors.profit : (unlocked ? AppColors.textPrimary : AppColors.textMuted), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'),
                      ),
                    ],
                  ),
                ),
                if (!accessible) const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              node.title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accessible ? AppColors.textPrimary : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, height: 1.15),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                node.isUnlocked ? node.currentEffectText : 'research.next_effect'.tr(params: {'effect': node.nextEffectText}),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: maxed ? AppColors.profit : (node.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary), fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                maxed ? 'research.completed'.tr() : '${node.cost} RP',
                style: TextStyle(color: maxed ? AppColors.profit : (accessible ? AppColors.gold : AppColors.textMuted), fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterSpine({required bool isLeftUnlocked, required bool isRightUnlocked}) {
    return Container(
      width: 20, height: 95, alignment: Alignment.center,
      child: Container(width: 3, height: double.infinity, color: (isLeftUnlocked || isRightUnlocked) ? AppColors.gold : AppColors.border),
    );
  }

  Widget _buildVerticalSpineConnector() {
    return Center(child: Container(width: 3, height: 14, color: AppColors.border));
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
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.background, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.gold, width: 2),
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
                      color: AppColors.surface,
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
                        Text(node.title, style: AppTheme.titleStyle(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(node.category.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Text(
                    node.isMaxed ? 'research.max'.tr() : '${node.currentLevel}/${node.maxLevel}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('research.current_level'.tr(params: {'level': node.currentLevel.toString()}), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(node.currentEffectText, style: TextStyle(color: node.isUnlocked ? AppColors.textPrimary : AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Divider(color: AppColors.border, height: 20, thickness: 2),
                    Text('research.next_level'.tr(params: {'level': (node.isMaxed ? node.maxLevel : node.currentLevel + 1).toString()}), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(node.nextEffectText, style: TextStyle(color: node.isMaxed ? AppColors.textMuted : AppColors.profit, fontSize: 14, fontWeight: FontWeight.bold)),
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
                    backgroundColor: node.isMaxed ? AppColors.profit : (canAfford ? AppColors.gold : AppColors.surface),
                    foregroundColor: canAfford || node.isMaxed ? AppColors.darkBrown : AppColors.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.darkBrown, width: canAfford ? 2 : 1)),
                    elevation: canAfford ? 4 : 0,
                  ),
                  onPressed: canAfford ? () {
                    Navigator.pop(context); // Paneli kapat
                    context.read<GameState>().upgradeResearch(node.id); // Gerçek veriyi güncelle
                  } : null,
                  child: Text(
                    node.isMaxed ? 'research.max_level_reached'.tr() : (!accessible ? 'research.btn_req_unmet'.tr() : 'research.btn_upgrade'.tr(params: {'cost': node.cost.toString()})),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                  ),
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
    final paint = Paint()..color = AppColors.gold..strokeWidth = 3.0..style = PaintingStyle.stroke;
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
    final paint = Paint()..color = isActive ? AppColors.gold : AppColors.border..strokeWidth = 3.0..style = PaintingStyle.stroke;
    final path = Path();
    final midX = size.width / 2, leftX = size.width * 0.25, rightX = size.width * 0.75;
    path.moveTo(leftX, 0); path.lineTo(leftX, 10); path.lineTo(midX, 20);
    path.moveTo(rightX, 0); path.lineTo(rightX, 10); path.lineTo(midX, 20);
    path.lineTo(midX, size.height);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant JoinLinesPainter oldDelegate) => oldDelegate.isActive != isActive;
}