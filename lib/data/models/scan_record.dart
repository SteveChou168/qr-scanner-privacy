// lib/data/models/scan_record.dart

import '../../app_text.dart';

/// Barcode format enumeration
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
  itf,
  codabar,
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
    itf => 'ITF',
    codabar => 'Codabar',
    unknown => 'Unknown',
  };

  static BarcodeFormat fromString(String? s) {
    if (s == null) return unknown;
    return BarcodeFormat.values.firstWhere(
      (e) => e.name == s,
      orElse: () => unknown,
    );
  }
}

/// Semantic type enumeration
enum SemanticType {
  url,
  email,
  wifi,
  isbn,
  vcard,
  geo,
  sms,
  text;

  String get icon => switch (this) {
    url => '🔗',
    email => '✉️',
    wifi => '📶',
    isbn => '📚',
    vcard => '👤',
    geo => '📍',
    sms => '💬',
    text => '📝',
  };

  String get label => switch (this) {
    url => AppText.typeUrl,
    email => AppText.typeEmail,
    wifi => AppText.typeWifi,
    isbn => AppText.typeIsbn,
    vcard => AppText.typeVcard,
    geo => AppText.typeGeo,
    sms => AppText.typeSms,
    text => AppText.typeText,
  };

  static SemanticType fromString(String? s) {
    if (s == null) return text;
    return SemanticType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => text,
    );
  }
}

/// Scan record model
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

  /// Primary label for display (semantic type)
  String get primaryLabel {
    return semanticType == SemanticType.isbn
        ? AppText.typeIsbn
        : semanticType.label;
  }

  /// Secondary label for display (barcode format)
  String get secondaryLabel => barcodeFormat.displayName;

  /// Preview text (first 50 chars)
  String get preview {
    final text = displayText ?? rawText;
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }

  /// Create from database map
  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] as int?,
      rawText: map['raw_text'] as String,
      displayText: map['display_text'] as String?,
      barcodeFormat: BarcodeFormat.fromString(map['barcode_format'] as String?),
      semanticType: SemanticType.fromString(map['semantic_type'] as String?),
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      placeName: map['place_name'] as String?,
      placeSource: map['place_source'] as String? ?? 'none',
      imagePath: map['image_path'] as String?,
      tags: (map['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      note: map['note'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
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
  }

  /// Create a copy with modifications
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
