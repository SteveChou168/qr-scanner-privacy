// Cyber Parts Growth System - Parts Grid
// 零件網格顯示組件

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_text.dart';
import '../data/cyber_part.dart';

/// 賽博零件網格
/// 顯示已收集與未收集的零件
class CyberPartsGrid extends StatelessWidget {
  final List<CyberPart> parts;
  final Set<String> collectedIds;
  final Color accentColor;
  final int currentRound;
  final double itemSize;
  final double spacing;

  const CyberPartsGrid({
    super.key,
    required this.parts,
    required this.collectedIds,
    required this.accentColor,
    this.currentRound = 1,
    this.itemSize = 48,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: parts.map((part) {
        final isCollected = collectedIds.contains(part.id);
        return _CyberPartItem(
          part: part,
          isCollected: isCollected,
          accentColor: accentColor,
          currentRound: currentRound,
          size: itemSize,
        );
      }).toList(),
    );
  }
}

/// 單一零件項目
class _CyberPartItem extends StatelessWidget {
  final CyberPart part;
  final bool isCollected;
  final Color accentColor;
  final int currentRound;
  final double size;

  const _CyberPartItem({
    required this.part,
    required this.isCollected,
    required this.accentColor,
    required this.currentRound,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCollected ? () => _showPartDetail(context) : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isCollected
              ? accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCollected
                ? accentColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: isCollected ? 2 : 1,
          ),
          boxShadow: isCollected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isCollected
              ? Text(
                  part.emoji,
                  style: TextStyle(fontSize: size * 0.55),
                )
              : Text(
                  '?',
                  style: TextStyle(
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
        ),
      ),
    );
  }

  void _showPartDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            // 背景模糊 + 暗化
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            // 卡片
            _CyberPartCard(
              animation: animation,
              part: part,
              accentColor: accentColor,
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }
}

/// 賽博風格零件詳情卡片
class _CyberPartCard extends StatefulWidget {
  final Animation<double> animation;
  final CyberPart part;
  final Color accentColor;

  const _CyberPartCard({
    required this.animation,
    required this.part,
    required this.accentColor,
  });

  @override
  State<_CyberPartCard> createState() => _CyberPartCardState();
}

class _CyberPartCardState extends State<_CyberPartCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _dismissController;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _closeWithAnimation() {
    if (_isClosing) return;
    _isClosing = true;
    HapticFeedback.lightImpact();
    _dismissController.forward().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final partName = _getPartName(widget.part);

    return Center(
      child: AnimatedBuilder(
        animation: _dismissController,
        builder: (context, child) {
          final progress = _dismissController.value;
          final scale = 1.0 - progress * 0.3;
          final opacity = 1.0 - progress;

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: _closeWithAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0D1117),
                    const Color(0xFF161B22),
                    const Color(0xFF0D1117),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 掃描線動畫背景
                    _buildScanLineEffect(),

                    // 角落光暈
                    Positioned(
                      left: -40,
                      top: -40,
                      child: _buildCornerGlow(100, widget.accentColor.withValues(alpha: 0.2)),
                    ),
                    Positioned(
                      right: -50,
                      bottom: -50,
                      child: _buildCornerGlow(120, widget.accentColor.withValues(alpha: 0.15)),
                    ),

                    // 主要內容
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 零件圖示
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              final glowOpacity = 0.3 + 0.3 * _glowController.value;
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.accentColor.withValues(alpha: 0.6),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accentColor.withValues(alpha: glowOpacity),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.part.emoji,
                                    style: const TextStyle(fontSize: 52),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // 零件名稱
                          Text(
                            partName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: widget.accentColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // 復用標記
                          if (widget.part.isReuse) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.replay,
                                    size: 14,
                                    color: Colors.amber.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppText.growthReusePart,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // 年份和模組資訊
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.accentColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildInfoChip(
                                  AppText.growthYearNumber(widget.part.year),
                                  widget.accentColor,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: widget.accentColor.withValues(alpha: 0.3),
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  AppText.growthRoundNumber(widget.part.moduleIndex + 1),
                                  widget.accentColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 關閉按鈕
                          TextButton(
                            onPressed: _closeWithAnimation,
                            style: TextButton.styleFrom(
                              foregroundColor: widget.accentColor,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                            ),
                            child: Text(
                              AppText.btnConfirm,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanLineEffect() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, _) {
          return CustomPaint(
            painter: _ScanLinePainter(
              progress: _glowController.value,
              color: widget.accentColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCornerGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  String _getPartName(CyberPart part) {
    return AppText.growthPartName(part.id);
  }
}

/// 掃描線效果繪製器
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // 水平掃描線
    final y = size.height * progress;
    paint.shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: 0.3),
        color.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));

    canvas.drawRect(
      Rect.fromLTWH(0, y - 1, size.width, 2),
      paint,
    );

    // 網格線
    paint.shader = null;
    paint.color = color.withValues(alpha: 0.03);
    const gridSize = 20.0;

    for (var x = 0.0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
