// lib/screens/generator_screen.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:provider/provider.dart';
import '../app_text.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../services/ad_service.dart';
import '../services/barcode_parser.dart';
import '../utils/app_constants.dart';
import '../utils/snackbar_helper.dart';
import '../utils/url_launcher_helper.dart';
import '../data/social_media_options.dart';
import '../data/info_type_options.dart';
import '../data/models/scan_record.dart';
import '../widgets/generator/horizontal_icon_selector.dart';
import '../growth/logic/growth_service.dart';

/// 生成器標籤類型
enum _GeneratorTab { social, info }

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _noteController = TextEditingController();
  final _qrKey = GlobalKey();
  String _qrData = '';

  // Tab 狀態
  _GeneratorTab _currentTab = _GeneratorTab.social;

  // Validation error
  String? _validationError;

  // WiFi fields
  final _wifiSsidController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  String _wifiSecurityType = 'WPA';

  // Social media selection
  SocialMediaOption? _selectedSocialMedia;
  List<SocialMediaOption> _socialMediaOptions = [];
  String? _lastLocaleCode;

  // Info type selection
  InfoTypeOption? _selectedInfoType;

  // Ad service
  final AdService _adService = AdService();
  int _remainingQuota = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadQuota();
    _adService.loadRewardedAd();
    // 預設是社群 Tab，_selectedSocialMedia 會在 didChangeDependencies 中初始化
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App 從背景恢復時重新載入配額（處理跨日情況）
    if (state == AppLifecycleState.resumed) {
      _loadQuota();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSocialMediaOptions();
  }

  void _loadSocialMediaOptions() {
    final appLang = AppText.language;

    if (_lastLocaleCode == appLang) return;
    _lastLocaleCode = appLang;

    setState(() {
      _socialMediaOptions = getSocialMediaOptions(appLang);
      if (_selectedSocialMedia != null &&
          !_socialMediaOptions.any((o) => o.id == _selectedSocialMedia!.id)) {
        _selectedSocialMedia = null;
      }
      // 如果是社群 Tab 且沒有選中項，自動選第一個
      if (_currentTab == _GeneratorTab.social &&
          _selectedSocialMedia == null &&
          _socialMediaOptions.isNotEmpty) {
        _selectedSocialMedia = _socialMediaOptions.first;
      }
    });
  }

  Future<void> _loadQuota() async {
    final quota = await _adService.getRemainingQuota();
    if (mounted) {
      setState(() {
        _remainingQuota = quota;
      });
    }
  }

  Future<void> _onQuotaChipTapped() async {
    final canWatch = await _adService.canWatchAdProactively();

    if (!canWatch) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppText.adDailyLimitReachedTitle),
          content: Text(AppText.adDailyLimitReachedMessage),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppText.dialogConfirm),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.adGetExtraQuotaTitle),
        content: Text(AppText.adGetExtraQuotaMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppText.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppText.adWatchAd),
          ),
        ],
      ),
    );

    if (result == true) {
      final rewardAmount = await _adService.showRewardedAd();
      if (rewardAmount > 0) {
        await _adService.incrementAdWatchCount();
        await _adService.addRewardQuota(rewardAmount);
        await _loadQuota();
        _showRewardResult(rewardAmount);
      }
    }
  }

  /// 顯示獎勵結果（5次時顯示恭喜彈窗）
  void _showRewardResult(int rewardAmount) {
    if (rewardAmount >= 5) {
      // 獎勵 5 次 - 顯示恭喜彈窗
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Text('🎉', style: TextStyle(fontSize: 48)),
          title: Text(AppText.adBonusRewardTitle),
          content: Text(AppText.adBonusRewardMessage(rewardAmount)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppText.dialogConfirm),
            ),
          ],
        ),
      );
    } else {
      // 一般獎勵 - 顯示 Snackbar
      SnackbarHelper.show(context, AppText.adRewardReceived(rewardAmount));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _noteController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _updateQRData() {
    String data = '';
    String? error;

    // 社交媒體模式
    if (_currentTab == _GeneratorTab.social && _selectedSocialMedia != null) {
      final input = _textController.text;
      if (input.isNotEmpty) {
        data = _selectedSocialMedia!.buildContent(input);
      }
    }
    // 資訊模式
    else if (_currentTab == _GeneratorTab.info && _selectedInfoType != null) {
      switch (_selectedInfoType!.id) {
        case 'text':
          data = _textController.text;
          if (data.length > AppConstants.maxQrDataLength) {
            error = AppText.contentTooLong;
          }
          break;
        case 'url':
          var url = _textController.text;
          if (url.isNotEmpty) {
            if (!url.startsWith('http')) {
              url = 'https://$url';
            }
            // 允許: 域名、路徑、查詢參數、端口
            if (!RegExp(r'^https?://(localhost(:\d+)?|[\w\-]+(\.[\w\-]+)+)(:\d+)?(/\S*)?$').hasMatch(url)) {
              error = AppText.invalidUrl;
            }
          }
          data = url;
          break;
        case 'email':
          final email = _textController.text;
          if (email.isNotEmpty) {
            if (!RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w+$').hasMatch(email)) {
              error = AppText.invalidEmail;
            } else {
              data = 'mailto:$email';
            }
          }
          break;
        case 'phone':
          final phone = _textController.text;
          if (phone.isNotEmpty) {
            // 移除空格和連字號，保留數字和 +
            final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
            data = 'tel:$cleanPhone';
          }
          break;
        case 'wifi':
          final ssid = _wifiSsidController.text;
          final password = _wifiPasswordController.text;
          if (password.length > AppConstants.maxWifiPasswordLength) {
            error = AppText.wifiPasswordTooLong;
          } else if (ssid.isNotEmpty) {
            data = 'WIFI:S:$ssid;T:$_wifiSecurityType;P:$password;;';
          }
          break;
      }
    }

    setState(() {
      _validationError = error;
      _qrData = error == null ? data : '';
    });
  }

  Future<bool> _checkQuotaAndShowAd() async {
    final needsAd = await _adService.needsToWatchAd();

    if (!needsAd) {
      await _adService.useQuota();
      await _loadQuota();
      return true;
    }

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppText.adQuotaExhaustedTitle),
        content: Text(AppText.adQuotaExhaustedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppText.dialogCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context, true);
            },
            child: Text(AppText.adWatchAd),
          ),
        ],
      ),
    );

    if (result == true) {
      final rewardAmount = await _adService.showRewardedAd();
      if (rewardAmount > 0) {
        await _adService.addRewardQuota(rewardAmount);
        await _loadQuota();
        _showRewardResult(rewardAmount);
        return true;
      }
    }

    return false;
  }

  /// 將 QR 圖片存到永久位置（documents/screenshots）
  Future<String?> _saveQRToDocuments(Uint8List pngBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${dir.path}/screenshots');
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${screenshotsDir.path}/qr_gen_$timestamp.png');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving QR to documents: $e');
      return null;
    }
  }

  /// 將生成的 QR Code 存入歷史記錄（呼叫端需先檢查重複）
  /// 成功存入時獲得 0.1 CP
  Future<void> _saveToHistory({String? imagePath}) async {
    if (_qrData.isEmpty) return;

    try {
      final historyProvider = context.read<HistoryProvider>();
      final parser = BarcodeParser();

      // 解析 QR 內容以取得語意類型
      final parsed = parser.parse(
        rawValue: _qrData,
        format: ms.BarcodeFormat.qrCode,
      );

      // 建立記錄（含圖片路徑）
      final record = ScanRecord(
        rawText: _qrData,
        displayText: parsed.displayText,
        barcodeFormat: BarcodeFormat.qrCode,
        semanticType: parsed.semanticType,
        scannedAt: DateTime.now(),
        imagePath: imagePath,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      // 直接存入（呼叫端已檢查重複）
      final savedRecord = await historyProvider.addRecord(record);

      // 成功存入時獲得 CP
      if (savedRecord != null) {
        await GrowthService.instance.earnScanCp(_qrData);
      }
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  /// 測試社群連結（不扣次數）
  Future<void> _testSocialLink() async {
    if (_selectedSocialMedia == null) return;

    final input = _textController.text.trim();
    if (input.isEmpty) {
      SnackbarHelper.showError(context, AppText.generatorEmpty);
      return;
    }

    final url = _selectedSocialMedia!.buildContent(input);
    final settings = context.read<SettingsProvider>();
    final success = await UrlLauncherHelper.openUrl(
      url,
      useExternalBrowser: settings.useExternalBrowser,
    );

    if (!success && mounted) {
      SnackbarHelper.showError(context, AppText.urlOpenFailed);
    }
  }

  Future<void> _saveQRImage() async {
    final canProceed = await _checkQuotaAndShowAd();
    if (!canProceed) return;

    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 存到相簿
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${dir.path}/qr_$timestamp.png');
      await tempFile.writeAsBytes(pngBytes);
      await Gal.putImage(tempFile.path);
      await tempFile.delete();

      // 檢查前10筆是否重複，不重複才存圖片和記錄
      final historyProvider = context.read<HistoryProvider>();
      final isDuplicate = await historyProvider.isDuplicateOfRecent(_qrData, limit: 10);
      if (!isDuplicate) {
        final savedImagePath = await _saveQRToDocuments(pngBytes);
        await _saveToHistory(imagePath: savedImagePath);
      }

      HapticFeedback.lightImpact();
      SnackbarHelper.showSuccess(context, AppText.imageSaved);
    } catch (e) {
      debugPrint('Error saving QR image: $e');
      SnackbarHelper.showError(context, AppText.imageSaveFailed);
    }
  }

  Future<void> _shareQRImage() async {
    final canProceed = await _checkQuotaAndShowAd();
    if (!canProceed) return;

    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 分享用暫存檔
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/qr_share.png');
      await tempFile.writeAsBytes(pngBytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(tempFile.path)],
        text: _qrData,
      ));

      // 檢查前10筆是否重複，不重複才存圖片和記錄
      final historyProvider = context.read<HistoryProvider>();
      final isDuplicate = await historyProvider.isDuplicateOfRecent(_qrData, limit: 10);
      if (!isDuplicate) {
        final savedImagePath = await _saveQRToDocuments(pngBytes);
        await _saveToHistory(imagePath: savedImagePath);
      }
    } catch (e) {
      debugPrint('Error sharing QR: $e');
    }
  }

  void _onTabChanged(_GeneratorTab tab) {
    if (_currentTab == tab) return;

    setState(() {
      _currentTab = tab;
      _textController.clear();
      _noteController.clear();
      _wifiSsidController.clear();
      _wifiPasswordController.clear();
      _qrData = '';
      _validationError = null;

      if (tab == _GeneratorTab.social) {
        _selectedInfoType = null;
        _selectedSocialMedia = _socialMediaOptions.isNotEmpty ? _socialMediaOptions.first : null;
      } else {
        _selectedSocialMedia = null;
        final infoTypes = getInfoTypeOptions();
        _selectedInfoType = infoTypes.isNotEmpty ? infoTypes.first : null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>().language;
    _loadSocialMediaOptions();

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.generatorTitle),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ActionChip(
              avatar: Icon(
                Icons.star,
                size: 18,
                color: _remainingQuota > 0
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppText.adRemainingQuota(_remainingQuota),
                    style: TextStyle(
                      fontSize: 12,
                      color: _remainingQuota > 0
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ],
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onPressed: _onQuotaChipTapped,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab 切換
            _buildTabSelector(colorScheme),
            const SizedBox(height: 16),

            // 圖標選擇器
            _buildIconSelector(colorScheme),
            const SizedBox(height: 20),

            // Input fields
            _buildInputFields(colorScheme),

            // Validation error
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationError!,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Note field
            _buildNoteField(colorScheme),
            const SizedBox(height: 24),

            // QR Preview with action buttons
            if (_qrData.isNotEmpty) ...[
              _buildQRPreviewWithActions(colorScheme),
            ] else ...[
              _buildEmptyState(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(ColorScheme colorScheme) {
    final isSocialSelected = _currentTab == _GeneratorTab.social;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _UnderlineTabButton(
                label: AppText.tabSocial,
                isSelected: isSocialSelected,
                onTap: () => _onTabChanged(_GeneratorTab.social),
                colorScheme: colorScheme,
              ),
            ),
            Expanded(
              child: _UnderlineTabButton(
                label: AppText.tabInfo,
                isSelected: !isSocialSelected,
                onTap: () => _onTabChanged(_GeneratorTab.info),
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        // 底部分隔線
        Container(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildIconSelector(ColorScheme colorScheme) {
    if (_currentTab == _GeneratorTab.social) {
      return HorizontalIconSelector<SocialMediaOption>(
        options: _socialMediaOptions,
        selectedOption: _selectedSocialMedia,
        onSelected: (option) {
          setState(() {
            if (option != null) {
              final currentInput = _textController.text.trim();
              final isFromSocialMedia = _selectedSocialMedia != null;
              final isPureId = currentInput.isNotEmpty &&
                  !currentInput.startsWith('http') &&
                  !currentInput.contains('/');

              _selectedSocialMedia = option;

              if (isFromSocialMedia && isPureId) {
                _updateQRData();
              } else {
                _textController.clear();
                _noteController.clear();
                _qrData = '';
              }
            } else {
              _selectedSocialMedia = null;
              _textController.clear();
              _qrData = '';
            }
          });
        },
        getId: (o) => o.id,
        getName: (o) => o.name,
        getIcon: (o) => o.icon,
        getColor: (o) => o.color,
      );
    } else {
      final infoTypes = getInfoTypeOptions();
      return HorizontalIconSelector<InfoTypeOption>(
        options: infoTypes,
        selectedOption: _selectedInfoType,
        onSelected: (option) {
          setState(() {
            if (option != null) {
              _selectedInfoType = option;
              _textController.clear();
              _noteController.clear();
              _wifiSsidController.clear();
              _wifiPasswordController.clear();
              _qrData = '';
              _validationError = null;
            }
          });
        },
        getId: (o) => o.id,
        getName: (o) => o.name,
        getIcon: (o) => o.icon,
        getColor: (o) => o.color,
      );
    }
  }

  /// 鐵灰色（用於深色品牌在暗色模式的輸入欄位圖標）
  static const _darkModeIconColor = Color(0xFFB0B0B0);

  /// 檢查顏色是否太暗（接近純黑）
  bool _isDarkColor(Color c) {
    // 閾值 0.05：只有接近純黑的顏色才視為太暗
    // 避免飽和藍/紫色（如 LinkedIn、Discord）被誤判
    return c.computeLuminance() < 0.05;
  }

  Widget _buildInputFields(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 社交媒體模式
    if (_currentTab == _GeneratorTab.social && _selectedSocialMedia != null) {
      final brandColor = _selectedSocialMedia!.color;
      final iconColor = (isDark && _isDarkColor(brandColor))
          ? _darkModeIconColor
          : brandColor;

      return TextField(
        controller: _textController,
        decoration: InputDecoration(
          labelText: _selectedSocialMedia!.name,
          hintText: AppText.socialInputHint,
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                _selectedSocialMedia!.icon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedSocialMedia!.displayPrefix,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        maxLines: 1,
        keyboardType: TextInputType.text,
        onChanged: (_) => _updateQRData(),
      );
    }

    // 資訊模式
    if (_currentTab == _GeneratorTab.info && _selectedInfoType != null) {
      if (_selectedInfoType!.id == 'wifi') {
        return Column(
          children: [
            TextField(
              controller: _wifiSsidController,
              decoration: InputDecoration(
                labelText: AppText.wifiSsid,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.wifi),
              ),
              onChanged: (_) => _updateQRData(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _wifiSecurityType,
              decoration: InputDecoration(
                labelText: AppText.wifiType,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              items: [
                DropdownMenuItem(value: 'WPA', child: Text(AppText.wifiTypeWpa)),
                DropdownMenuItem(value: 'WEP', child: Text(AppText.wifiTypeWep)),
                DropdownMenuItem(value: 'nopass', child: Text(AppText.wifiTypeOpen)),
              ],
              onChanged: (value) {
                setState(() {
                  _wifiSecurityType = value ?? 'WPA';
                });
                _updateQRData();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _wifiPasswordController,
              decoration: InputDecoration(
                labelText: AppText.wifiPassword,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.password),
              ),
              obscureText: true,
              onChanged: (_) => _updateQRData(),
            ),
          ],
        );
      }

      final infoColor = _selectedInfoType!.color;
      final infoIconColor = (isDark && _isDarkColor(infoColor))
          ? _darkModeIconColor
          : infoColor;

      return TextField(
        controller: _textController,
        decoration: InputDecoration(
          labelText: _getInputLabel(),
          hintText: _getInputHint(),
          border: const OutlineInputBorder(),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: FaIcon(
              _selectedInfoType!.icon,
              color: infoIconColor,
              size: 20,
            ),
          ),
        ),
        maxLines: 1,
        keyboardType: _getKeyboardType(),
        onChanged: (_) => _updateQRData(),
      );
    }

    // Fallback
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: AppText.inputText,
        hintText: AppText.inputHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.text_fields),
      ),
      maxLines: 1,
      onChanged: (_) => _updateQRData(),
    );
  }

  Widget _buildQRPreviewWithActions(ColorScheme colorScheme) {
    final hasNote = _noteController.text.trim().isNotEmpty;
    final hasBrandLogo = _currentTab == _GeneratorTab.social && _selectedSocialMedia != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // QR Code 預覽（左側）
        Expanded(
          child: RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: _getQrCodeColor(),
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: _getQrCodeColor(),
                          ),
                        ),
                        if (hasBrandLogo)
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _getBrandBackgroundColor(),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: FaIcon(
                                    _selectedSocialMedia!.icon,
                                    size: 32,
                                    color: _getBrandLogoColor(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        _noteController.text.trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 操作按鈕（右側垂直排列）
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 測試按鈕（僅社群 TAB 顯示）
            if (_currentTab == _GeneratorTab.social) ...[
              _ActionIconButton(
                icon: Icons.open_in_new_rounded,
                label: AppText.testLink,
                onTap: _testSocialLink,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),
            ],
            // 儲存按鈕
            _ActionIconButton(
              icon: Icons.save_alt_rounded,
              label: AppText.saveImage,
              onTap: _saveQRImage,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            // 分享按鈕
            _ActionIconButton(
              icon: Icons.share_rounded,
              label: AppText.shareQR,
              onTap: _shareQRImage,
              colorScheme: colorScheme,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  Color _getBrandLogoColor() {
    if (_selectedSocialMedia == null) return Colors.black;

    if (_selectedSocialMedia!.id == 'kakao') {
      return Colors.black;
    }

    if (_selectedSocialMedia!.id == 'snapchat') {
      return const Color(0xFFE5B800);
    }

    return _selectedSocialMedia!.color;
  }

  Color _getBrandBackgroundColor() {
    if (_selectedSocialMedia == null) return Colors.grey.shade100;

    final color = _selectedSocialMedia!.color;

    if (color == Colors.black) {
      return Colors.grey.shade200;
    }

    if (_selectedSocialMedia!.id == 'kakao') {
      return color.withValues(alpha: 0.3);
    }

    if (_selectedSocialMedia!.id == 'snapchat') {
      return const Color(0xFFFFFC00).withValues(alpha: 0.3);
    }

    return color.withValues(alpha: 0.15);
  }

  Color _getQrCodeColor() {
    if (_currentTab == _GeneratorTab.social && _selectedSocialMedia != null) {
      final brandColor = _selectedSocialMedia!.color;

      if (brandColor == Colors.black) {
        return Colors.black;
      }

      final hsl = HSLColor.fromColor(brandColor);

      if (hsl.lightness > 0.4) {
        return hsl.withLightness(0.35).toColor();
      }

      return brandColor;
    }

    // 資訊模式用黑色 QR
    return Colors.black;
  }

  Widget _buildNoteField(ColorScheme colorScheme) {
    return TextField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: AppText.noteLabel,
        hintText: AppText.noteHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.note_outlined),
      ),
      maxLines: 1,
      onChanged: (_) => setState(() {}),
    );
  }


  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              AppText.generatorEmpty,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getInputLabel() {
    if (_selectedInfoType == null) return AppText.inputText;

    return switch (_selectedInfoType!.id) {
      'text' => AppText.inputText,
      'url' => 'URL',
      'email' => AppText.typeEmail,
      'phone' => AppText.templatePhone,
      _ => AppText.inputText,
    };
  }

  String _getInputHint() {
    if (_selectedInfoType == null) return AppText.inputHint;

    return switch (_selectedInfoType!.id) {
      'text' => AppText.inputHint,
      'url' => 'example.com',
      'email' => 'user@example.com',
      'phone' => '',
      _ => AppText.inputHint,
    };
  }

  TextInputType _getKeyboardType() {
    if (_selectedInfoType == null) return TextInputType.text;

    return switch (_selectedInfoType!.id) {
      'text' => TextInputType.multiline,
      'url' => TextInputType.url,
      'email' => TextInputType.emailAddress,
      'phone' => TextInputType.phone,
      _ => TextInputType.text,
    };
  }
}

/// Material 風格下劃線 Tab 按鈕
class _UnderlineTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _UnderlineTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 文字區域
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              child: Text(label),
            ),
          ),
          // 下劃線指示器
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 3,
            width: isSelected ? 32 : 0,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS 簡約風操作按鈕
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isPrimary;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isPrimary
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
