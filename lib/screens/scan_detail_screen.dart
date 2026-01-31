// lib/screens/scan_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../app_text.dart';
import '../data/models/scan_record.dart';
import '../providers/history_provider.dart';
import '../providers/codex_provider.dart';
import '../services/barcode_parser.dart';
import '../utils/action_handler.dart';
import '../utils/clipboard_helper.dart';
import '../utils/date_format_helper.dart';
import '../utils/semantic_type_extension.dart';

/// 掃描記錄詳情頁 - 參考 TPML_APP 記事設計
class ScanDetailScreen extends StatefulWidget {
  final ScanRecord record;

  const ScanDetailScreen({
    super.key,
    required this.record,
  });

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  late ScanRecord _record;
  late TextEditingController _noteController;
  bool _noteSaved = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _noteController = TextEditingController(text: _record.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    ClipboardHelper.copy(context, text);
  }

  Future<void> _handleAction() async {
    await ActionHandler.handle(context, _record);
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    context.read<HistoryProvider>().toggleFavorite(_record.id!);
    setState(() {
      _record = _record.copyWith(isFavorite: !_record.isFavorite);
    });
  }

  void _deleteRecord() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppText.deleteConfirmTitle),
        content: Text(AppText.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppText.dialogCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Delete from both providers to ensure sync
              context.read<HistoryProvider>().deleteRecord(_record.id!);
              // Also refresh CodexProvider if available
              try {
                context.read<CodexProvider>().deleteRecord(_record.id!);
              } catch (_) {
                // CodexProvider might not be available in all contexts
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppText.actionDelete),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.detailTitle),
        actions: [
          // 收藏按鈕
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _record.isFavorite ? Icons.star : Icons.star_border,
              color: _record.isFavorite ? Colors.amber : null,
            ),
            tooltip: _record.isFavorite
                ? AppText.actionUnfavorite
                : AppText.actionFavorite,
          ),
          // 刪除按鈕
          IconButton(
            onPressed: _deleteRecord,
            icon: const Icon(Icons.delete_outline),
            tooltip: AppText.actionDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 類型標籤區
            Row(
              children: [
                _buildBadge(
                  _record.semanticType.label,
                  colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  _record.barcodeFormat.displayName,
                  colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 時間和地點元數據
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormatHelper.formatDateTime(_record.scannedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_record.placeName != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _record.placeName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 圖片區域（如果有照片）
            if (_record.imagePath != null && _record.imagePath!.isNotEmpty)
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _showFullImage(context),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: colorScheme.surfaceContainerHigh,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: File(_record.imagePath!).existsSync()
                            ? Image.file(
                                File(_record.imagePath!),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // 內容區域（主要掃描內容）
            Container(
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顯示內容標題
                  Text(
                    AppText.detailRawValue,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _record.rawText,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),

                  // 解析後的值
                  if (_record.displayText != null &&
                      _record.displayText != _record.rawText) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppText.detailParsedValue,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _record.displayText!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // WiFi 詳細信息（如果是 WiFi 類型）
            if (_record.semanticType == SemanticType.wifi) ...[
              const SizedBox(height: 16),
              _buildWifiInfoCard(colorScheme),
            ],

            const SizedBox(height: 16),

            // 備註區域
            _buildNoteSection(colorScheme, textTheme),

            const SizedBox(height: 24),

            // 操作按鈕區
            if (_record.semanticType != SemanticType.text)
              FilledButton.icon(
                onPressed: _handleAction,
                icon: Icon(_record.semanticType.actionIcon),
                label: Text(_record.semanticType.actionLabel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _copyToClipboard(_record.rawText),
              icon: const Icon(Icons.copy),
              label: Text(AppText.actionCopy),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                AppText.detailNote,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (_noteSaved)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppText.detailNoteSaved,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: AppText.detailNoteHint,
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: textTheme.bodyMedium,
            onChanged: (_) {
              if (_noteSaved) {
                setState(() => _noteSaved = false);
              }
            },
            onEditingComplete: _saveNote,
            onTapOutside: (_) {
              FocusScope.of(context).unfocus();
              _saveNote();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    final newNote = _noteController.text.trim();
    if (newNote == (_record.note ?? '')) return;

    final updatedRecord = _record.copyWith(note: newNote.isEmpty ? null : newNote);
    final success = await context.read<HistoryProvider>().updateRecord(updatedRecord);

    if (success && mounted) {
      setState(() {
        _record = updatedRecord;
        _noteSaved = true;
      });
    }
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWifiInfoCard(ColorScheme colorScheme) {
    final wifi = BarcodeParser.parseWifiString(_record.rawText);
    final ssid = wifi['ssid'] ?? '-';
    final password = wifi['password'] ?? '-';
    final security = wifi['type'] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'WiFi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _wifiDetailRow('SSID', ssid, colorScheme),
          _wifiDetailRow(AppText.wifiSecurity, security, colorScheme),
          Row(
            children: [
              Expanded(
                child: _wifiDetailRow(AppText.wifiPassword, password, colorScheme),
              ),
              if (password != '-')
                IconButton(
                  onPressed: () => _copyToClipboard(password),
                  icon: Icon(Icons.copy, size: 22, color: colorScheme.primary),
                  tooltip: AppText.wifiCopyPassword,
                  iconSize: 22,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wifiDetailRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    if (_record.imagePath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewerScreen(imagePath: _record.imagePath!),
      ),
    );
  }
}

/// 照片全屏檢視器
class _PhotoViewerScreen extends StatefulWidget {
  final String imagePath;

  const _PhotoViewerScreen({required this.imagePath});

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  bool _isSaving = false;

  Future<void> _saveToGallery() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 檢查權限並儲存到相簿
      await Gal.putImage(widget.imagePath);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppText.photoSavedToGallery),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppText.photoSaveFailed}: ${e.type.name}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppText.photoSaveFailed),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(widget.imagePath)],
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppText.shareFailed),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          // 頂部工具列
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 關閉按鈕
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // 分享和下載按鈕
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 分享按鈕
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white, size: 28),
                          onPressed: _shareImage,
                          tooltip: AppText.actionShare,
                        ),
                        // 下載到相簿按鈕
                        IconButton(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download, color: Colors.white, size: 28),
                          onPressed: _isSaving ? null : _saveToGallery,
                          tooltip: AppText.saveToGallery,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
