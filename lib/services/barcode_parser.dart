// lib/services/barcode_parser.dart

import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import '../data/models/scan_record.dart';

/// Parsed barcode result
class ParsedBarcode {
  final String rawValue;
  final String displayText;
  final SemanticType semanticType;
  final BarcodeFormat barcodeFormat;
  final Map<String, dynamic>? metadata;

  const ParsedBarcode({
    required this.rawValue,
    required this.displayText,
    required this.semanticType,
    required this.barcodeFormat,
    this.metadata,
  });
}

/// Barcode parser service
class BarcodeParser {
  /// Parse barcode and determine semantic type
  ParsedBarcode parse({
    required String rawValue,
    required ms.BarcodeFormat format,
  }) {
    final barcodeFormat = _mapFormat(format);

    // 1. URL
    if (_isUrl(rawValue)) {
      return ParsedBarcode(
        rawValue: rawValue,
        displayText: rawValue,
        semanticType: SemanticType.url,
        barcodeFormat: barcodeFormat,
      );
    }

    // 2. Email
    if (_isEmail(rawValue)) {
      return ParsedBarcode(
        rawValue: rawValue,
        displayText: _extractEmail(rawValue),
        semanticType: SemanticType.email,
        barcodeFormat: barcodeFormat,
      );
    }

    // 3. Phone - DISABLED: Hard to detect accurately, rarely used in QR codes
    // Phone numbers are now treated as plain text
    // if (_isPhone(rawValue)) { ... }

    // 4. Wi-Fi
    if (_isWifi(rawValue)) {
      final wifi = _parseWifi(rawValue);
      return ParsedBarcode(
        rawValue: rawValue,
        displayText: wifi['ssid'] ?? rawValue,
        semanticType: SemanticType.wifi,
        barcodeFormat: barcodeFormat,
        metadata: wifi,
      );
    }

    // 5. ISBN (EAN-13 starting with 978/979)
    final extractedIsbn = _extractIsbn(rawValue);
    if (extractedIsbn != null) {
      return ParsedBarcode(
        rawValue: rawValue,
        displayText: extractedIsbn,
        semanticType: SemanticType.isbn,
        barcodeFormat: barcodeFormat,
      );
    }

    // 6. vCard
    if (_isVCard(rawValue)) {
      final vcard = _parseVCard(rawValue);
      return ParsedBarcode(
        rawValue: rawValue,
        displayText: vcard['name'] ?? rawValue,
        semanticType: SemanticType.vcard,
        barcodeFormat: barcodeFormat,
        metadata: vcard,
      );
    }

    // 7. Geo
    if (_isGeo(rawValue)) {
      final geo = _parseGeo(rawValue);
      return ParsedBarcode(
        rawValue: rawValue,
        displayText: '${geo['lat']}, ${geo['lng']}',
        semanticType: SemanticType.geo,
        barcodeFormat: barcodeFormat,
        metadata: geo,
      );
    }

    // 8. SMS
    if (_isSms(rawValue)) {
      final sms = _parseSms(rawValue);
      return ParsedBarcode(
        rawValue: rawValue,
        displayText: sms['number'] ?? rawValue,
        semanticType: SemanticType.sms,
        barcodeFormat: barcodeFormat,
        metadata: sms,
      );
    }

    // 9. Default: plain text
    return ParsedBarcode(
      rawValue: rawValue,
      displayText: rawValue,
      semanticType: SemanticType.text,
      barcodeFormat: barcodeFormat,
    );
  }

  // ============ Format Mapping ============

