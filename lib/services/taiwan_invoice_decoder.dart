// lib/services/taiwan_invoice_decoder.dart
// 台灣電子發票 QR Code 解碼器

import 'dart:typed_data';
import 'package:enough_convert/enough_convert.dart';

/// 台灣電子發票解析結果
class TaiwanInvoice {
  final String track;           // 字軌 (2碼)
  final String number;          // 號碼 (8碼)
  final String date;            // 開立日期 (民國年月日)
  final String randomCode;      // 隨機碼 (4碼)
  final int salesAmount;        // 未稅金額
  final int totalAmount;        // 總金額
  final String buyerId;         // 買方統編
  final String sellerId;        // 賣方統編
  final String encryptedInfo;   // 加密驗證資訊 (AES + Base64, 24碼)
  final int itemCount;          // 品目筆數
  final String encodingParam;   // 編碼參數
  final List<InvoiceItem> items; // 商品明細
  final String rawText;         // 原始文字（已解碼）

  TaiwanInvoice({
    required this.track,
    required this.number,
    required this.date,
    required this.randomCode,
    required this.salesAmount,
    required this.totalAmount,
    required this.buyerId,
    required this.sellerId,
    required this.encryptedInfo,
    required this.itemCount,
    required this.encodingParam,
    required this.items,
    required this.rawText,
  });

  /// 格式化的發票號碼 (XX-12345678)
  String get formattedNumber => '$track-$number';

  /// 格式化的日期 (民國114年02月01日 -> 2025/02/01)
  String get formattedDate {
    if (date.length != 7) return date;
    final year = int.tryParse(date.substring(0, 3));
    final month = date.substring(3, 5);
    final day = date.substring(5, 7);
    if (year == null) return date;
    return '${year + 1911}/$month/$day';
  }

  /// 格式化的總金額
  String get formattedTotal => '\$${totalAmount.toString()}';
}

/// 發票商品明細
class InvoiceItem {
  final String name;     // 品名
  final int quantity;    // 數量
  final int price;       // 單價

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

/// 台灣電子發票解碼器
class TaiwanInvoiceDecoder {
  static final _big5Codec = Big5Codec(allowInvalid: true);

  /// 檢查是否為台灣電子發票格式（左 QR 或右 QR）
  static bool isTaiwanInvoice(String? text, Uint8List? rawBytes) {
    // 1. 檢查左 QR（有完整 header）- 放寬日期驗證
    if (rawBytes != null && rawBytes.length >= 77) {
      // 檢查前10碼：2個大寫英文 + 8個數字
      final header = String.fromCharCodes(rawBytes.sublist(0, 10));
      final dateStr = String.fromCharCodes(rawBytes.sublist(10, 17));
      if (RegExp(r'^[A-Z]{2}\d{8}$').hasMatch(header)) {
        // 放寬日期格式：任何 7 碼數字（涵蓋民國 0xx-9xx 年）
        if (RegExp(r'^\d{7}$').hasMatch(dateStr)) {
          return true;
        }
      }
    }

    // 2. 檢查右 QR（** 開頭的商品續接資料）
    if (rawBytes != null && rawBytes.length >= 2) {
      if (rawBytes[0] == 0x2A && rawBytes[1] == 0x2A) {  // ** in ASCII
        return true;
      }
    }

    // 3. rawBytes 含有高位元組（Big5 或 UTF-8 中文）就嘗試解碼
    if (rawBytes != null && rawBytes.length >= 20) {
      if (_containsBig5Chars(rawBytes) || _containsUtf8Chars(rawBytes)) {
        return true;
      }
    }

    // 4. Fallback: 用 text 檢查左 QR（放寬日期）
    if (text != null && text.length >= 77) {
      if (RegExp(r'^[A-Z]{2}\d{8}\d{7}').hasMatch(text)) {
        return true;
      }
    }

    // 5. Fallback: 用 text 檢查右 QR
    if (text != null && text.startsWith('**')) {
      return true;
    }

    // 6. Fallback: text 含有亂碼特徵（高位元組被誤讀）
    if (text != null && text.length >= 20 && _containsGarbledChinese(text)) {
      return true;
    }

    return false;
  }

