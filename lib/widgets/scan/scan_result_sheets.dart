// lib/widgets/scan/scan_result_sheets.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../app_text.dart';
import '../../data/models/scan_record.dart';
import '../../services/barcode_parser.dart';
import 'scan_models.dart';
import 'scan_action_buttons.dart';

/// Single result sheet for displaying one scanned code
class ScanResultSheet extends StatelessWidget {
  final ParsedBarcode code;
  final Function(ScanAction) onAction;
  final VoidCallback onDismiss;
  final Uint8List? imageData;

  const ScanResultSheet({
    super.key,
    required this.code,
    required this.onAction,
    required this.onDismiss,
    this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type label with icon + thumbnail
                Row(
                  children: [
                    Text(
                      code.semanticType.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code.semanticType.label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            code.barcodeFormat.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Thumbnail (only when imageData is available)
                    if (imageData != null)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withAlpha(50),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(
                          imageData!,
                          fit: BoxFit.cover,
                          cacheWidth: 120, // Limit decoded size for memory
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    code.rawValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      fontFamily: code.semanticType == SemanticType.isbn
                          ? 'monospace'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildActionButtons(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    // 1. Copy - always first
    buttons.add(ScanActionButton(
      icon: Icons.copy,
      label: AppText.scanCopy,
      onTap: () {
        onAction(ScanAction.copy);
        Navigator.pop(context);
      },
    ));

    // 2. Share - always second
    buttons.add(ScanActionButton(
      icon: Icons.share,
      label: AppText.scanShare,
      onTap: () {
        onAction(ScanAction.share);
        Navigator.pop(context);
      },
    ));

    // 3. Type-specific action - third (primary action)
    switch (code.semanticType) {
      case SemanticType.url:
        buttons.add(ScanActionButton(
          icon: Icons.open_in_new,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(ScanAction.open);
          },
        ));
        break;

      case SemanticType.email:
        buttons.add(ScanActionButton(
          icon: Icons.email,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(ScanAction.open);
          },
        ));
        break;

      case SemanticType.isbn:
        buttons.add(ScanActionButton(
          icon: Icons.search,
          label: AppText.scanSearch,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(ScanAction.search);
          },
        ));
        break;

      case SemanticType.wifi:
        buttons.add(ScanActionButton(
          icon: Icons.wifi,
          label: AppText.scanConnect,
          isPrimary: true,
          onTap: () {
            onAction(ScanAction.connect);
            Navigator.pop(context);
          },
        ));
        break;

      case SemanticType.sms:
        buttons.add(ScanActionButton(
          icon: Icons.sms,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(ScanAction.open);
          },
        ));
        break;

      case SemanticType.text:
      case SemanticType.vcard:
      case SemanticType.geo:
        // Search for types without specific open action
        buttons.add(ScanActionButton(
          icon: Icons.search,
          label: AppText.scanSearch,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(ScanAction.search);
          },
        ));
        break;
    }

    return buttons;
  }
}

/// Multi-code sheet for displaying multiple scanned codes
class MultiCodeSheet extends StatelessWidget {
  final List<ParsedBarcode> codes;
  final List<Uint8List?>? imageDataList;
  final Function(ParsedBarcode, ScanAction) onAction;
  final VoidCallback onDismiss;

  const MultiCodeSheet({
    super.key,
    required this.codes,
    required this.onAction,
    required this.onDismiss,
    this.imageDataList,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrollable code list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: codes.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (ctx, i) => _buildCodeCard(
                context,
                codes[i],
                imageDataList != null && i < imageDataList!.length ? imageDataList![i] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(BuildContext context, ParsedBarcode code, Uint8List? imageData) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type label with icon + thumbnail
        Row(
          children: [
            Text(
              code.semanticType.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code.semanticType.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    code.barcodeFormat.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            // Thumbnail
            if (imageData != null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(50),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  imageData,
                  fit: BoxFit.cover,
                  cacheWidth: 100,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            code.rawValue,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
              fontFamily: code.semanticType == SemanticType.isbn
                  ? 'monospace'
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Icon-only action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: _buildIconButtons(context, code),
        ),
      ],
    );
  }

  List<Widget> _buildIconButtons(BuildContext context, ParsedBarcode code) {
    final buttons = <Widget>[];

    // 1. Copy - always first
    buttons.add(ScanIconButton(
      icon: Icons.copy,
      onTap: () {
        onAction(code, ScanAction.copy);
      },
    ));

    // 2. Share - always second
    buttons.add(ScanIconButton(
      icon: Icons.share,
      onTap: () {
        onAction(code, ScanAction.share);
      },
    ));

    // 3. Type-specific action - third (primary action)
    switch (code.semanticType) {
      case SemanticType.url:
        buttons.add(ScanIconButton(
          icon: Icons.open_in_new,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(code, ScanAction.open);
          },
        ));
        break;

      case SemanticType.email:
        buttons.add(ScanIconButton(
          icon: Icons.email,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(code, ScanAction.open);
          },
        ));
        break;

      case SemanticType.isbn:
        buttons.add(ScanIconButton(
          icon: Icons.search,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(code, ScanAction.search);
          },
        ));
        break;

      case SemanticType.wifi:
        buttons.add(ScanIconButton(
          icon: Icons.wifi,
          isPrimary: true,
          onTap: () {
            onAction(code, ScanAction.connect);
          },
        ));
        break;

      case SemanticType.sms:
        buttons.add(ScanIconButton(
          icon: Icons.sms,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(code, ScanAction.open);
          },
        ));
        break;

      case SemanticType.text:
      case SemanticType.vcard:
      case SemanticType.geo:
        // Search for types without specific open action
        buttons.add(ScanIconButton(
          icon: Icons.search,
          isPrimary: true,
          onTap: () {
            Navigator.pop(context);
            onAction(code, ScanAction.search);
          },
        ));
        break;
    }

    return buttons;
  }
}