  BarcodeFormat _mapFormat(ms.BarcodeFormat format) {
    return switch (format) {
      ms.BarcodeFormat.qrCode => BarcodeFormat.qrCode,
      ms.BarcodeFormat.dataMatrix => BarcodeFormat.dataMatrix,
      ms.BarcodeFormat.pdf417 => BarcodeFormat.pdf417,
      ms.BarcodeFormat.aztec => BarcodeFormat.aztec,
      ms.BarcodeFormat.ean13 => BarcodeFormat.ean13,
      ms.BarcodeFormat.ean8 => BarcodeFormat.ean8,
      ms.BarcodeFormat.upcA => BarcodeFormat.upcA,
      ms.BarcodeFormat.upcE => BarcodeFormat.upcE,
      ms.BarcodeFormat.code128 => BarcodeFormat.code128,
      ms.BarcodeFormat.code39 => BarcodeFormat.code39,
      ms.BarcodeFormat.itf => BarcodeFormat.itf,
      ms.BarcodeFormat.codabar => BarcodeFormat.codabar,
      _ => BarcodeFormat.unknown,
    };
  }

  // ============ Validators ============

  bool _isUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        (lower.startsWith('www.') && lower.contains('.'));
  }

  bool _isEmail(String value) {
    final lower = value.toLowerCase();
    if (lower.startsWith('mailto:')) return true;
    return RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w+$').hasMatch(value);
  }

  // Phone detection removed - hard to detect accurately, rarely used in QR codes

  bool _isWifi(String value) {
    return value.toUpperCase().startsWith('WIFI:');
  }

  /// 從內容提取 ISBN-13，不依賴 format（mobile_scanner 可能誤判格式）
  String? _extractIsbn(String value) {
    // 提取所有數字
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // 嘗試匹配 978/979 開頭的 13 位數字
    final match = RegExp(r'(97[89]\d{10})').firstMatch(digitsOnly);
    if (match == null) return null;

    final isbn = match.group(1)!;
    return _validateIsbn13(isbn) ? isbn : null;
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

  // ============ Extractors ============

  String _extractEmail(String value) {
    if (value.toLowerCase().startsWith('mailto:')) {
      return value.substring(7).split('?').first;
    }
    return value;
  }

  Map<String, String> _parseWifi(String value) {
    return parseWifiString(value);
  }

  /// Parse WiFi QR string - public static method for reuse
  /// Format: WIFI:S:SSID;T:WPA;P:password;;
  static Map<String, String> parseWifiString(String value) {
    final result = <String, String>{};
    if (!value.toUpperCase().startsWith('WIFI:')) return result;

    final content = value.substring(5); // Remove "WIFI:"
    final parts = content.split(';');
    for (final part in parts) {
      if (part.startsWith('S:')) result['ssid'] = part.substring(2);
      if (part.startsWith('T:')) result['type'] = part.substring(2);
      if (part.startsWith('P:')) result['password'] = part.substring(2);
      if (part.startsWith('H:')) result['hidden'] = part.substring(2);
    }
    return result;
  }

  Map<String, String> _parseVCard(String value) {
    final result = <String, String>{};
    final lines = value.split(RegExp(r'[\r\n]+'));

    for (final line in lines) {
      if (line.startsWith('FN:')) {
        result['name'] = line.substring(3);
      } else if (line.startsWith('TEL')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          result['phone'] = line.substring(colonIndex + 1);
        }
      } else if (line.startsWith('EMAIL')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          result['email'] = line.substring(colonIndex + 1);
        }
      } else if (line.startsWith('ORG:')) {
        result['org'] = line.substring(4);
      }
    }
    return result;
  }

  Map<String, String> _parseGeo(String value) {
    // geo:lat,lng or geo:lat,lng?q=...
    final content = value.substring(4).split('?').first;
    final parts = content.split(',');

    return {
      'lat': parts.isNotEmpty ? parts[0] : '0',
      'lng': parts.length > 1 ? parts[1] : '0',
    };
  }

  Map<String, String> _parseSms(String value) {
    // sms:number?body=text or smsto:number:body
    String content;
    if (value.toLowerCase().startsWith('smsto:')) {
      content = value.substring(6);
    } else {
      content = value.substring(4);
    }

    final parts = content.split('?');
    final number = parts[0].split(':').first;

    String? body;
    if (parts.length > 1) {
      final params = Uri.splitQueryString(parts[1]);
      body = params['body'];
    }

    return {
      'number': number,
      if (body != null) 'body': body,
    };
  }
}
