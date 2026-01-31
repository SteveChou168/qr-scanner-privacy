# QR Scanner 技术架构规划

> 基于 tpml_app 架构设计，对应 PDR 需求

---

## 一、项目概览

| 项目 | 内容 |
|------|------|
| **名称** | Offline-First QR/Barcode Scanner |
| **定位** | 轻量、快速、隐私友善的掃描工具 |
| **框架** | Flutter (Dart 3.0+) |
| **平台** | Android (Priority), iOS (Secondary) |
| **架构** | 分层架构 + Provider 状态管理 |

---

## 二、系统架构图

```
┌──────────────────────────────────────────────────────────┐
│                    UI Layer (screens/)                    │
│  ┌────────────┬────────────┬────────────┬─────────────┐  │
│  │ScanScreen  │HistoryScreen│WebViewScreen│SettingsScreen│ │
│  │(主扫描页)   │(扫描历史)   │(内嵌浏览器) │(设置页)      │  │
│  └────────────┴────────────┴────────────┴─────────────┘  │
├──────────────────────────────────────────────────────────┤
│                  Widgets Layer (widgets/)                 │
│  ┌────────────┬────────────┬────────────┬─────────────┐  │
│  │AROverlay   │ScanResult  │AdBanner    │TypeIcon     │  │
│  │(AR浮层)    │Card(结果卡) │(广告横幅)  │(类型图标)   │  │
│  └────────────┴────────────┴────────────┴─────────────┘  │
├──────────────────────────────────────────────────────────┤
│               State Management (providers/)               │
│  ┌────────────┬────────────┬────────────┬─────────────┐  │
│  │ScanProvider│HistoryProvider│SettingsProvider│AdProvider│ │
│  └────────────┴────────────┴────────────┴─────────────┘  │
├──────────────────────────────────────────────────────────┤
│                 Services Layer (services/)                │
│  ┌────────────┬────────────┬────────────┬─────────────┐  │
│  │ScanService │OCRService  │LocationSvc │ExportService│  │
│  │(扫描核心)  │(OCR补救)   │(地点服务)  │(CSV导出)    │  │
│  └────────────┴────────────┴────────────┴─────────────┘  │
├──────────────────────────────────────────────────────────┤
│                    Data Layer (data/)                     │
│  ┌────────────┬────────────┬────────────┬─────────────┐  │
│  │Database    │Models      │Repositories│Preferences  │  │
│  │(SQLite)    │(数据模型)  │(数据仓库)  │(轻量存储)   │  │
│  └────────────┴────────────┴────────────┴─────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 三、目录结构设计

```
lib/
├── main.dart                      # App入口
├── app.dart                       # MaterialApp配置
├── app_theme.dart                 # 主题配置
├── app_constants.dart             # 常量定义
│
├── data/                          # 数据层
│   ├── database/
│   │   ├── database_helper.dart   # SQLite管理器 (~800行)
│   │   ├── migrations/            # 数据库迁移
│   │   │   └── migrations.dart
│   │   └── tables.dart            # 表结构常量
│   │
│   ├── models/                    # 数据模型
│   │   ├── scan_record.dart       # 扫描记录
│   │   ├── scan_type.dart         # 扫描类型枚举
│   │   └── action_type.dart       # 行为类型枚举
│   │
│   ├── repositories/              # 数据仓库
│   │   ├── history_repository.dart
│   │   └── settings_repository.dart
│   │
│   └── preferences/               # SharedPreferences
│       └── app_preferences.dart
│
├── services/                      # 服务层
│   ├── scan_service.dart          # 扫描核心服务 (~400行)
│   ├── ocr_service.dart           # OCR补救服务
│   ├── barcode_parser.dart        # 条码解析 + 语意分类
│   ├── location_service.dart      # 地点服务 (Approximate)
│   ├── image_service.dart         # 图像存储服务
│   ├── export_service.dart        # CSV导出服务 (P2)
│   ├── intent_service.dart        # Intent API服务 (P2)
│   └── ad_service.dart            # 广告服务
│
├── providers/                     # 状态管理
│   ├── scan_provider.dart         # 扫描状态
│   ├── history_provider.dart      # 历史状态
│   ├── settings_provider.dart     # 设置状态
│   └── ad_provider.dart           # 广告状态
│
├── screens/                       # 页面
│   ├── scan_screen.dart           # 主扫描页 (~600行)
│   ├── history_screen.dart        # 历史记录页 (~500行)
│   ├── history_detail_screen.dart # 历史详情页
│   ├── webview_screen.dart        # WebView页 (~300行)
│   └── settings_screen.dart       # 设置页 (~400行)
│
├── widgets/                       # 可复用组件
│   ├── scan/
│   │   ├── camera_preview.dart    # 相机预览
│   │   ├── ar_overlay.dart        # AR浮层覆盖
│   │   ├── scan_result_card.dart  # 扫描结果卡片
│   │   ├── multi_code_list.dart   # 多码列表
│   │   └── zoom_slider.dart       # 缩放滑块
│   │
│   ├── history/
│   │   ├── history_item.dart      # 历史项
│   │   ├── history_filter.dart    # 筛选器
│   │   └── thumbnail_view.dart    # 缩略图
│   │
│   ├── common/
│   │   ├── type_icon.dart         # 类型图标
│   │   ├── ad_banner.dart         # 广告横幅
│   │   └── loading_indicator.dart
│   │
│   └── webview/
│       └── webview_toolbar.dart   # WebView工具栏
│
└── utils/                         # 工具类
    ├── isbn_validator.dart        # ISBN验证
    ├── url_validator.dart         # URL验证
    ├── pattern_matcher.dart       # 模式匹配
    └── permission_helper.dart     # 权限处理

