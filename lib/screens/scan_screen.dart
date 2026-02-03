// lib/screens/scan_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:flutter_zxing/flutter_zxing.dart' as zxing;

import '../app_text.dart';
import '../data/models/scan_record.dart';
import '../growth/logic/growth_service.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/barcode_parser.dart';
import '../services/location_service.dart';
import '../services/taiwan_invoice_decoder.dart';
import '../widgets/scan/scan_widgets.dart';
import '../utils/url_launcher_helper.dart';
import '../services/inverted_barcode_helper.dart';

class ScanScreen extends StatefulWidget {
  final bool isActive;
  final ValueChanged<bool>? onGalleryModeChanged;

  const ScanScreen({super.key, this.isActive = true, this.onGalleryModeChanged});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  ms.MobileScannerController? _controller;
  final BarcodeParser _parser = BarcodeParser();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GlobalKey _cameraKey = GlobalKey();

  bool _torchOn = false;
  List<DetectedCode> _detectedCodes = [];
  bool _isPaused = false;
  bool _isProcessing = false;
  Timer? _debounceTimer;
  bool _controllerInitialized = false;
  bool _controllerReturnImage = false; // Track current returnImage setting


  // Multi-frame accumulation for better detection
  final Map<String, AccumulatedCode> _frameAccumulator = {};
  final Map<String, ParsedBarcode> _parseCache = {}; // Parse Cache 避免重複解析
  Timer? _detectionTimer;     // 標準模式：偵測到碼後 200ms
  Timer? _fallbackTimer;      // 標準模式：1 秒 fallback
  static const int _defaultFrameCount = 1; // 預設閾值（降低以提高識別率）
  static const int _maxFrameCount = 10; // frameCount 上限，避免無限增長

  // Continuous scan mode
  int _continuousScanCount = 0;
  final Set<String> _recentlyScanned = {};
  Timer? _recentlyClearTimer;

  // Paused background image (to show last frame when scanner is stopped)
  Uint8List? _pausedBackgroundImage;

  // 最新的相機幀（用於 fallback 掃描）
  Uint8List? _latestCameraFrame;

  // 多點觸摸追蹤（用於阻止 PageView 滑動）
  int _pointerCount = 0;

  // 照片模式
  bool _galleryMode = false;
  bool _isPickingImage = false;  // 正在選擇照片（相簿選擇器開啟中）
  Uint8List? _galleryImage;
  Size? _galleryImageSize;
  String? _galleryImagePath;

  // 對焦功能
  bool _focusSupported = true; // 假設支持，失敗時設為 false

