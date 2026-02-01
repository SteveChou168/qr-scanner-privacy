# Scanner Implementation

## Mobile Scanner Integration

Uses `mobile_scanner` v7.x with `ms.` prefix to avoid enum conflicts:
```dart
import 'package:mobile_scanner/mobile_scanner.dart' as ms;

_controller = ms.MobileScannerController(
  detectionSpeed: ms.DetectionSpeed.noDuplicates,  // 提高識別率
  cameraResolution: const Size(1920, 1080),
  returnImage: returnImage,  // 僅在需要保存圖片時啟用
  // 不指定 formats，讓 ML Kit 自動識別所有格式
);

// v7.x breaking change: autoStart removed, must manually start
if (widget.isActive) {
  _controller?.start();
}
```

## 2025-01 條碼識別率優化

### 問題
ISBN 條碼（EAN-13）識別率低，即使是清晰的條碼也經常掃不到。

### 與 tpml_app 的比較分析

| 配置項 | QR 專案（優化前） | tpml_app | 影響 |
|--------|------------------|----------|------|
| detectionSpeed | `normal` | `noDuplicates` | tpml 更穩定 |
| formats | 明確指定 12 種 | 不指定（默認全部） | 限制格式可能降低識別率 |
| autoZoom | `true` | 不指定 | 可能對 1D 條碼有負面影響 |
| returnImage | 根據設置 | 無 | 會增加資源消耗 |

### 已完成的優化

1. **移除 `formats` 參數** - 讓 ML Kit 自動識別所有格式
2. **移除 `autoZoom`** - 對 1D 條碼可能有負面影響
3. **改用 `DetectionSpeed.noDuplicates`** - 與 tpml_app 一致
4. **降低多幀累積閾值** - 從 3 幀改為 1 幀
5. **ISBN 判斷改為基於內容** - 不再依賴 format 參數
   ```dart
   // 舊邏輯：依賴 format
   if (format != ms.BarcodeFormat.ean13) return false;

   // 新邏輯：從內容提取
   final match = RegExp(r'(97[89]\d{10})').firstMatch(digitsOnly);
   ```

### 實時掃描改善
上述優化後，實時掃描識別率有明顯改善。

### 照片模式問題（待解決）

照片模式使用 `analyzeImage()` 仍然識別率低。已嘗試：

1. ❌ 使用獨立的 MobileScannerController
2. ❌ 加入 `google_mlkit_barcode_scanning` 直接調用 ML Kit
3. ❌ 圖片銳利化 (convolution kernel)
4. ❌ 對比度增強 (grayscale + contrast 1.5x)
5. ❌ 二值化處理 (luminanceThreshold)
6. ❌ 多角度旋轉 (90°, 180°, 270°)

### 可能的方向

1. **圖片預處理**
   - 自動檢測條碼區域並裁切放大
   - 對比度增強
   - 圖片旋轉校正

2. **使用其他掃描庫**
   - ZXing (zxing2) - 專門的條碼解碼庫
   - 可能對靜態圖片有更好的支援

3. **分析 analyzeImage 與實時掃描的差異**
   - 實時掃描可以識別，照片模式不行
   - 可能是相機流的格式/解析度與靜態圖片不同

4. **研究 ML Kit InputImage 的最佳實踐**
   - 圖片格式（JPEG vs PNG）
   - 圖片解析度
   - InputImage.fromFilePath vs fromBytes

### 測試圖片
`assets/ISBN.jpg` - 清晰的 ISBN 條碼，實時掃描可識別，照片模式無法識別

## 三種掃描模式

### 1. 實時掃描 (Single Mode) - 預設
- 偵測到碼 → 立即停止掃描 → 顯示結果
- 無 AR overlay，直接顯示結果
- 支援單次掃描多個碼（可滾動列表）
- **優化後識別率改善**

### 2. AR 模式
- 透過工具列按鈕切換
- 顯示 AR overlay 標示偵測到的碼
- 累積多個碼直到用戶確認
- 使用多幀累積確保穩定性
- **優化後識別率改善**

### 3. 照片模式
- 從相簿選擇圖片掃描
- 支援縮放、平移查看
- 可裁切 viewport 重新掃描
- **目前識別率仍有問題**

### 連續掃描模式
- 自動保存並繼續掃描
- 可在設置中配置

## Multi-Frame Accumulation (AR Mode)

```dart
// Tunable parameters in scan_screen.dart
static const int _defaultFrameCount = 1;       // 降低閾值提高識別率
static const Duration _accumulationWindow = Duration(milliseconds: 1000);
```

**How it works:**
1. `DetectionSpeed.noDuplicates` - 過濾重複檢測
2. Accumulates detected codes over 1000ms window
3. 閾值已降低為 1 幀即可顯示
4. AR overlay shows unstable codes with reduced opacity

## Scanner Lifecycle

```dart
// Stop scanner when showing results (reduce CPU)
_controller?.stop();

// Resume scanner when user dismisses result sheet
_controller?.start();
```

## 對焦功能

實時掃描支援點擊對焦：
```dart
// 觸發對焦
_controller?.setFocusPoint(point);
```

**注意**: 對焦功能對識別率影響有限，主要問題在 ML Kit 本身。

## isActive Pattern

Screens with continuous resource usage must accept `isActive` parameter:
```dart
class ScanScreen extends StatefulWidget {
  final bool isActive;  // Controls camera start/stop
  ...
}
```

In `HomeScreen`:
```dart
ScanScreen(isActive: _currentIndex == 0),
```

## Semantic Type Detection

`BarcodeParser.parse()` detects content type:
- **ISBN**: 從內容提取 978/979 開頭的 13 位數字 + checksum 驗證（不依賴 format 參數）
- **URL**: http/https/www prefixes
- **WiFi**: `WIFI:S:ssid;T:type;P:password;;` format
- **Email/Phone/SMS/vCard/Geo**: Standard URI schemes

## 照片模式

採用 **ML Kit + ZXing 並行掃描**，合併結果（ZXing 優先）：

```dart
// 並行執行
final results = await Future.wait([
  _scanWithMLKit(path, bytes),
  _scanWithZXing(path, bytes),
]);

// 合併：ZXing 優先
final merged = <String, DetectedCode>{};
for (final code in mlKitCodes) merged[code.rawValue] = code;
for (final code in zxingCodes) merged[code.rawValue] = code;  // 覆蓋
```

檔案位置：`lib/widgets/scan/scan_gallery_mode.dart`

## MIG 4.0 發票掃描問題 ✅ 已解決

2026年起台灣統一發票採用 MIG 4.0 格式，ML Kit 無法辨識，但 ZXing 可以。

**關鍵修復**：flutter_zxing 的 `imageFormat` 預設是 `lum` 但內部傳 RGB，導致解碼失敗。
需明確設定 `imageFormat: ImageFormat.rgb`。

詳細記錄請參考：[MIG4.0.md](./MIG4.0.md)