  /// 檢查 rawBytes 是否包含 Big5 中文字元
  static bool _containsBig5Chars(Uint8List bytes) {
    for (int i = 0; i < bytes.length - 1; i++) {
      // Big5 高位元組範圍: 0x81-0xFE
      // Big5 低位元組範圍: 0x40-0x7E, 0xA1-0xFE
      if (bytes[i] >= 0x81 && bytes[i] <= 0xFE) {
        final low = bytes[i + 1];
        if ((low >= 0x40 && low <= 0x7E) || (low >= 0xA1 && low <= 0xFE)) {
          return true;
        }
      }
    }
    return false;
  }

  /// 檢查 text 是否包含 Big5 被誤讀的亂碼
  ///
  /// 情況 1: Latin-1/ISO-8859-1 誤讀 → 0x80-0xFF 範圍字元
  /// 情況 2: UTF-8 誤讀 → U+FFFD replacement character (�)
  /// 情況 3: Shift_JIS 誤讀 → 日文片假名 (U+FF61-U+FF9F)
  static bool _containsGarbledChinese(String text) {
    for (final char in text.codeUnits) {
      // Latin-1 誤讀：0x80-0xFF
      if (char >= 0x80 && char <= 0xFF) {
        return true;
      }
      // UTF-8 誤讀：replacement character (�)
      if (char == 0xFFFD) {
        return true;
      }
      // Shift_JIS 誤讀：半形片假名
      if (char >= 0xFF61 && char <= 0xFF9F) {
        return true;
      }
    }
    return false;
  }

  /// 從 rawBytes 解碼台灣電子發票
  ///
  /// Big5 向下相容 ASCII，所以整個 rawBytes 都可以用 Big5 解碼
  static TaiwanInvoice? decode(Uint8List? rawBytes, String? fallbackText) {
    if (rawBytes == null || rawBytes.length < 77) {
      return null;
    }

    try {
      // 用 Big5 解碼整個 rawBytes
      final decodedText = _big5Codec.decode(rawBytes);

      // 解析固定欄位 (前77碼都是 ASCII)
      // 官方 MIG 格式:
      // 0-9:   發票號碼 (10) = 字軌(2) + 號碼(8)
      // 10-16: 日期 (7)
      // 17-20: 隨機碼 (4)
      // 21-28: 銷售額 hex (8)
      // 29-36: 總金額 hex (8)
      // 37-44: 買方統編 (8)
      // 45-52: 賣方統編 (8)
      // 53-76: 加密資料 (24)
      final track = decodedText.substring(0, 2);
      final number = decodedText.substring(2, 10);
      final date = decodedText.substring(10, 17);
      final randomCode = decodedText.substring(17, 21);
      final salesHex = decodedText.substring(21, 29);
      final totalHex = decodedText.substring(29, 37);
      final buyerId = decodedText.substring(37, 45);
      final sellerId = decodedText.substring(45, 53);
      final encryptedInfo = decodedText.substring(53, 77);

      // 解析金額 (16進位)
      final salesAmount = int.tryParse(salesHex, radix: 16) ?? 0;
      final totalAmount = int.tryParse(totalHex, radix: 16) ?? 0;

      // 解析商品明細 (77碼之後，格式: :品目筆數:總筆數:編碼參數:品名1:數量1:單價1:...)
      final items = <InvoiceItem>[];
      int itemCount = 0;
      String encodingParam = '';

      if (decodedText.length > 77) {
        final suffix = decodedText.substring(77);
        final parts = suffix.split(':');

        // 格式: :品目筆數:總筆數:編碼參數:品名1:數量1:單價1:...
        if (parts.length >= 4) {
          itemCount = int.tryParse(parts[1]) ?? 0;
          // parts[2] 是總筆數
          encodingParam = parts[3];

          // 解析商品 (從 index 4 開始，每3個一組)
          for (int i = 4; i + 2 < parts.length; i += 3) {
            final name = parts[i];
            final qty = int.tryParse(parts[i + 1]) ?? 0;
            final price = int.tryParse(parts[i + 2]) ?? 0;
            if (name.isNotEmpty) {
              items.add(InvoiceItem(name: name, quantity: qty, price: price));
            }
          }
        }
      }

      return TaiwanInvoice(
        track: track,
        number: number,
        date: date,
        randomCode: randomCode,
        salesAmount: salesAmount,
        totalAmount: totalAmount,
        buyerId: buyerId,
        sellerId: sellerId,
        encryptedInfo: encryptedInfo,
        itemCount: itemCount,
        encodingParam: encodingParam,
        items: items,
        rawText: decodedText,
      );
    } catch (e) {
      // 解碼失敗，返回 null
      return null;
    }
  }

