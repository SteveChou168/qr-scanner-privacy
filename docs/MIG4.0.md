# MIG 4.0 發票掃描問題記錄

## 問題描述

2026年1-2月的台灣統一發票採用 **MIG 4.0 格式**，ML Kit 無法辨識其 QR Code。

### 症狀
- 2025年11-12月發票：可以掃描 ✅
- 2026年1-2月發票：無法掃描 ❌
- 其他 QR Code：正常 ✅
- 其他 App（如「QR掃描器」）：可以掃描 ✅

### 根本原因
MIG 4.0 格式的 QR Code 可能採用了不同的編碼方式或密度，導致 ML Kit 無法正確識別。

---

## 嘗試過的解決方案

### 1. ZXing Fallback (flutter_zxing)
**狀態**: ⚠️ 發現 BUG 並修復中

```yaml
flutter_zxing: ^1.8.0  # 實際安裝 1.9.1
```

#### 發現的 Bug：imageFormat 不匹配

`flutter_zxing` 套件有一個 bug：
- **預設** `imageFormat = ImageFormat.lum`（灰階/亮度）
- **但是**內部函數 `rgbBytes()` 會將圖片轉為 RGB 格式
- 這導致 native 層誤解圖片格式，無法正確解碼

**修復方式**：
```dart
final params = zxing.DecodeParams(
  imageFormat: zxing.ImageFormat.rgb,  // 關鍵！必須明確設為 RGB
  format: zxing.Format.any,            // 掃所有格式
  tryHarder: true,
  tryRotate: true,
  tryInverted: true,
  isMultiScan: true,
  maxSize: 9999,                       // 避免縮圖，用原圖解析度
);
```

**ZXing Online 能掃**: (https://zxing.org/w/decode.jspx) 可以掃描！這表示 ZXing 引擎本身有能力。

---

### 2. OpenCV WeChat QR Scanner (opencv_dart)
**狀態**: ❌ 失敗（且套件太大）

```yaml
opencv_dart: ^2.1.0
```

需要模型檔案：
- `detect.prototxt` (42KB)
- `detect.caffemodel` (943KB)
- `sr.prototxt` (6KB)
- `sr.caffemodel` (24KB)

**APK 增加**: 約 100+ MB（太大，已移除）

**結果**: 無法掃描 MIG 4.0 QR Code

---

### 3. 解析度切換 (FHD/2K/4K)
**狀態**: ⚠️ 實作完成但未驗證效果

在 `scan_screen.dart` 加入解析度切換按鈕：

```dart
static const List<Size> _resolutions = [
  Size(1920, 1080),  // FHD
  Size(2560, 1440),  // 2K
  Size(3840, 2160),  // 4K
];
```

**結論**: 用戶認為 ML Kit 解析度不足不是主因

---

### 4. 圖像預處理 (OpenCV)
**狀態**: ❌ 已實作但未驗證（隨 opencv_dart 移除）

```dart
// 1. 轉灰階
final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);

// 2. 腐蝕運算 (Erosion) - 把黏在一起的點分開
final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
final eroded = cv.erode(gray, kernel);

// 3. 二值化 (Binarization) - 強化對比
final (_, binary) = cv.threshold(eroded, 128, 255, cv.THRESH_BINARY);
```

---

## 待嘗試的方向

### 1. 調整 ZXing 參數
ZXing Online 能掃出來，表示 ZXing 引擎有能力。可能需要：
- 不同的 `DecodeParams` 配置
- 圖像預處理（用 `image` 套件）
- 調整圖片大小或格式

### 2. 圖像預處理（不用 OpenCV）
使用 `image` 套件做預處理：
```dart
import 'package:image/image.dart' as img;

// 灰階
img.Image processed = img.grayscale(original);

// 銳化
processed = img.convolution(processed, sharpenKernel);

// 對比度增強
processed = img.adjustColor(processed, contrast: 1.5);
```

### 3. iOS Vision Framework
Apple 原生的 QR 掃描可能更強，但只限 iOS。

### 4. 商業 SDK
- Dynamsoft Barcode SDK
- Scandit

---

## 目前狀態 ✅ 已解決

照片模式採用 **ML Kit + ZXing 並行掃描**，合併結果。

檔案位置：`lib/widgets/scan/scan_gallery_mode.dart`

### 架構

```
┌─────────────────────────────────────────┐
│  選擇圖片                                │
└─────────────┬───────────────────────────┘
              │
     ┌────────┴────────┐
     ▼                 ▼
┌─────────┐      ┌─────────┐
│ ML Kit  │      │  ZXing  │   ← Future.wait() 並行
└────┬────┘      └────┬────┘
     │                │
     └───────┬────────┘
             ▼
      合併結果 (去重)
      衝突時 ZXing 優先
```

### 關鍵修復

**flutter_zxing imageFormat bug**：
```dart
final params = zxing.DecodeParams(
  imageFormat: zxing.ImageFormat.rgb,  // 關鍵！預設 lum 但實際傳 RGB
  format: zxing.Format.any,
  tryHarder: true,
  tryRotate: true,
  tryInverted: true,
  isMultiScan: true,
  maxSize: 9999,
);
```

### 效果

- ✅ MIG 4.0 發票：可掃描
- ✅ 一般 QR Code：可掃描
- ✅ ISBN 條碼：可掃描
- ✅ 並行掃描，速度不受影響（~400ms）

---

## Big5 編碼問題 ✅ 已解決

### 問題
台灣電子發票 QR Code 的品名欄位使用 Big5 編碼，但 ZXing/ML Kit 用 Latin-1 解讀，導致亂碼：
- `ÂC³½³J»æ` → 應該是中文品名
- `¬õ¯ù[¤¤]` → 應該是中文品名

### 解決方案
1. 使用 `enough_convert` 套件提供 Big5 Codec
2. 直接從 `rawBytes` 解碼，不用已污染的 String
3. 偵測台灣發票格式後自動 Big5 解碼

### 檔案
- `lib/services/taiwan_invoice_decoder.dart` - 發票偵測與解碼
- `lib/widgets/scan/scan_gallery_mode.dart` - 掃描時自動解碼

### 發票 QR Code 格式
```
位置 1-2:   字軌 (2英文)     例: XH
位置 3-10:  發票號碼 (8位數)  例: 36363795
位置 11-17: 開立日期 (民國)   例: 1150201
位置 18-21: 隨機碼 (4碼)     例: 9210
位置 22-29: 未稅金額 (16進位)
位置 30-37: 總金額 (16進位)
位置 38-45: 買方統編
位置 46-69: 加密驗證 (AES+Base64)
位置 70-79: 營業人自用區
位置 80+:   :品目筆數:總筆數:編碼參數:品名1:數量1:單價1:...
```

---

## 參考資料

- [ML Kit 高密度 QR Code 問題 (GitHub Issue #352)](https://github.com/juliansteenbakker/mobile_scanner/issues/352)
- [ZXing Online Decoder](https://zxing.org/w/decode.jspx)
- [OpenCV WeChat QR Code](https://docs.opencv.org/4.x/dd/d63/group__wechat__qrcode.html)
- [MIG 4.0 格式說明](https://www.einvoice.nat.gov.tw/)
