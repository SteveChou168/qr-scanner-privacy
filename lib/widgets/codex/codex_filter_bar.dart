// lib/widgets/codex/codex_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_text.dart';
import '../../data/models/scan_record.dart';
import '../../providers/codex_provider.dart';

class CodexFilterBar extends StatelessWidget {
  const CodexFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CodexProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: AppText.filterAll,
                isSelected: provider.filterType == null && !provider.showFavoritesOnly,
                onTap: () {
                  provider.setFilter(null);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppText.filterFavorites,
                icon: Icons.star,
                color: Colors.amber,
                isSelected: provider.showFavoritesOnly,
                onTap: () => provider.setFavoritesFilter(!provider.showFavoritesOnly),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppText.typeUrl,
                icon: Icons.link,
                color: Colors.blue,
                isSelected: provider.filterType == SemanticType.url,
                onTap: () => provider.setFilter(SemanticType.url),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppText.typeIsbn,
                icon: Icons.menu_book,
                color: Colors.brown,
                isSelected: provider.filterType == SemanticType.isbn,
                onTap: () => provider.setFilter(SemanticType.isbn),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppText.codexFilterBarcode,
                icon: Icons.qr_code,
                color: Colors.grey,
                isSelected: provider.filterType == SemanticType.text,
                onTap: () => provider.setFilter(SemanticType.text),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppText.typeWifi,
                icon: Icons.wifi,
                color: Colors.purple,
                isSelected: provider.filterType == SemanticType.wifi,
                onTap: () => provider.setFilter(SemanticType.wifi),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppText.typeEmail,
                icon: Icons.email,
                color: Colors.orange,
                isSelected: provider.filterType == SemanticType.email,
                onTap: () => provider.setFilter(SemanticType.email),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Material(
      color: isSelected
          ? effectiveColor.withValues(alpha: 0.15)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? effectiveColor.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? effectiveColor : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? effectiveColor : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