  /// 取得解碼後的顯示文字
  ///
  /// 智慧判斷編碼：UTF-8 直接用 text，Big5 才重新解碼
  static String getDecodedText(Uint8List? rawBytes, String fallbackText) {
    if (rawBytes == null || rawBytes.isEmpty) {
      return fallbackText;
    }

    // 1. 檢測編碼類型
    final encoding = _detectEncoding(rawBytes);

    // 2. UTF-8 編碼：ZXing 已經正確解碼，直接用 fallbackText
    if (encoding == 'UTF-8') {
      return fallbackText;
    }

    // 3. Big5 編碼：需要重新解碼
    if (encoding == 'Big5') {
      try {
        return _big5Codec.decode(rawBytes);
      } catch (_) {
        // Big5 解碼失敗，繼續嘗試其他方法
      }
    }

    // 4. Fallback: 嘗試從亂碼還原 Big5
    if (fallbackText.isNotEmpty && _containsGarbledChinese(fallbackText)) {
      try {
        final recoveredBytes = Uint8List.fromList(
          fallbackText.codeUnits.map((c) => c & 0xFF).toList(),
        );
        final decoded = _big5Codec.decode(recoveredBytes);
        if (_containsValidChinese(decoded)) {
          return decoded;
        }
      } catch (_) {
        // 亂碼還原失敗
      }
    }

    return fallbackText;
  }

  /// 檢測 rawBytes 的編碼類型
  ///
  /// MIG 3.2: Big5 編碼
  /// MIG 4.0: UTF-8 編碼
  static String _detectEncoding(Uint8List bytes) {
    // UTF-8 多字節序列特徵：
    // 2 bytes: 110xxxxx 10xxxxxx (0xC0-0xDF 0x80-0xBF)
    // 3 bytes: 1110xxxx 10xxxxxx 10xxxxxx (0xE0-0xEF 0x80-0xBF 0x80-0xBF)
    // 4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

    int utf8Score = 0;
    int big5Score = 0;

    for (int i = 0; i < bytes.length - 1; i++) {
      final b = bytes[i];

      // 檢測 UTF-8 三字節序列（中文常見）
      if (i + 2 < bytes.length &&
          b >= 0xE0 && b <= 0xEF &&
          bytes[i + 1] >= 0x80 && bytes[i + 1] <= 0xBF &&
          bytes[i + 2] >= 0x80 && bytes[i + 2] <= 0xBF) {
        utf8Score += 3;
        i += 2;
        continue;
      }

      // 檢測 UTF-8 二字節序列
      if (i + 1 < bytes.length &&
          b >= 0xC0 && b <= 0xDF &&
          bytes[i + 1] >= 0x80 && bytes[i + 1] <= 0xBF) {
        utf8Score += 2;
        i += 1;
        continue;
      }

      // 檢測 Big5 雙字節序列
      // Big5 高位元組: 0x81-0xFE, 低位元組: 0x40-0x7E 或 0xA1-0xFE
      if (b >= 0x81 && b <= 0xFE) {
        final low = bytes[i + 1];
        if ((low >= 0x40 && low <= 0x7E) || (low >= 0xA1 && low <= 0xFE)) {
          big5Score += 2;
          i += 1;
          continue;
        }
      }
    }

    if (utf8Score > big5Score) return 'UTF-8';
    if (big5Score > utf8Score) return 'Big5';
    return 'Unknown';
  }

  /// 檢查 rawBytes 是否包含 UTF-8 多字節序列
  static bool _containsUtf8Chars(Uint8List bytes) {
    for (int i = 0; i < bytes.length - 2; i++) {
      final b = bytes[i];
      // UTF-8 三字節序列（中文常見）
      if (b >= 0xE0 && b <= 0xEF &&
          bytes[i + 1] >= 0x80 && bytes[i + 1] <= 0xBF &&
          bytes[i + 2] >= 0x80 && bytes[i + 2] <= 0xBF) {
        return true;
      }
    }
    return false;
  }

  /// 檢查字串是否包含有效的中文字元（Unicode CJK 範圍）
  static bool _containsValidChinese(String text) {
    for (final char in text.codeUnits) {
      // CJK Unified Ideographs: U+4E00 - U+9FFF
      // CJK Extension A: U+3400 - U+4DBF
      if ((char >= 0x4E00 && char <= 0x9FFF) ||
          (char >= 0x3400 && char <= 0x4DBF)) {
        return true;
      }
    }
    return false;
  }
}