android/
├── app/src/main/
│   ├── AndroidManifest.xml        # 权限声明
│   └── kotlin/.../
│       └── IntentActivity.kt      # Intent接收 (P2)
└── build.gradle.kts
```

---

## 四、数据库设计 (SQLite)

### 4.1 表结构

```sql
-- ============================================
-- 扫描历史表 (核心表)
-- ============================================
CREATE TABLE scan_history (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    raw_text        TEXT NOT NULL,           -- 原始扫描内容
    display_text    TEXT,                    -- 显示文字 (可能经处理)

    -- 类型信息
    barcode_format  TEXT NOT NULL,           -- 条码格式: QR/EAN13/CODE128...
    semantic_type   TEXT NOT NULL,           -- 语意类型: url/email/phone/wifi/isbn/text

    -- 时间与地点
    scanned_at      TEXT NOT NULL,           -- ISO8601 扫描时间
    place_name      TEXT,                    -- 城市/行政区 (可选)
    place_source    TEXT DEFAULT 'none',     -- none/approx

    -- 图像 (可选)
    image_path      TEXT,                    -- 截图路径 (App私有)

    -- 扩展
    tags            TEXT,                    -- 逗号分隔标签
    note            TEXT,                    -- 用户备注
    is_favorite     INTEGER DEFAULT 0,       -- 收藏标记

    -- 索引优化
    created_at      TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_history_scanned_at ON scan_history(scanned_at DESC);
CREATE INDEX idx_history_semantic_type ON scan_history(semantic_type);
CREATE INDEX idx_history_is_favorite ON scan_history(is_favorite);

-- ============================================
-- 设置表 (键值对)
-- ============================================
CREATE TABLE app_settings (
    key     TEXT PRIMARY KEY,
    value   TEXT NOT NULL
);

-- 预设值
INSERT INTO app_settings (key, value) VALUES
    ('save_image', 'false'),          -- 是否保存截图
    ('save_location', 'false'),       -- 是否保存地点
    ('auto_open_url', 'false'),       -- 自动打开URL
    ('vibration', 'true'),            -- 扫描震动
    ('sound', 'true'),                -- 扫描声音
    ('history_limit', '500'),         -- 历史上限
    ('image_limit', '200'),           -- 图像上限
    ('theme_mode', 'system'),         -- system/light/dark
    ('is_premium', 'false');          -- 付费用户

-- ============================================
-- 批次扫描表 (P2 - 付费功能)
-- ============================================
CREATE TABLE batch_scans (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_name      TEXT NOT NULL,
    created_at      TEXT DEFAULT CURRENT_TIMESTAMP,
    item_count      INTEGER DEFAULT 0
);

CREATE TABLE batch_scan_items (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id    INTEGER NOT NULL,
    raw_text    TEXT NOT NULL,
    barcode_format TEXT,
    semantic_type TEXT,
    scanned_at  TEXT NOT NULL,
    FOREIGN KEY (batch_id) REFERENCES batch_scans(id) ON DELETE CASCADE
);

CREATE INDEX idx_batch_items_batch_id ON batch_scan_items(batch_id);
```

### 4.2 数据模型 (Dart)

```dart
// lib/data/models/scan_record.dart

/// 条码格式枚举
enum BarcodeFormat {
  qrCode,
  dataMatrix,
  pdf417,
  aztec,
  ean13,
  ean8,
  upcA,
  upcE,
  code128,
  code39,
  unknown;

  String get displayName => switch (this) {
    qrCode => 'QR Code',
    dataMatrix => 'Data Matrix',
    pdf417 => 'PDF417',
    aztec => 'Aztec',
    ean13 => 'EAN-13',
    ean8 => 'EAN-8',
    upcA => 'UPC-A',
    upcE => 'UPC-E',
    code128 => 'Code-128',
    code39 => 'Code-39',
    unknown => 'Unknown',
  };
}

/// 语意类型枚举
enum SemanticType {
  url,
  email,
  phone,
  wifi,
  isbn,
  vcard,
  geo,
  sms,
  text;

  String get icon => switch (this) {
    url => '🔗',
    email => '✉️',
    phone => '📞',
    wifi => '📶',
    isbn => '📚',
    vcard => '👤',
    geo => '📍',
    sms => '💬',
    text => '📝',
  };

  String get label => switch (this) {
    url => 'URL',
    email => 'Email',
    phone => 'Phone',
    wifi => 'Wi-Fi',
    isbn => 'ISBN',
    vcard => 'Contact',
    geo => 'Location',
    sms => 'SMS',
    text => 'Text',
  };
}

/// 扫描记录模型
class ScanRecord {
  final int? id;
  final String rawText;
  final String? displayText;
  final BarcodeFormat barcodeFormat;
  final SemanticType semanticType;
  final DateTime scannedAt;
  final String? placeName;
  final String placeSource;
  final String? imagePath;
  final List<String> tags;
  final String? note;
  final bool isFavorite;

  const ScanRecord({
    this.id,
    required this.rawText,
    this.displayText,
    required this.barcodeFormat,
    required this.semanticType,
    required this.scannedAt,
    this.placeName,
    this.placeSource = 'none',
    this.imagePath,
    this.tags = const [],
    this.note,
    this.isFavorite = false,
  });

  /// 从数据库Map构建
  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] as int?,
      rawText: map['raw_text'] as String,
      displayText: map['display_text'] as String?,
      barcodeFormat: BarcodeFormat.values.firstWhere(
        (e) => e.name == map['barcode_format'],
        orElse: () => BarcodeFormat.unknown,
      ),
      semanticType: SemanticType.values.firstWhere(
        (e) => e.name == map['semantic_type'],
        orElse: () => SemanticType.text,
      ),
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      placeName: map['place_name'] as String?,
      placeSource: map['place_source'] as String? ?? 'none',
      imagePath: map['image_path'] as String?,
      tags: (map['tags'] as String?)?.split(',') ?? [],
      note: map['note'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }

  /// 转为数据库Map
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'raw_text': rawText,
    'display_text': displayText,
    'barcode_format': barcodeFormat.name,
    'semantic_type': semanticType.name,
    'scanned_at': scannedAt.toIso8601String(),
    'place_name': placeName,
    'place_source': placeSource,
    'image_path': imagePath,
    'tags': tags.join(','),
    'note': note,
    'is_favorite': isFavorite ? 1 : 0,
  };

  /// 用于显示的主标签
  String get primaryLabel {
    // ISBN特殊处理：语意优先
    if (semanticType == SemanticType.isbn) {
      return '书籍 ISBN';
    }
    return semanticType.label;
  }

  /// 用于显示的副标签
  String get secondaryLabel => barcodeFormat.displayName;

  /// 复制并修改
  ScanRecord copyWith({
    int? id,
    String? rawText,
    String? displayText,
    BarcodeFormat? barcodeFormat,
    SemanticType? semanticType,
    DateTime? scannedAt,
    String? placeName,
    String? placeSource,
    String? imagePath,
    List<String>? tags,
    String? note,
    bool? isFavorite,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      displayText: displayText ?? this.displayText,
      barcodeFormat: barcodeFormat ?? this.barcodeFormat,
      semanticType: semanticType ?? this.semanticType,
      scannedAt: scannedAt ?? this.scannedAt,
      placeName: placeName ?? this.placeName,
      placeSource: placeSource ?? this.placeSource,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
```

---

## 五、技术选型

### 5.1 核心依赖

```yaml
# pubspec.yaml
name: qr_scanner
description: Offline-First QR/Barcode Scanner
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

  # ========== 扫描核心 ==========
  mobile_scanner: ^5.1.1           # CameraX + ML Kit 条码扫描
  google_mlkit_text_recognition: ^0.11.0  # OCR文字识别 (Fallback)

  # ========== 数据存储 ==========
  sqflite: ^2.3.0                  # SQLite
  shared_preferences: ^2.2.0       # 轻量配置
  path_provider: ^2.1.1            # 文件路径
  path: ^1.8.0

  # ========== UI组件 ==========
  provider: ^6.1.1                 # 状态管理
  webview_flutter: ^4.4.2          # WebView
  url_launcher: ^6.3.0             # URL打开
  share_plus: ^7.2.1               # 分享功能

  # ========== 位置服务 ==========
  geolocator: ^10.1.0              # GPS定位
  geocoding: ^2.1.1                # 反向地理编码

  # ========== 图像处理 ==========
  flutter_image_compress: ^2.1.0   # 图片压缩

  # ========== 广告 ==========
  google_mobile_ads: ^4.0.0        # Google AdMob

  # ========== 工具 ==========
  intl: ^0.18.0                    # 国际化/日期格式
  csv: ^5.1.1                      # CSV导出 (P2)
  permission_handler: ^11.0.1      # 权限处理

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### 5.2 技术对比 (参考 tpml_app)

| 功能 | tpml_app | QR Scanner | 说明 |
|------|----------|------------|------|
| **扫描** | mobile_scanner | mobile_scanner | 相同，已验证 |
| **OCR** | 无 | google_mlkit_text_recognition | 新增补救功能 |
| **数据库** | sqflite | sqflite | 相同 |
| **WebView** | webview_flutter | webview_flutter | 相同 |
| **定位** | geolocator + geocoding | geolocator + geocoding | 相同 |
| **广告** | google_mobile_ads | google_mobile_ads | 相同 |
| **状态管理** | Provider | Provider | 相同 |
| **图片压缩** | flutter_image_compress | flutter_image_compress | 相同 |

---

## 六、核心服务设计

### 6.1 ScanService (扫描核心)

```dart
// lib/services/scan_service.dart

import 'package:mobile_scanner/mobile_scanner.dart';

class ScanService {
  final MobileScannerController controller;
  final BarcodeParser _parser = BarcodeParser();

  ScanService() : controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,  // 用于AR Overlay + 截图
    formats: [
      // P0: 2D码
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
      BarcodeFormat.aztec,
      // P0: 1D码
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );

  /// 处理扫描结果
  Future<ScanRecord?> processBarcodes(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return null;

    // 单码或多码处理
    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return null;

    // 解析语意类型
    final parsed = _parser.parse(
      rawValue: barcode.rawValue!,
      format: barcode.format,
    );

    return ScanRecord(
      rawText: barcode.rawValue!,
      displayText: parsed.displayText,
      barcodeFormat: _mapFormat(barcode.format),
      semanticType: parsed.semanticType,
      scannedAt: DateTime.now(),
    );
  }

  /// 获取所有扫到的码 (Multi-QR)
  List<ScanRecord> processMultipleBarcodes(BarcodeCapture capture) {
    return capture.barcodes
      .where((b) => b.rawValue != null)
      .map((b) {
        final parsed = _parser.parse(
          rawValue: b.rawValue!,
          format: b.format,
        );
        return ScanRecord(
          rawText: b.rawValue!,
          displayText: parsed.displayText,
          barcodeFormat: _mapFormat(b.format),
          semanticType: parsed.semanticType,
          scannedAt: DateTime.now(),
        );
      })
      .toList();
  }

  /// Auto-Zoom 功能
  Future<void> autoZoom(double currentZoom, Rect? boundingBox) async {
    if (boundingBox == null) return;

    // 条码太小时自动放大
    final area = boundingBox.width * boundingBox.height;
    if (area < 0.05 && currentZoom < 2.0) {
      await controller.setZoomScale(currentZoom + 0.5);
    }
  }

  void dispose() {
    controller.dispose();
  }
}
```

### 6.2 BarcodeParser (条码解析)

```dart
// lib/services/barcode_parser.dart

class ParsedBarcode {
  final String displayText;
  final SemanticType semanticType;
  final Map<String, dynamic>? metadata;

  const ParsedBarcode({
    required this.displayText,
    required this.semanticType,
    this.metadata,
  });
}

class BarcodeParser {
  /// 解析条码内容，判断语意类型
  ParsedBarcode parse({
    required String rawValue,
    required BarcodeFormat format,
  }) {
    // 1. URL
    if (_isUrl(rawValue)) {
      return ParsedBarcode(
        displayText: rawValue,
        semanticType: SemanticType.url,
      );
    }

    // 2. Email (mailto: 或纯邮箱)
    if (_isEmail(rawValue)) {
      return ParsedBarcode(
        displayText: _extractEmail(rawValue),
        semanticType: SemanticType.email,
      );
    }

    // 3. Phone (tel: 或纯电话)
    if (_isPhone(rawValue)) {
      return ParsedBarcode(
        displayText: _extractPhone(rawValue),
        semanticType: SemanticType.phone,
      );
    }

    // 4. Wi-Fi (WIFI:S:...; 格式)
    if (_isWifi(rawValue)) {
      final wifi = _parseWifi(rawValue);
      return ParsedBarcode(
        displayText: wifi['ssid'] ?? rawValue,
        semanticType: SemanticType.wifi,
        metadata: wifi,
      );
    }

    // 5. ISBN (EAN-13 且 978/979 开头)
    if (_isIsbn(rawValue, format)) {
      return ParsedBarcode(
        displayText: rawValue,
        semanticType: SemanticType.isbn,
      );
    }

    // 6. vCard
    if (_isVCard(rawValue)) {
      return ParsedBarcode(
        displayText: _extractVCardName(rawValue),
        semanticType: SemanticType.vcard,
        metadata: _parseVCard(rawValue),
      );
    }

    // 7. Geo (geo:lat,lng)
    if (_isGeo(rawValue)) {
      return ParsedBarcode(
        displayText: rawValue,
        semanticType: SemanticType.geo,
        metadata: _parseGeo(rawValue),
      );
    }

    // 8. SMS (smsto: 或 sms:)
    if (_isSms(rawValue)) {
      return ParsedBarcode(
        displayText: _extractSmsNumber(rawValue),
        semanticType: SemanticType.sms,
        metadata: _parseSms(rawValue),
      );
    }

    // 9. 默认：纯文字
    return ParsedBarcode(
      displayText: rawValue,
      semanticType: SemanticType.text,
    );
  }

  // ========== 验证函数 ==========

  bool _isUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') ||
           lower.startsWith('https://') ||
           lower.startsWith('www.');
  }

  bool _isEmail(String value) {
    final lower = value.toLowerCase();
    if (lower.startsWith('mailto:')) return true;
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value);
  }

  bool _isPhone(String value) {
    final lower = value.toLowerCase();
    if (lower.startsWith('tel:')) return true;
    // 简单电话号码检测
    return RegExp(r'^[\d\s\-\+\(\)]{7,}$').hasMatch(value);
  }

  bool _isWifi(String value) {
    return value.toUpperCase().startsWith('WIFI:');
  }

  bool _isIsbn(String value, BarcodeFormat format) {
    // EAN-13 且 978/979 开头
    if (format != BarcodeFormat.ean13) return false;
    if (!value.startsWith('978') && !value.startsWith('979')) return false;
    return _validateIsbn13(value);
  }

  bool _validateIsbn13(String isbn) {
    if (isbn.length != 13) return false;
    if (!RegExp(r'^\d{13}$').hasMatch(isbn)) return false;

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(isbn[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(isbn[12]);
  }

  bool _isVCard(String value) {
    return value.toUpperCase().contains('BEGIN:VCARD');
  }

  bool _isGeo(String value) {
    return value.toLowerCase().startsWith('geo:');
  }

  bool _isSms(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('sms:') || lower.startsWith('smsto:');
  }

  // ========== 提取函数 ==========

  String _extractEmail(String value) {
    if (value.toLowerCase().startsWith('mailto:')) {
      return value.substring(7).split('?').first;
    }
    return value;
  }

  String _extractPhone(String value) {
    if (value.toLowerCase().startsWith('tel:')) {
      return value.substring(4);
    }
    return value;
  }

  Map<String, String> _parseWifi(String value) {
    // WIFI:S:SSID;T:WPA;P:password;;
    final result = <String, String>{};
    final content = value.substring(5); // 去掉 "WIFI:"

    final parts = content.split(';');
    for (final part in parts) {
      if (part.startsWith('S:')) result['ssid'] = part.substring(2);
      if (part.startsWith('T:')) result['type'] = part.substring(2);
      if (part.startsWith('P:')) result['password'] = part.substring(2);
    }
    return result;
  }

  // ... 其他解析函数
}
```

### 6.3 OCRService (OCR补救)

```dart
// lib/services/ocr_service.dart

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _recognizer = TextRecognizer();
  final BarcodeParser _parser = BarcodeParser();

  /// 从图像中识别文字并分类
  Future<List<ParsedBarcode>> recognizeFromImage(InputImage image) async {
    final recognized = await _recognizer.processImage(image);
    final results = <ParsedBarcode>[];

    for (final block in recognized.blocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;

      // 尝试解析语意类型
      final parsed = _parser.parse(
        rawValue: text,
        format: BarcodeFormat.unknown,
      );

      // 只保留有意义的结果
      if (parsed.semanticType != SemanticType.text ||
          text.length > 10) {
        results.add(parsed);
      }
    }

    return results;
  }

  void dispose() {
    _recognizer.close();
  }
}
```

### 6.4 LocationService (地点服务)

```dart
// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// 获取粗略地点 (城市/行政区)
  /// 符合 PDR 的隐私友善要求
  Future<LocationResult> getApproximateLocation() async {
    try {
      // 检查权限
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return LocationResult.denied();
        }
      }

      // 获取位置 (使用低精度)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,  // 粗略定位
        timeLimit: const Duration(seconds: 5),
      );

      // 反向地理编码 (只取城市/区)
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return LocationResult.failed();
      }

      final place = placemarks.first;
      // 组合地点名称：城市 + 行政区
      final parts = [
        place.locality,      // 城市
        place.subLocality,   // 区
      ].where((p) => p != null && p.isNotEmpty);

      return LocationResult.success(
        placeName: parts.join(', '),
        source: 'approx',
      );
    } catch (e) {
      return LocationResult.failed();
    }
  }
}

class LocationResult {
  final bool isSuccess;
  final String? placeName;
  final String source;  // none/approx

  const LocationResult._({
    required this.isSuccess,
    this.placeName,
    required this.source,
  });

  factory LocationResult.success({
    required String placeName,
    required String source,
  }) => LocationResult._(
    isSuccess: true,
    placeName: placeName,
    source: source,
  );

  factory LocationResult.denied() => const LocationResult._(
    isSuccess: false,
    source: 'none',
  );

  factory LocationResult.failed() => const LocationResult._(
    isSuccess: false,
    source: 'none',
  );
}
```

---

## 七、UI 设计规范

### 7.1 页面结构

```
┌─────────────────────────────────────┐
│          App Bar (可选)              │
├─────────────────────────────────────┤
│                                     │
│      Camera Preview (主区域)         │
│                                     │
│    ┌─────────────────────────┐      │
│    │    AR Overlay (浮层)    │      │
│    │   [📚 ISBN 9784...]     │      │
│    └─────────────────────────┘      │
│                                     │
├─────────────────────────────────────┤
│   [🔦] [History] [Settings]         │  ← 底部工具栏
└─────────────────────────────────────┘

扫描成功后：
┌─────────────────────────────────────┐
│           Result Card               │
│  ┌─────────────────────────────┐    │
│  │ 📚 书籍 ISBN               │    │
│  │ 9784567890123              │    │
│  │ (EAN-13)                   │    │
│  │                            │    │
│  │ [复制] [搜索] [保存]       │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│        Banner Ad (固定高度)          │
└─────────────────────────────────────┘
```

### 7.2 WebView 布局 (不撕裂设计)

```
┌─────────────────────────────────────┐
│  [←] example.com      [🔄] [↗️]     │  ← Toolbar
├─────────────────────────────────────┤
│        Banner Ad (固定高度)          │  ← 广告在内容上方
├─────────────────────────────────────┤
│                                     │
│          WebView Content            │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

### 7.3 历史页面布局

```
┌─────────────────────────────────────┐
│  History          [Filter] [Search] │
├─────────────────────────────────────┤
│  ┌───┬─────────────────────────┐    │
│  │📷 │ 📚 ISBN 978456789...    │    │
│  │   │ 2024-01-15 14:30       │    │
│  │   │ 台北市, 大安區         │    │
│  └───┴─────────────────────────┘    │
│  ┌───┬─────────────────────────┐    │
│  │📷 │ 🔗 https://example...   │    │
│  │   │ 2024-01-15 14:25       │    │
│  └───┴─────────────────────────┘    │
│  ...                                │
├─────────────────────────────────────┤
│        Banner Ad (固定高度)          │
└─────────────────────────────────────┘
```

---

## 八、权限配置

### 8.1 Android Manifest

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- 基础权限 -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>

    <!-- 相机 (P0) -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="true"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>

    <!-- 地点 (P1 - 可选) -->
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <!-- 注意：不使用 ACCESS_FINE_LOCATION 符合隐私友善原则 -->

    <!-- 存储 (用于截图保存) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>

    <application
        android:label="QR Scanner"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- AdMob -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXX~XXXXXXX"/>

        <!-- ML Kit -->
        <meta-data
            android:name="com.google.mlkit.vision.DEPENDENCIES"
            android:value="barcode,ocr"/>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- P2: Intent API -->
            <intent-filter>
                <action android:name="com.example.qrscanner.SCAN"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
        </activity>

    </application>
</manifest>
```

---

## 九、开发阶段规划

### Phase 1: MVP (P0)

**目标**: 核心扫描 + 基础历史

| 模块 | 任务 | 状态 |
|------|------|------|
| **扫描** | CameraX + ML Kit 整合 | - |
| **扫描** | 多格式支持 (QR + 1D) | - |
| **扫描** | Multi-QR 检测 | - |
| **解析** | 语意类型解析器 | - |
| **解析** | ISBN 验证 + 识别 | - |
| **数据库** | SQLite 基础表 | - |
| **历史** | 历史列表页 | - |
| **WebView** | Lite WebView 容器 | - |
| **行为** | URL/Email/Phone 跳转 | - |

### Phase 2: 完善体验 (P1)

| 模块 | 任务 | 状态 |
|------|------|------|
| **OCR** | OCR Fallback 补救 | - |
| **AR** | AR Overlay 浮层 | - |
| **Auto-Zoom** | 低成功率自动放大 | - |
| **图像** | 截图保存功能 | - |
| **地点** | 粗略位置保存 | - |
| **历史** | 筛选 + 搜索 | - |
| **广告** | Banner 广告整合 | - |
| **主题** | Light/Dark 主题 | - |

### Phase 3: 商业化 (P2)

| 模块 | 任务 | 状态 |
|------|------|------|
| **导出** | CSV 导出功能 | - |
| **批次** | 批次扫描模式 | - |
| **Intent** | 外部调用 API | - |
| **付费** | 付费解锁功能 | - |
| **进阶历史** | 进阶历史管理 | - |

---

## 十、技术债务与风险

### 10.1 已知风险

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| ML Kit 模型大小 | APK 体积增加 | 使用动态下载模型 |
| OCR 误识别 | 用户体验 | 信心分数过滤 |
| WebView 安全 | 安全风险 | 限制 JS 功能、显示域名 |
| 广告影响体验 | 用户流失 | 固定位置、不插页 |

### 10.2 性能考虑

- 相机预览使用 GPU 加速
- 扫描结果去重 (DetectionSpeed.noDuplicates)
- 历史列表分页加载
- 图像压缩后存储 (WebP/JPEG, 质量 70%)
- 自动清理旧图像 (保留最近 200 张)

---

## 十一、参考资源

- [mobile_scanner 文档](https://pub.dev/packages/mobile_scanner)
- [ML Kit Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning)
- [Google AdMob 政策](https://support.google.com/admob/answer/6128543)
- tpml_app 源码 (`/home/steve0721/projects/tpml_app/`)

---

*文档版本: 1.0*
*基于 PDR v1.0 规划*
