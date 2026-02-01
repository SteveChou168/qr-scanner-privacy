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
  final String encryptedInfo;   // 加密驗證資訊
  final String merchantArea;    // 營業人自用區
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
    required this.encryptedInfo,
    required this.merchantArea,
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
    // 1. 檢查左 QR（有完整 header）
    if (rawBytes != null && rawBytes.length >= 77) {
      // 檢查前10碼：2個大寫英文 + 8個數字
      final header = String.fromCharCodes(rawBytes.sublist(0, 10));
      if (RegExp(r'^[A-Z]{2}\d{8}$').hasMatch(header)) {
        // 檢查日期格式：民國年 (1xx 開頭)
        final dateStr = String.fromCharCodes(rawBytes.sublist(10, 17));
        if (RegExp(r'^1\d{6}$').hasMatch(dateStr)) {
          return true;
        }
      }
    }

    // 2. 檢查右 QR（** 開頭的商品續接資料）
    if (rawBytes != null && rawBytes.length >= 2) {
      // 右 QR 以 ** 開頭
      if (rawBytes[0] == 0x2A && rawBytes[1] == 0x2A) {  // ** in ASCII
        // 確認含有 Big5 高位元組（中文字元）
        if (_containsBig5Chars(rawBytes)) {
          return true;
        }
      }
    }

    // 3. Fallback: 用 text 檢查左 QR
    if (text != null && text.length >= 77) {
      if (RegExp(r'^[A-Z]{2}\d{8}1\d{6}').hasMatch(text)) {
        return true;
      }
    }

    // 4. Fallback: 用 text 檢查右 QR
    if (text != null && text.startsWith('**') && _containsGarbledChinese(text)) {
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

  /// 檢查 text 是否包含 Big5 被誤讀的亂碼（Latin-1 高位字元）
  static bool _containsGarbledChinese(String text) {
    // Big5 被 Latin-1 誤讀會出現 0x80-0xFF 範圍的字元
    for (final char in text.codeUnits) {
      if (char >= 0x80 && char <= 0xFF) {
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

      // 解析固定欄位 (前77碼都是 ASCII，不會有問題)
      final track = decodedText.substring(0, 2);
      final number = decodedText.substring(2, 10);
      final date = decodedText.substring(10, 17);
      final randomCode = decodedText.substring(17, 21);
      final salesHex = decodedText.substring(21, 29);
      final totalHex = decodedText.substring(29, 37);
      final buyerId = decodedText.substring(37, 45);
      final encryptedInfo = decodedText.substring(45, 69);
      final merchantArea = decodedText.substring(69, 79);

      // 解析金額 (16進位)
      final salesAmount = int.tryParse(salesHex, radix: 16) ?? 0;
      final totalAmount = int.tryParse(totalHex, radix: 16) ?? 0;

      // 解析商品明細 (79碼之後)
      final items = <InvoiceItem>[];
      int itemCount = 0;
      String encodingParam = '';

      if (decodedText.length > 79) {
        final suffix = decodedText.substring(79);
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
        encryptedInfo: encryptedInfo,
        merchantArea: merchantArea,
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
  /// 優先用 rawBytes 解碼，失敗則用 fallbackText
  static String getDecodedText(Uint8List? rawBytes, String fallbackText) {
    if (rawBytes == null || rawBytes.isEmpty) {
      return fallbackText;
    }

    try {
      return _big5Codec.decode(rawBytes);
    } catch (_) {
      return fallbackText;
    }
  }
}
