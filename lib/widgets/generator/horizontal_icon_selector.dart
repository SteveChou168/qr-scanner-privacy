// lib/widgets/generator/horizontal_icon_selector.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 橫向可滑動的圖標選擇器（社群和資訊共用）
class HorizontalIconSelector<T> extends StatelessWidget {
  final List<T> options;
  final T? selectedOption;
  final ValueChanged<T?> onSelected;
  final String Function(T) getId;
  final String Function(T) getName;
  final IconData Function(T) getIcon;
  final Color Function(T) getColor;
  final bool showLabel;

  const HorizontalIconSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    required this.getId,
    required this.getName,
    required this.getIcon,
    required this.getColor,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: showLabel ? 80 : 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedOption != null && getId(selectedOption as T) == getId(option);
          final color = getColor(option);

          return _IconItem(
            icon: getIcon(option),
            label: getName(option),
            color: color,
            isSelected: isSelected,
            showLabel: showLabel,
            colorScheme: colorScheme,
            onTap: () {
              if (isSelected) {
                onSelected(null);
              } else {
                onSelected(option);
              }
            },
          );
        },
      ),
    );
  }
}

class _IconItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final bool showLabel;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _IconItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.showLabel,
    required this.colorScheme,
    required this.onTap,
  });

  // 銀色（用於深色品牌在暗色模式的外框）
  static const _silverColor = Color(0xFFB0B0B0);

  /// 檢查顏色是否太暗（接近純黑）
  bool _isDarkColor(Color c) {
    // 計算相對亮度 (0.0 = 黑, 1.0 = 白)
    // 閾值 0.05：只有接近純黑的顏色才視為太暗
    // 避免飽和藍/紫色（如 LinkedIn、Discord）被誤判
    final luminance = c.computeLuminance();
    return luminance < 0.05;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDarkBrand = _isDarkColor(color); // 用亮度檢測，不只是純黑

    // 圖標顏色：深色品牌在暗色模式用白色
    final iconColor = (isDarkBrand && isDark) ? Colors.white : color;

    // 背景色：暗色模式全黑，淺色模式保持原樣
    final backgroundColor = isDark
        ? Colors.black
        : (isSelected ? color.withValues(alpha: 0.15) : colorScheme.surfaceContainerLow);

    // 邊框色：選中時亮品牌色（深色品牌在暗色模式用銀色）
    final borderColor = isSelected
        ? ((isDarkBrand && isDark) ? _silverColor : color)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: iconColor,
                // 視覺補償：淺色模式下深色 ICON 看起來較小（光滲現象），+2px 補償
                size: isDark ? 28 : 30,
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 56,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                    ? ((isDarkBrand && isDark) ? _silverColor : color)
                    : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
