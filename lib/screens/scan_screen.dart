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
import '../utils/image_annotator.dart';

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
  Size? _previewSize;
  bool _controllerInitialized = false;
  bool _controllerReturnImage = false; // Track current returnImage setting

  // Multi-code scan mode
  bool _multiCodeMode = false;
  final Map<String, DetectedCode> _multiCodeBuffer = {};

  // Multi-frame accumulation for better detection
  final Map<String, AccumulatedCode> _frameAccumulator = {};
  final Map<String, ParsedBarcode> _parseCache = {}; // Parse Cache 避免重複解析
  Timer? _accumulationTimer;
  static const int _defaultFrameCount = 1; // 預設閾值（降低以提高識別率）
  static const int _maxFrameCount = 10; // frameCount 上限，避免無限增長
  static const Duration _accumulationWindow = Duration(milliseconds: 1000); // 累積 1 秒後停止
  static const Duration _extendedAccumulationWindow = Duration(milliseconds: 2000); // 重掃時使用 2 秒

  // Continuous scan mode
  int _continuousScanCount = 0;
  final Set<String> _recentlyScanned = {};
  Timer? _recentlyClearTimer;

  // Paused background image (to show last frame when scanner is stopped)
  Uint8List? _pausedBackgroundImage;

  // AR mode: currently selected code for inline result display
  DetectedCode? _arSelectedCode;

  // AR 模式：垂直平移偏移量（只允許向上，即負值）
  double _arVerticalOffset = 0.0;

  // AR 模式：是否使用延長的累積時間（重掃時為 true）
  bool _useExtendedAccumulationTime = false;

  // 多點觸摸追蹤（用於阻止 PageView 滑動）
  int _pointerCount = 0;

  // 照片模式
  bool _galleryMode = false;
  Uint8List? _galleryImage;
  Size? _galleryImageSize;
  String? _galleryImagePath;

  // 對焦功能
  bool _focusSupported = true; // 假設支持，失敗時設為 false

  // 解析度模式：0=FHD(1920x1080), 1=2K(2560x1440), 2=4K(3840x2160)
  int _resolutionMode = 0;
  static const List<Size> _resolutions = [
    Size(1920, 1080),  // FHD
    Size(2560, 1440),  // 2K
    Size(3840, 2160),  // 4K
  ];
  static const List<String> _resolutionLabels = ['FHD', '2K', '4K'];

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
      cameraResolution: _resolutions[_resolutionMode],
      returnImage: returnImage,
    );
    // Manually start if tab is active (autoStart removed in v7.x)
    if (widget.isActive) {
      _controller?.start();
    }
  }

  /// 切換解析度模式 (FHD → 2K → 4K → FHD)
  Future<void> _cycleResolution() async {
    if (!mounted) return;

    final nextMode = (_resolutionMode + 1) % _resolutions.length;

    // 先停止並釋放舊的 controller
    final oldController = _controller;
    _controller = null;

    // 先更新 UI，讓 MobileScanner 知道 controller 變了
    setState(() {
      _resolutionMode = nextMode;
    });

    await oldController?.stop();
    await oldController?.dispose();

    // 等待一下確保資源完全釋放
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // 重建 controller
    _initController(returnImage: _controllerReturnImage);

    // 觸發重建
    setState(() {});
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
      _accumulationTimer?.cancel();
      _multiCodeBuffer.clear();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _recentlyClearTimer?.cancel();
    _accumulationTimer?.cancel();
    _controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onDetect(ms.BarcodeCapture capture) {
    if (_isPaused || _isProcessing) return;

    try {
      final barcodes = capture.barcodes;
      if (barcodes.isEmpty) return;

      // Get preview size for AR overlay
      _previewSize = capture.size;

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

      final key = barcode.rawValue!;

      // AR Mode 下已收集到 buffer 的碼，跳過處理
      if (_multiCodeMode && _multiCodeBuffer.containsKey(key)) continue;

      // Parse Cache: 同一 rawValue 只解析一次
      final parsed = _parseCache.putIfAbsent(
        key,
        () => _parser.parse(rawValue: barcode.rawValue!, format: barcode.format),
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
          ),
          lastSeen: now,
        );
      }
    }

    // 即時更新 AR overlay
    _updateDetectedCodesFromAccumulator();

    // AR Mode: 根據設定使用 1 秒或 2 秒後固定背景，讓用戶點選碼
    if (_multiCodeMode) {
      // 把穩定的碼加入 buffer
      final stableCodes = _frameAccumulator.entries
          .where((e) => e.value.frameCount >= _defaultFrameCount)
          .toList();
      for (final entry in stableCodes) {
        if (!_multiCodeBuffer.containsKey(entry.key)) {
          _multiCodeBuffer[entry.key] = entry.value.code;
        }
      }

      // 根據是否重掃決定累積時間（1 秒或 2 秒）
      final window = _useExtendedAccumulationTime
          ? _extendedAccumulationWindow
          : _accumulationWindow;
      _accumulationTimer ??= Timer(window, () {
        _accumulationTimer = null;
        _pauseArModeWithBackground();
      });
      return;
    }

    // Single Mode: 1 秒後停止掃描，顯示結果讓用戶選擇
    _accumulationTimer ??= Timer(_accumulationWindow, () {
      _accumulationTimer = null;
      _stopAndShowResults();
    });
  }

  void _updateDetectedCodesFromAccumulator() {
    // 顯示所有累積的碼，包含幀數資訊
    final newCodes = _frameAccumulator.values
        .map((acc) => acc.code.copyWith(frameCount: acc.frameCount))
        .toList();

    // 方案 B: 只在碼列表實際變化時 setState
    final oldKeys = _detectedCodes.map((c) => c.parsed.rawValue).toSet();
    final newKeys = newCodes.map((c) => c.parsed.rawValue).toSet();
    final hasNewStableCode = newCodes.any((c) =>
        c.frameCount == _defaultFrameCount &&
        !_detectedCodes.any((old) =>
            old.parsed.rawValue == c.parsed.rawValue &&
            old.frameCount >= _defaultFrameCount));

    // 只在以下情況 setState：
    // 1. 碼列表 key 變化（新增或移除）
    // 2. 有碼剛達到穩定閾值
    if (!_setEquals(oldKeys, newKeys) || hasNewStableCode) {
      // 掃到穩定碼時給震動（聲音留給結果顯示）
      if (hasNewStableCode) {
        final settings = context.read<SettingsProvider>();
        if (settings.vibration) {
          HapticFeedback.mediumImpact();
        }
      }
      setState(() {
        _detectedCodes = newCodes;
      });
    }
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  /// Single Mode: 累積後直接顯示結果
  void _stopAndShowResults() {
    // 避免競態條件：如果已暫停、正在處理、在 AR 模式、或 widget 已卸載，直接返回
    if (_isPaused || _isProcessing || _multiCodeMode || !mounted) return;

    // 過濾出穩定偵測到的碼（至少 N 幀）
    final stableCodes = _frameAccumulator.entries
        .where((e) => e.value.frameCount >= _defaultFrameCount)
        .map((e) => e.value.code)
        .toList();

    if (stableCodes.isEmpty) {
      // 沒有穩定的碼，繼續掃描
      _frameAccumulator.clear();
      _parseCache.clear();
      setState(() {
        _detectedCodes = [];
      });
      return;
    }

    final settings = context.read<SettingsProvider>();

    // 連續掃描模式：自動儲存並繼續掃描（不顯示結果）
    if (settings.continuousScanMode) {
      _handleContinuousScan(stableCodes);
      return;
    }

    // 結果顯示時只給聲音（震動在掃到時已給）
    if (settings.sound) {
      _playBeep();
    }

    // 停止掃描，保留背景影像
    _pauseWithBackground(stableCodes.first.imageData);

    setState(() {
      _detectedCodes = stableCodes;
    });

    // 直接顯示結果
    if (stableCodes.length == 1) {
      _showSingleResult(stableCodes.first);
    } else {
      _showMultiCodeSheet();
    }
  }

  void _toggleMultiCodeMode() {
    // If paused, resume scanning first
    // 切換模式時重置所有狀態
    _isPaused = false;
    _pausedBackgroundImage = null;
    _detectedCodes = [];
    _frameAccumulator.clear();
    _parseCache.clear();
    _accumulationTimer?.cancel();
    _accumulationTimer = null; // 確保 Timer 完全清除
    _multiCodeBuffer.clear();
    _arSelectedCode = null;
    _arVerticalOffset = 0.0; // 重置垂直偏移
    _torchOn = false; // 重置手電筒狀態
    _useExtendedAccumulationTime = false; // 重置延長時間標記

    // 無條件重新啟動相機（避免狀態不一致導致黑屏）
    _controller?.start();

    setState(() {
      _multiCodeMode = !_multiCodeMode;
    });
  }

  void _confirmMultiCodeScan() {
    if (_multiCodeBuffer.isEmpty) return;

    final codes = _multiCodeBuffer.values.toList();
    _pauseWithBackground(codes.first.imageData);

    if (codes.length == 1) {
      _showSingleResult(codes.first);
    } else {
      _showMultiCodeSheet();
    }
  }

  void _clearMultiCodeBuffer() {
    setState(() {
      _multiCodeBuffer.clear();
      _detectedCodes = [];
    });
  }

  /// AR 模式重掃：使用延長的 2 秒累積時間，清除舊結果重新偵測
  void _rescanArMode() {
    if (!_multiCodeMode) return;

    // 設為延長時間模式（本次 AR session 內維持）
    _useExtendedAccumulationTime = true;

    // 清除所有狀態，重新掃描
    _isPaused = false;
    _pausedBackgroundImage = null;
    _frameAccumulator.clear();
    _parseCache.clear();
    _accumulationTimer?.cancel();
    _accumulationTimer = null;
    _arSelectedCode = null;
    _torchOn = false; // 相機重啟後手電筒會關閉

    // 重新啟動相機
    _controller?.start();

    setState(() {
      _multiCodeBuffer.clear(); // 清除之前的結果（讓「發現 X 個」歸零）
      _detectedCodes = []; // 清除 AR overlay 顯示
    });
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

  /// AR Mode: 選擇碼並顯示 inline 結果卡片（可切換）
  void _selectArCode(DetectedCode code) async {
    // 智能對焦到選中的 barcode（可能改善截圖品質）
    await _focusOnBarcode(code);

    // 固定背景
    _pauseWithBackground(code.imageData);

    // 自動儲存
    await _saveCodeIfNotDuplicate(code);

    if (!mounted) return;

    // 播放聲音
    final settings = context.read<SettingsProvider>();
    if (settings.sound) {
      _playBeep();
    }

    setState(() {
      _arSelectedCode = code;
    });
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
      // 先取消 Timer 避免競態條件
      _accumulationTimer?.cancel();
      _accumulationTimer = null;

      setState(() {
        _isPaused = false;
        _pausedBackgroundImage = null; // Clear background image
        _detectedCodes = [];
        _arVerticalOffset = 0.0; // 重置 AR 模式垂直偏移
        _torchOn = false; // 重置手電筒狀態（相機重啟後手電筒會關閉）
        _useExtendedAccumulationTime = false; // 離開本次 AR session，重置為 1 秒
        // Clear accumulators when resuming
        _frameAccumulator.clear();
        _parseCache.clear(); // 新掃描週期清空 Parse Cache
        // Clear multi-code buffer when resuming
        if (_multiCodeMode) {
          _multiCodeBuffer.clear();
        }
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

  /// AR Mode: 時間到後固定背景（抓最後一幀）+ ZXing 補掃
  Future<void> _pauseArModeWithBackground() async {
    // 避免競態條件：如果已暫停、不在 AR 模式、或 widget 已卸載，直接返回
    if (_isPaused || !_multiCodeMode || !mounted) return;

    // 取第一個穩定碼的圖片作為背景
    final stableCode = _multiCodeBuffer.values.firstOrNull;
    final imageData = stableCode?.imageData;
    _pauseWithBackground(imageData);

    // 用 ZXing 補掃背景圖片（MIG 4.0 發票 ML Kit 掃不出來）
    if (imageData != null) {
      final zxingCodes = await _scanWithZXing(imageData);

      // 合併結果：ZXing 優先（Big5 解碼更準確）
      for (final code in zxingCodes) {
        _multiCodeBuffer[code.parsed.rawValue] = code;
      }
    }

    if (!mounted) return;

    // 更新 detectedCodes 為 buffer 中的穩定碼
    setState(() {
      _detectedCodes = _multiCodeBuffer.values.toList();
    });
  }

  /// AR Mode: ZXing 掃描背景圖片
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

        // 跳過 ML Kit 已掃到的（避免重複）
        if (_multiCodeBuffer.containsKey(code.text)) continue;

        final rawBytes = code.rawBytes;

        // 檢查是否為台灣電子發票，用 Big5 解碼
        String rawValue = code.text!;
        if (TaiwanInvoiceDecoder.isTaiwanInvoice(rawValue, rawBytes)) {
          rawValue = TaiwanInvoiceDecoder.getDecodedText(rawBytes, rawValue);
          debugPrint('AR ZXing: 台灣發票 Big5 解碼');
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

  /// 標註並儲存截圖
  /// - 在圖片上添加圓形字母標籤（A/B/C/D）標示每個碼的位置
  /// - 壓縮圖片：最大寬度 800px，JPEG 品質 75%
  Future<String?> _saveScreenshot(
    Uint8List? imageData, {
    List<Rect?>? allBoundingBoxes,
    Size? previewSize,
  }) async {
    if (imageData == null) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory(p.join(dir.path, 'screenshots'));
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = p.join(screenshotsDir.path, fileName);

      // 1. 添加圓形字母標籤（A/B/C/D）
      final annotatedData = await ImageAnnotator.annotateImage(
        imageData,
        allBoundingBoxes ?? [],
        previewSize,
      );

      // 2. 壓縮圖片：限制寬度 800px，JPEG 品質 75%
      final compressedData = await FlutterImageCompress.compressWithList(
        annotatedData,
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
    String? codeLetter,
    List<Rect?>? allBoundingBoxes,
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
    // 多碼時：標註所有碼的位置（A/B/C/D）
    // 單碼時：不標註字母
    if (imagePath == null && settings.saveImage) {
      imagePath = await _saveScreenshot(
        code.imageData,
        allBoundingBoxes: allBoundingBoxes ?? [code.boundingBox],
        previewSize: _previewSize,
      );
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
      codeLetter: codeLetter,
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

    // Collect all bounding boxes for annotation
    final allBoundingBoxes = _detectedCodes.map((c) => c.boundingBox).toList();
    final isMultiCode = _detectedCodes.length > 1;

    // Get shared image data (use first code's image)
    final codeWithImage = _detectedCodes.firstWhere(
      (c) => c.imageData != null,
      orElse: () => _detectedCodes.first,
    );

    // 多碼時：只保存一張圖，標註所有碼的位置（A/B/C/D）
    // 所有記錄共享這張圖，用 codeLetter 區分
    String? sharedImagePath;
    if (settings.saveImage && codeWithImage.imageData != null) {
      sharedImagePath = await _saveScreenshot(
        codeWithImage.imageData,
        allBoundingBoxes: isMultiCode ? allBoundingBoxes : null,
        previewSize: _previewSize,
      );
    }

    // Save each code with shared image
    for (int i = 0; i < _detectedCodes.length; i++) {
      final code = _detectedCodes[i];
      final isDuplicate = await historyProvider.isDuplicateOfRecent(
        code.parsed.rawValue,
        limit: 10,
      );
      if (isDuplicate) {
        debugPrint('Skipping duplicate: ${code.parsed.rawValue}');
        continue;
      }

      // Assign letter only for multi-code scans
      final codeLetter = isMultiCode ? ImageAnnotator.getLetter(i) : null;

      // All codes share the same annotated image
      await _buildAndSaveRecord(
        code,
        sharedPlaceName: placeName,
        sharedPlaceSource: placeSource,
        sharedImagePath: sharedImagePath,
        codeLetter: codeLetter,
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

  /// 智能對焦：對焦到偵測到的 barcode 區域
  Future<void> _focusOnBarcode(DetectedCode code) async {
    if (code.boundingBox == null || _previewSize == null) return;

    final box = code.boundingBox!;
    final centerX = (box.left + box.width / 2) / _previewSize!.width;
    final centerY = (box.top + box.height / 2) / _previewSize!.height;

    await _setFocusPoint(Offset(
      centerX.clamp(0.0, 1.0),
      centerY.clamp(0.0, 1.0),
    ));
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

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        // User cancelled - ensure scanner is running
        controller.start();
        return;
      }

      // 停止相機
      controller.stop();

      // 讀取圖片
      final imageBytes = await File(image.path).readAsBytes();

      // 獲取圖片尺寸
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;
      final imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      // 進入照片模式
      setState(() {
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

  /// 退出照片模式
  void _exitGalleryMode() {
    setState(() {
      _galleryMode = false;
      _galleryImage = null;
      _galleryImageSize = null;
      _galleryImagePath = null;
    });
    widget.onGalleryModeChanged?.call(false);
    _resumeScanning();
  }

  @override
  Widget build(BuildContext context) {
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
                  // 點擊對焦（非 AR 模式，或 AR 模式下點擊非 barcode 區域）
                  onTapDown: _isPaused ? null : (details) {
                    // AR 模式下，檢查是否點擊到 barcode 區域（由 AR overlay 處理）
                    if (_multiCodeMode && _detectedCodes.isNotEmpty && _previewSize != null) {
                      for (final code in _detectedCodes) {
                        if (code.boundingBox != null) {
                          final scaledBox = scaleRect(code.boundingBox!, _previewSize!, screenSize);
                          // 擴大點擊區域（包含 overlay）
                          final hitBox = scaledBox.inflate(50);
                          if (hitBox.contains(details.localPosition)) {
                            return; // 讓 AR overlay 處理
                          }
                        }
                      }
                    }
                    // 點擊空白處對焦
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
          // AR 模式下支持向上拖動
          if (_isPaused && _pausedBackgroundImage != null)
            Positioned.fill(
              child: GestureDetector(
                onVerticalDragUpdate: _multiCodeMode ? (details) {
                  setState(() {
                    // 只允許向上拖動（負值），限制最大偏移量
                    final newOffset = _arVerticalOffset + details.delta.dy;
                    _arVerticalOffset = newOffset.clamp(-300.0, 0.0);
                  });
                } : null,
                child: Transform.translate(
                  offset: Offset(0, _arVerticalOffset),
                  child: Image.memory(
                    _pausedBackgroundImage!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true, // Prevent flicker
                  ),
                ),
              ),
            ),

          // AR Overlay: 只在 AR Mode 時顯示（跟隨垂直偏移）
          if (_multiCodeMode && _detectedCodes.isNotEmpty && _previewSize != null)
            Transform.translate(
              offset: Offset(0, _arVerticalOffset),
              child: ScanArOverlay(
                detectedCodes: _detectedCodes,
                previewSize: _previewSize!,
                stableFrameCount: _defaultFrameCount,
                onCodeTap: _selectArCode,
              ),
            ),

          // 解析度切換按鈕（左下角，toolbar 上方）
          Positioned(
            bottom: 100 + MediaQuery.of(context).padding.bottom,
            left: 16,
            child: GestureDetector(
              onTap: _cycleResolution,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _resolutionMode > 0
                      ? Colors.amber.withAlpha(230)
                      : Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.high_quality,
                      color: _resolutionMode > 0 ? Colors.black : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _resolutionLabels[_resolutionMode],
                      style: TextStyle(
                        color: _resolutionMode > 0 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Multi-code mode indicator
          if (_multiCodeMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: MultiCodeModeIndicator(
                count: _multiCodeBuffer.length,
                onClear: _clearMultiCodeBuffer,
              ),
            ),

          // Continuous scan counter
          if (!_multiCodeMode && context.watch<SettingsProvider>().continuousScanMode && _continuousScanCount > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: ContinuousScanCounter(
                count: _continuousScanCount,
                onClear: () => setState(() => _continuousScanCount = 0),
              ),
            ),

          // Multi-code confirm bar (when in multi-code mode and has codes, but no selected code)
          if (_multiCodeMode && _multiCodeBuffer.isNotEmpty && _arSelectedCode == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: MultiCodeConfirmBar(
                count: _multiCodeBuffer.length,
                onConfirm: _confirmMultiCodeScan,
                onRescan: _rescanArMode,
                isExtendedScan: _useExtendedAccumulationTime,
              ),
            ),

          // AR Mode: 選中碼的結果卡片（不加遮罩，讓 AR overlay 可點擊切換）
          if (_multiCodeMode && _arSelectedCode != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ScanArResultCard(
                code: _arSelectedCode!,
                showThumbnail: context.read<SettingsProvider>().saveImage,
                onClose: () {
                  setState(() => _arSelectedCode = null);
                  _resumeScanning();
                },
                onAction: _handleAction,
              ),
            ),

          // Single Mode 暫停時顯示「發現 X 個」（點擊可查看全部）
          if (!_multiCodeMode && _isPaused && _detectedCodes.isNotEmpty)
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

          // Bottom toolbar（AR 結果卡片顯示時隱藏）
          if (!(_multiCodeMode && _arSelectedCode != null))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ScanBottomToolbar(
                onGalleryTap: _pickFromGallery,
                onTorchTap: _toggleTorch,
                onArModeTap: _toggleMultiCodeMode,
                isTorchOn: _torchOn,
                isArModeActive: _multiCodeMode,
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