  // 反相模式（用於掃描白底黑字條碼）
  bool _invertMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudio();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize controller with settings on first dependency resolution
    if (!_controllerInitialized) {
      _controllerInitialized = true;
      final settings = context.read<SettingsProvider>();
      _initController(returnImage: settings.saveImage);
    }
  }

  void _initController({bool returnImage = false}) {
    _controllerReturnImage = returnImage;
    _controller = ms.MobileScannerController(
      detectionSpeed: ms.DetectionSpeed.noDuplicates,
      cameraResolution: const Size(1920, 1080),
      returnImage: returnImage,
    );
    // Manually start if tab is active (autoStart removed in v7.x)
    if (widget.isActive) {
      _controller?.start();
    }
  }

  Future<void> _initAudio() async {
    // Pre-load beep sound
    await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.stop();
      // Clear detection states when app goes to background
      _clearAllDetectionStates();
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      controller.start();
      // Reset torch state (torch is off after camera restart)
      setState(() => _torchOn = false);
      // Auto focus on app resume
      Future.delayed(const Duration(milliseconds: 300), _triggerFocus);
    }
  }

  @override
  void didUpdateWidget(ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null) return;

    // Handle tab switching: pause/resume camera
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        // Check if saveImage setting changed, recreate controller if needed
        final settings = context.read<SettingsProvider>();
        if (settings.saveImage != _controllerReturnImage) {
          _recreateController(returnImage: settings.saveImage);
        } else {
          controller.start();
          // Reset torch state (torch is off after camera restart)
          setState(() => _torchOn = false);
          // Auto focus on tab switch
          Future.delayed(const Duration(milliseconds: 300), _triggerFocus);
        }
      } else {
        controller.stop();
        // Clear all detection states when leaving scan screen
        _clearAllDetectionStates();
      }
    }
  }

  Future<void> _recreateController({required bool returnImage}) async {
    await _controller?.dispose();
    _initController(returnImage: returnImage);
    if (widget.isActive) {
      _controller?.start();
      // Reset torch state (torch is off after camera restart)
      setState(() => _torchOn = false);
      // Auto focus after controller recreation
      Future.delayed(const Duration(milliseconds: 300), _triggerFocus);
    }
  }

  void _clearAllDetectionStates() {
    setState(() {
      _detectedCodes = [];
      _frameAccumulator.clear();
      _detectionTimer?.cancel();
      _fallbackTimer?.cancel();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _recentlyClearTimer?.cancel();
    _detectionTimer?.cancel();
    _fallbackTimer?.cancel();
    _controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onDetect(ms.BarcodeCapture capture) {
    if (_isPaused || _isProcessing) return;

    try {
      // 保存最新的相機幀（用於 fallback 掃描）
      if (capture.image != null) {
        _latestCameraFrame = capture.image;
      }

      // ZXing 並行掃描
      if (capture.image != null) {
        if (_invertMode) {
          // 反相模式：只用 ZXing 掃反相圖，跳過 ML Kit
          _processInvertedFrame(capture.image);
          return;
        } else {
          // 標準模式：ZXing 掃原圖（與 ML Kit 並行）
          _processOriginalFrame(capture.image);
        }
      }

      final barcodes = capture.barcodes;
      if (barcodes.isEmpty) {
        // 沒有偵測到碼，啟動 fallback Timer
        _fallbackTimer ??= Timer(const Duration(seconds: 1), () {
          _fallbackTimer = null;
          _stopAndShowResults();
        });
        return;
      }

      // 累積多幀偵測結果
      _accumulateDetectedCodes(barcodes, capture.image);
    } catch (e) {
      debugPrint('Error in barcode detection: $e');
    }
  }

  void _accumulateDetectedCodes(List<ms.Barcode> barcodes, Uint8List? image) {
    final now = DateTime.now();

    for (final barcode in barcodes) {
      if (barcode.rawValue == null || barcode.rawValue!.isEmpty) continue;

      final rawBytes = barcode.rawBytes;

      // 檢查是否為台灣電子發票，用 Big5 解碼
      String decodedValue = barcode.rawValue!;
      if (TaiwanInvoiceDecoder.isTaiwanInvoice(decodedValue, rawBytes)) {
        decodedValue = TaiwanInvoiceDecoder.getDecodedText(rawBytes, decodedValue);
        debugPrint('ML Kit: 台灣發票 Big5 解碼');
      }

      final key = decodedValue;

      // Parse Cache: 同一 rawValue 只解析一次
      final parsed = _parseCache.putIfAbsent(
        key,
        () => _parser.parse(rawValue: decodedValue, format: barcode.format),
      );

      Rect? boundingBox;
      if (barcode.corners.isNotEmpty) {
        boundingBox = _calculateBoundingBox(barcode.corners);
      }

      if (_frameAccumulator.containsKey(key)) {
        // 已存在，更新計數和位置
        _frameAccumulator[key]!.update(
          DetectedCode(
            parsed: parsed,
            boundingBox: boundingBox,
            imageData: image,
            rawBytes: rawBytes,
          ),
          maxFrameCount: _maxFrameCount,
          minFrameCount: _defaultFrameCount,
        );
      } else {
        // 新偵測到的碼
        _frameAccumulator[key] = AccumulatedCode(
          code: DetectedCode(
            parsed: parsed,
            boundingBox: boundingBox,
            imageData: image,
            rawBytes: rawBytes,
          ),
          lastSeen: now,
        );
      }
    }

    // 更新震動回饋
    _updateDetectedCodesFromAccumulator();

    // 兩層 Timer 設計
    // 1. fallback Timer（1 秒）：開始掃描時啟動，ML Kit 掃不到時 fallback
    // 2. detection Timer（200ms）：偵測到碼時啟動，等相機穩定
    _fallbackTimer ??= Timer(const Duration(seconds: 1), () {
      _fallbackTimer = null;
      _stopAndShowResults();
    });

    // 偵測到碼 → 取消 fallback，啟動 200ms Timer
    if (_detectionTimer == null && _frameAccumulator.isNotEmpty) {
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      _detectionTimer = Timer(const Duration(milliseconds: 200), () {
        _detectionTimer = null;
        _stopAndShowResults();
      });
    }
  }

  void _updateDetectedCodesFromAccumulator() {
    // 掃到穩定碼時給震動（聲音留給結果顯示）
    final hasNewStableCode = _frameAccumulator.values.any((acc) =>
        acc.frameCount == _defaultFrameCount &&
        !_detectedCodes.any((old) =>
            old.parsed.rawValue == acc.code.parsed.rawValue &&
            old.frameCount >= _defaultFrameCount));

    if (hasNewStableCode) {
      final settings = context.read<SettingsProvider>();
      if (settings.vibration) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  /// 累積後 + ZXing 補掃，顯示結果
  Future<void> _stopAndShowResults() async {
    // 避免競態條件：如果已暫停、正在處理、或 widget 已卸載，直接返回
    if (_isPaused || _isProcessing || !mounted) return;

    // 取得 ML Kit 累積的穩定碼
    final mlKitCodes = _frameAccumulator.entries
        .where((e) => e.value.frameCount >= _defaultFrameCount)
        .map((e) => e.value.code)
        .toList();

    // 取得背景圖片（用於 ZXing 補掃）
    // 優先順序：ML Kit 結果的圖片 > 最新相機幀 > 暫停背景
    final imageData = mlKitCodes.isNotEmpty
        ? mlKitCodes.first.imageData
        : (_latestCameraFrame ?? _pausedBackgroundImage);

    // 暫停相機，保留背景影像
    _pauseWithBackground(imageData);

    // ZXing 補掃背景圖片（MIG 4.0 發票 + Big5 解碼）
    final zxingCodes = imageData != null ? await _scanWithZXing(imageData) : <DetectedCode>[];

    if (!mounted) return;

    // 合併結果：用 rawValue 做 key，ZXing 優先
    final merged = <String, DetectedCode>{};
    for (final code in mlKitCodes) {
      merged[code.parsed.rawValue] = code;
    }
    for (final code in zxingCodes) {
      merged[code.parsed.rawValue] = code;  // ZXing 覆蓋 ML Kit
    }
    final allCodes = merged.values.toList();

    // 沒有任何結果，繼續掃描
    if (allCodes.isEmpty) {
      _frameAccumulator.clear();
      _parseCache.clear();
      _resumeScanning();
      return;
    }

    final settings = context.read<SettingsProvider>();

    // 連續掃描模式：自動儲存並繼續掃描（不顯示結果）
    if (settings.continuousScanMode) {
      _handleContinuousScan(allCodes);
      return;
    }

    // 結果顯示時只給聲音
    if (settings.sound) {
      _playBeep();
    }

    setState(() {
      _detectedCodes = allCodes;
    });

    // 直接顯示結果
    if (allCodes.length == 1) {
      _showSingleResult(allCodes.first);
    } else {
      _showMultiCodeSheet();
    }
  }

  Future<void> _handleContinuousScan(List<DetectedCode> codes) async {
    // Filter out recently scanned codes (within 5 seconds)
    final newCodes = codes.where((c) => !_recentlyScanned.contains(c.parsed.rawValue)).toList();

    if (newCodes.isEmpty) {
      setState(() {
        _detectedCodes = [];
      });
      return;
    }

    // Mark as recently scanned
    for (final code in newCodes) {
      _recentlyScanned.add(code.parsed.rawValue);
    }

    // Clear recently scanned after 5 seconds
    _recentlyClearTimer?.cancel();
    _recentlyClearTimer = Timer(const Duration(seconds: 5), () {
      _recentlyScanned.clear();
    });

    // Save all new codes (skip duplicates of recent 10)
    for (final code in newCodes) {
      await _saveCodeIfNotDuplicate(code);
      _continuousScanCount++;
    }

    if (mounted) {
      setState(() {
        _detectedCodes = [];
      });
    }
  }

  Rect _calculateBoundingBox(List<Offset> corners) {
    double minX = corners.first.dx;
    double maxX = corners.first.dx;
    double minY = corners.first.dy;
    double maxY = corners.first.dy;

    for (final corner in corners) {
      if (corner.dx < minX) minX = corner.dx;
      if (corner.dx > maxX) maxX = corner.dx;
      if (corner.dy < minY) minY = corner.dy;
      if (corner.dy > maxY) maxY = corner.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _showSingleResult(DetectedCode code) async {
    // Auto-save (skip if duplicate of recent 10)
    await _saveCodeIfNotDuplicate(code);

    if (!mounted) return;

    _showSingleResultWithoutSave(code);
  }

  void _showSingleResultWithoutSave(DetectedCode code) {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScanResultSheet(
        code: code.parsed,
        onAction: (action) => _handleAction(code, action),
        onDismiss: _resumeScanning,
        imageData: settings.saveImage ? code.imageData : null,
      ),
    ).then((_) => _resumeScanning());
  }

  void _showMultiCodeSheet() async {
    // Auto-save all codes (skip duplicates)
    await _saveAllCodes();

    if (!mounted) return;

    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiCodeSheet(
        codes: _detectedCodes.map((c) => c.parsed).toList(),
        imageDataList: settings.saveImage
            ? _detectedCodes.map((c) => c.imageData).toList()
            : null,
        onAction: (parsed, action) {
          final code = _detectedCodes.firstWhere((c) => c.parsed == parsed);
          _handleAction(code, action);
        },
        onDismiss: _resumeScanning,
      ),
    ).then((_) => _resumeScanning());
  }

  void _resumeScanning() {
    if (mounted) {
      // 先取消所有 Timer 避免競態條件
      _detectionTimer?.cancel();
      _detectionTimer = null;
      _fallbackTimer?.cancel();
      _fallbackTimer = null;

      setState(() {
        _isPaused = false;
        _pausedBackgroundImage = null; // Clear background image
        _detectedCodes = [];
        _torchOn = false; // 重置手電筒狀態（相機重啟後手電筒會關閉）
        // Clear accumulators when resuming
        _frameAccumulator.clear();
        _parseCache.clear(); // 新掃描週期清空 Parse Cache
      });
      // Resume scanner after processing is complete
      _controller?.start();
    }
  }

  /// Pause scanning and save background image
  void _pauseWithBackground(Uint8List? imageData) {
    _isPaused = true;
    _pausedBackgroundImage = imageData;
    _controller?.stop();
  }

  /// ZXing 掃描背景圖片
  Future<List<DetectedCode>> _scanWithZXing(Uint8List imageBytes) async {
    final codes = <DetectedCode>[];
    File? tempFile;

    try {
      debugPrint('AR ZXing: 開始補掃...');

      // 寫到臨時檔案（ZXing 需要路徑）
      final tempDir = await getTemporaryDirectory();
      tempFile = File(p.join(tempDir.path, 'ar_scan_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      await tempFile.writeAsBytes(imageBytes);

      final params = zxing.DecodeParams(
        imageFormat: zxing.ImageFormat.rgb,
        format: zxing.Format.any,
        tryHarder: true,
        tryRotate: true,
        tryInverted: true,
        isMultiScan: true,
        maxSize: 9999,
      );

      final result = await zxing.zx.readBarcodesImagePathString(tempFile.path, params);
      debugPrint('AR ZXing: 找到 ${result.codes.length} 個');

      for (final code in result.codes) {
        if (code.text == null || code.text!.isEmpty) continue;

        final rawBytes = code.rawBytes;

        // 檢查是否為台灣電子發票，智慧判斷編碼（Big5 或 UTF-8）
        String rawValue = code.text!;
        if (TaiwanInvoiceDecoder.isTaiwanInvoice(rawValue, rawBytes)) {
          rawValue = TaiwanInvoiceDecoder.getDecodedText(rawBytes, rawValue);
        }

        final parsed = _parser.parse(
          rawValue: rawValue,
          format: _zxingFormatToMsFormat(code.format),
        );

        Rect? boundingBox;
        if (code.position != null) {
          final pos = code.position!;
          boundingBox = Rect.fromLTRB(
            pos.topLeftX.toDouble(),
            pos.topLeftY.toDouble(),
            pos.bottomRightX.toDouble(),
            pos.bottomRightY.toDouble(),
          );
        }

        codes.add(DetectedCode(
          parsed: parsed,
          boundingBox: boundingBox,
          imageData: imageBytes,
          rawBytes: rawBytes,
        ));
      }
    } catch (e) {
      debugPrint('AR ZXing error: $e');
    } finally {
      // 確保臨時檔案被清除
      tempFile?.delete().ignore();
    }

    return codes;
  }

  /// Convert ZXing Format (int) to mobile_scanner format
  ms.BarcodeFormat _zxingFormatToMsFormat(int? format) {
    if (format == null) return ms.BarcodeFormat.unknown;
    return switch (format) {
      zxing.Format.qrCode => ms.BarcodeFormat.qrCode,
      zxing.Format.dataMatrix => ms.BarcodeFormat.dataMatrix,
      zxing.Format.pdf417 => ms.BarcodeFormat.pdf417,
      zxing.Format.aztec => ms.BarcodeFormat.aztec,
      zxing.Format.ean13 => ms.BarcodeFormat.ean13,
      zxing.Format.ean8 => ms.BarcodeFormat.ean8,
      zxing.Format.upca => ms.BarcodeFormat.upcA,
      zxing.Format.upce => ms.BarcodeFormat.upcE,
      zxing.Format.code128 => ms.BarcodeFormat.code128,
      zxing.Format.code39 => ms.BarcodeFormat.code39,
      zxing.Format.itf => ms.BarcodeFormat.itf,
      zxing.Format.codabar => ms.BarcodeFormat.codabar,
      zxing.Format.code93 => ms.BarcodeFormat.code93,
      _ => ms.BarcodeFormat.unknown,
    };
  }

  Future<void> _handleAction(DetectedCode code, ScanAction action) async {
    switch (action) {
      case ScanAction.copy:
        await Clipboard.setData(ClipboardData(text: code.parsed.rawValue));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppText.copied)),
          );
        }
        break;

      case ScanAction.open:
        if (code.parsed.semanticType == SemanticType.url) {
          await _openUrl(code.parsed.rawValue);
        } else if (code.parsed.semanticType == SemanticType.email) {
          final uri = Uri.parse('mailto:${code.parsed.displayText}');
          await launchUrl(uri);
        } else if (code.parsed.semanticType == SemanticType.sms) {
          final number = code.parsed.metadata?['number'] ?? code.parsed.displayText;
          final body = code.parsed.metadata?['body'] ?? '';
          final uri = Uri.parse('sms:$number?body=$body');
          await launchUrl(uri);
        }
        break;

      case ScanAction.save:
        await _saveCode(code);
        break;

      case ScanAction.share:
        await SharePlus.instance.share(ShareParams(text: code.parsed.rawValue));
        break;

      case ScanAction.search:
        String searchUrl;
        if (code.parsed.semanticType == SemanticType.isbn) {
          // For ISBN, search with ISBN prefix
          searchUrl =
              'https://www.google.com/search?q=ISBN+${Uri.encodeComponent(code.parsed.rawValue)}';
        } else {
          // For text/vcard/geo, search the content directly
          searchUrl =
              'https://www.google.com/search?q=${Uri.encodeComponent(code.parsed.rawValue)}';
        }
        final settings = context.read<SettingsProvider>();
        await UrlLauncherHelper.openUrl(
          searchUrl,
          useExternalBrowser: settings.useExternalBrowser,
        );
        break;

      case ScanAction.connect:
        // For Wi-Fi
        if (code.parsed.semanticType == SemanticType.wifi) {
          // On most platforms, Wi-Fi connection needs native code
          // For now, just copy the password
          final password = code.parsed.metadata?['password'];
          if (password != null) {
            await Clipboard.setData(ClipboardData(text: password));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${AppText.copied}: WiFi Password')),
              );
            }
          }
        }
        break;
    }
  }

  /// 開啟 URL，根據用戶設定決定使用內建或外部瀏覽器
  /// - 內建：Chrome Custom Tabs (Android) / Safari View Controller (iOS)
  /// - 外部：系統預設瀏覽器（Edge、Firefox 等）
  Future<void> _openUrl(String url) async {
    final settings = context.read<SettingsProvider>();
    await UrlLauncherHelper.openUrl(
      url,
      useExternalBrowser: settings.useExternalBrowser,
    );
  }

  /// 儲存截圖
  /// - 壓縮圖片：最大寬度 800px，JPEG 品質 75%
  Future<String?> _saveScreenshot(Uint8List? imageData) async {
    if (imageData == null) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory(p.join(dir.path, 'screenshots'));
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = p.join(screenshotsDir.path, fileName);

      // 壓縮圖片：限制寬度 800px，JPEG 品質 75%
      final compressedData = await FlutterImageCompress.compressWithList(
        imageData,
        minWidth: 800,
        minHeight: 600,
        quality: 75,
        format: CompressFormat.jpeg,
      );

      final file = File(filePath);
      await file.writeAsBytes(compressedData);
      return file.path;
    } catch (e) {
      debugPrint('Error saving screenshot: $e');
      return null;
    }
  }

  /// Core save logic - builds record with location/image and saves to history
  Future<void> _buildAndSaveRecord(
    DetectedCode code, {
    String? sharedPlaceName,
    String? sharedPlaceSource,
    String? sharedImagePath,
  }) async {
    final settings = context.read<SettingsProvider>();
    final historyProvider = context.read<HistoryProvider>();

    String? placeName = sharedPlaceName;
    String placeSource = sharedPlaceSource ?? 'none';
    String? imagePath = sharedImagePath;

    // Get location if enabled and not provided
    if (placeName == null && settings.saveLocation) {
      final result = await _locationService.getApproximateLocation();
      if (result.isSuccess) {
        placeName = result.placeName;
        placeSource = result.source;
      }
    }

    // Save screenshot if enabled and not provided
    if (imagePath == null && settings.saveImage) {
      imagePath = await _saveScreenshot(code.imageData);
    }

    final record = ScanRecord(
      rawText: code.parsed.rawValue,
      displayText: code.parsed.displayText,
      barcodeFormat: code.parsed.barcodeFormat,
      semanticType: code.parsed.semanticType,
      scannedAt: DateTime.now(),
      placeName: placeName,
      placeSource: placeSource,
      imagePath: imagePath,
    );

    await historyProvider.addRecord(record);

    // Earn CP for scan (silent, no UI feedback)
    await GrowthService.instance.earnScanCp(code.parsed.rawValue);
  }

  Future<void> _saveCode(DetectedCode code, {bool showSnackbar = true}) async {
    await _buildAndSaveRecord(code);

    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.saved)),
      );
    }
  }

  /// Auto-save if not duplicate of recent 10 records
  Future<void> _saveCodeIfNotDuplicate(DetectedCode code) async {
    final historyProvider = context.read<HistoryProvider>();

    // Check if duplicate of recent 10
    final isDuplicate = await historyProvider.isDuplicateOfRecent(
      code.parsed.rawValue,
      limit: 10,
    );
    if (isDuplicate) {
      debugPrint('Skipping duplicate: ${code.parsed.rawValue}');
      return;
    }

    await _buildAndSaveRecord(code);
  }

  Future<void> _saveAllCodes() async {
    if (_detectedCodes.isEmpty) return;
    _isProcessing = true;

    final settings = context.read<SettingsProvider>();
    final historyProvider = context.read<HistoryProvider>();

    // Get location once for all codes
    String? placeName;
    String placeSource = 'none';
    if (settings.saveLocation) {
      final result = await _locationService.getApproximateLocation();
      if (result.isSuccess) {
        placeName = result.placeName;
        placeSource = result.source;
      }
    }

    // Get shared image data (use first code's image)
    final codeWithImage = _detectedCodes.firstWhere(
      (c) => c.imageData != null,
      orElse: () => _detectedCodes.first,
    );

    // 多碼時：所有記錄共享同一張圖
    String? sharedImagePath;
    if (settings.saveImage && codeWithImage.imageData != null) {
      sharedImagePath = await _saveScreenshot(codeWithImage.imageData);
    }

    // Save each code with shared image
    for (final code in _detectedCodes) {
      final isDuplicate = await historyProvider.isDuplicateOfRecent(
        code.parsed.rawValue,
        limit: 10,
      );
      if (isDuplicate) {
        debugPrint('Skipping duplicate: ${code.parsed.rawValue}');
        continue;
      }

      await _buildAndSaveRecord(
        code,
        sharedPlaceName: placeName,
        sharedPlaceSource: placeSource,
        sharedImagePath: sharedImagePath,
      );
    }

    _isProcessing = false;
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await controller.toggleTorch();
      HapticFeedback.lightImpact();
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  /// 切換反相模式（用於掃描深色背景上的淺色條碼）
  /// 不重建 controller，只用 ZXing 掃反相圖
  void _toggleInvertMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _invertMode = !_invertMode;
      // 重置掃描狀態
      _frameAccumulator.clear();
      _parseCache.clear();
      _detectionTimer?.cancel();
      _detectionTimer = null;
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
    });
    debugPrint('Invert mode: $_invertMode (ZXing only)');
  }

  /// 標準模式：ZXing 掃原圖（與 ML Kit 並行）
  Timer? _originalScanTimer;
  bool _originalScanning = false;

  void _processOriginalFrame(Uint8List? imageBytes) {
    if (imageBytes == null || _isPaused || _originalScanning) return;

    // Debounce：每 300ms 最多處理一次
    if (_originalScanTimer?.isActive ?? false) return;
    _originalScanTimer = Timer(const Duration(milliseconds: 300), () {});

    _originalScanning = true;
    _scanOriginalImage(imageBytes).then((_) {
      _originalScanning = false;
    });
  }

  Future<void> _scanOriginalImage(Uint8List imageBytes) async {
    try {
      // 直接用 ZXing 掃描原圖
      final codes = await _scanWithZXing(imageBytes);

      if (!mounted || codes.isEmpty || _isPaused) return;

      final settings = context.read<SettingsProvider>();

      // 播放聲音和震動
      if (settings.sound) {
        _playBeep();
      }
      if (settings.vibration) {
        HapticFeedback.mediumImpact();
      }

      // 暫停相機，保留背景
      _pauseWithBackground(imageBytes);

      // 連續掃描模式
      if (settings.continuousScanMode) {
        _handleContinuousScan(codes);
        return;
      }

      setState(() {
        _detectedCodes = codes;
      });

      // 顯示結果
      if (codes.length == 1) {
        _showSingleResult(codes.first);
      } else {
        _showMultiCodeSheet();
      }
    } catch (e) {
      debugPrint('Original scan error: $e');
    }
  }

  /// 反相模式：反轉圖片顏色後用 ZXing 掃描
  /// 用於掃描深色背景上的淺色條碼（如黑底白字）
  Timer? _invertScanTimer;
  bool _invertScanning = false;

  void _processInvertedFrame(Uint8List? imageBytes) {
    if (imageBytes == null || _isPaused || _invertScanning) return;

    // Debounce：每 300ms 最多處理一次
    if (_invertScanTimer?.isActive ?? false) return;
    _invertScanTimer = Timer(const Duration(milliseconds: 300), () {});

    _invertScanning = true;
    _scanInvertedImage(imageBytes).then((_) {
      _invertScanning = false;
    });
  }

  Future<void> _scanInvertedImage(Uint8List imageBytes) async {
    try {
      // 反相圖片
      final invertedBytes = InvertedBarcodeHelper.invertImage(imageBytes);
      if (invertedBytes == null) return;

      // 用 ZXing 掃描反相後的圖片
      final codes = await _scanWithZXing(invertedBytes);

      if (!mounted || codes.isEmpty) return;

      final settings = context.read<SettingsProvider>();

      // 播放聲音和震動
      if (settings.sound) {
        _playBeep();
      }
      if (settings.vibration) {
        HapticFeedback.mediumImpact();
      }

      // 暫停相機，保留背景
      _pauseWithBackground(imageBytes); // 用原圖當背景（不是反相圖）

      // 連續掃描模式
      if (settings.continuousScanMode) {
        _handleContinuousScan(codes);
        return;
      }

      setState(() {
        _detectedCodes = codes;
      });

      // 顯示結果
      if (codes.length == 1) {
        _showSingleResult(codes.first);
      } else {
        _showMultiCodeSheet();
      }
    } catch (e) {
      debugPrint('Invert scan error: $e');
    }
  }

  /// 重新觸發相機對焦（對焦到畫面中央）
  Future<void> _triggerFocus() async {
    await _setFocusPoint(const Offset(0.5, 0.5));
  }

  /// 設定對焦點（座標 0.0-1.0）
  /// 包含設備能力檢測，低端設備會自動禁用
  Future<void> _setFocusPoint(Offset point) async {
    final controller = _controller;
    if (controller == null || _isPaused || !_focusSupported) return;

    try {
      HapticFeedback.lightImpact();
      await controller.setFocusPoint(point);
    } catch (e) {
      debugPrint('Focus not supported on this device: $e');
      // 標記此設備不支持對焦功能
      setState(() => _focusSupported = false);
    }
  }

  /// 處理點擊對焦（將螢幕座標轉換為正規化座標）
  Future<void> _handleTapToFocus(TapDownDetails details, Size screenSize) async {
    if (!_focusSupported) return;

    final relativeX = details.localPosition.dx / screenSize.width;
    final relativeY = details.localPosition.dy / screenSize.height;

    await _setFocusPoint(Offset(
      relativeX.clamp(0.0, 1.0),
      relativeY.clamp(0.0, 1.0),
    ));
  }

  Future<void> _pickFromGallery() async {
    final controller = _controller;
    if (controller == null) return;

    // 標記正在選擇照片，避免相機在背景啟動
    setState(() => _isPickingImage = true);
    controller.stop();

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        // User cancelled - 回到相機模式
        setState(() => _isPickingImage = false);
        controller.start();
        return;
      }

      // 讀取圖片
      final imageBytes = await File(image.path).readAsBytes();

      // 獲取圖片尺寸
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;
      final imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      // 進入照片模式
      setState(() {
        _isPickingImage = false;
        _galleryMode = true;
        _galleryImage = imageBytes;
        _galleryImageSize = imageSize;
        _galleryImagePath = image.path;
      });
      widget.onGalleryModeChanged?.call(true);
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.error)),
        );
      }
      _exitGalleryMode();
    }
  }

  /// 退出照片模式，重新打開相簿讓用戶選另一張
  void _exitGalleryMode() {
    // 確保相機停止（不要在背景跑）
    _controller?.stop();

    setState(() {
      _isPickingImage = true;  // 標記正在選擇照片，避免相機啟動
      _galleryMode = false;
      _galleryImage = null;
      _galleryImageSize = null;
      _galleryImagePath = null;
    });
    widget.onGalleryModeChanged?.call(false);
    // 重新打開相簿選擇器
    _pickFromGallery();
  }

  @override
  Widget build(BuildContext context) {
    // 正在選擇照片，顯示黑屏（避免相機在背景跑）
    if (_isPickingImage) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    // 照片模式
    if (_galleryMode && _galleryImage != null && _galleryImageSize != null && _galleryImagePath != null) {
      return ScanGalleryMode(
        imageBytes: _galleryImage!,
        imagePath: _galleryImagePath!,
        imageSize: _galleryImageSize!,
        parser: _parser,
        onExit: _exitGalleryMode,
        onAction: _handleAction,
        onSaveCode: _saveCodeIfNotDuplicate,
        onPlayBeep: _playBeep,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview with pinch-to-zoom and tap-to-focus
          if (_controller != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  // 阻止 PageView 響應，讓縮放手勢優先
                  behavior: HitTestBehavior.opaque,
                  // 點擊對焦
                  onTapDown: _isPaused ? null : (details) {
                    _handleTapToFocus(details, screenSize);
                  },
                  onScaleStart: (details) {
                    // 兩指時標記，阻止 PageView
                    if (details.pointerCount >= 2) {
                      _pointerCount = details.pointerCount;
                    }
                  },
                  onScaleUpdate: (details) {
                    // 兩指縮放功能暫時屏蔽 - 目前掃描品質已足夠好
                  },
                  onScaleEnd: (_) => _pointerCount = 0,
                  // 吸收水平拖動，避免觸發 PageView
                  onHorizontalDragStart: _pointerCount >= 2 ? (_) {} : null,
                  onHorizontalDragUpdate: _pointerCount >= 2 ? (_) {} : null,
                  child: RepaintBoundary(
                    key: _cameraKey,
                    child: _controller == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : ms.MobileScanner(
                            controller: _controller!,
                            fit: BoxFit.cover,
                            onDetect: _onDetect,
                            errorBuilder: (context, error) {
                              return _buildCameraError(error);
                            },
                          ),
                  ),
                );
              },
            ),

          // Paused background image (shows last frame when scanner is stopped)
          if (_isPaused && _pausedBackgroundImage != null)
            Positioned.fill(
              child: Image.memory(
                _pausedBackgroundImage!,
                fit: BoxFit.cover,
                gaplessPlayback: true, // Prevent flicker
              ),
            ),

          // Continuous scan counter
          if (context.watch<SettingsProvider>().continuousScanMode && _continuousScanCount > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: ContinuousScanCounter(
                count: _continuousScanCount,
                onClear: () => setState(() => _continuousScanCount = 0),
              ),
            ),

          // 暫停時顯示「發現 X 個」（點擊可查看全部）
          if (_isPaused && _detectedCodes.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: SingleModeResultBar(
                count: _detectedCodes.length,
                onViewResults: () {
                  if (_detectedCodes.length == 1) {
                    _showSingleResult(_detectedCodes.first);
                  } else {
                    _showMultiCodeSheet();
                  }
                },
                onRescan: _resumeScanning,
              ),
            ),

          // Bottom toolbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ScanBottomToolbar(
              onGalleryTap: _pickFromGallery,
              onTorchTap: _toggleTorch,
              onInvertModeTap: _toggleInvertMode,
              isTorchOn: _torchOn,
              isInvertModeActive: _invertMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError(ms.MobileScannerException error) {
    String message;
    bool showSettingsButton = false;

    switch (error.errorCode) {
      case ms.MobileScannerErrorCode.permissionDenied:
        message = AppText.cameraPermissionMessage;
        showSettingsButton = true;
        break;
      case ms.MobileScannerErrorCode.controllerDisposed:
      case ms.MobileScannerErrorCode.controllerUninitialized:
        message = 'Camera initialization error';
        break;
      default:
        message = error.errorDetails?.message ?? 'Camera error';
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                AppText.cameraPermissionDenied,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (showSettingsButton) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    // Open app settings
                    final uri = Uri.parse('app-settings:');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: Text(AppText.openSettings),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
