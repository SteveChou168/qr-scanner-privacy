# Image Optimization

## Thumbnail Caching (Memory Optimization)

List views use `cacheWidth`/`cacheHeight` to limit decoded image size:

```dart
// scan_history_card.dart - 60x60 display
Image.file(
  file,
  cacheWidth: 120,   // 2x for retina
  cacheHeight: 120,
);

// codex_grid_card.dart - ~100x100 display
Image.file(
  file,
  cacheWidth: 200,
  cacheHeight: 200,
);
```

**Why**: Without this, a 4000x3000 original image decodes fully into memory. With 50,000 records scrolling, this would cause memory issues.

## Screenshot Compression (Storage Optimization)

Scan screenshots are compressed before saving:

```dart
// scan_screen.dart - _saveScreenshot()
final compressedData = await FlutterImageCompress.compressWithList(
  imageData,
  minWidth: 800,    // Sufficient for QR/barcode recognition
  minHeight: 600,
  quality: 75,      // High contrast codes don't need high quality
  format: CompressFormat.jpeg,
);
```

| | Before | After |
|---|--------|-------|
| Per image | 300-500KB | 30-80KB |
| 50,000 records | 15-25GB | 1.5-4GB |

**Note**: 800px width is sufficient for QR code decoding (minimum ~100-200px needed).

## Full Image Viewer

`_PhotoViewerScreen` in `scan_detail_screen.dart`:
- Loads **full resolution** for zoom (no cacheWidth)
- `InteractiveViewer` supports 0.5x-4x zoom
- Download button saves to system gallery via `gal` package
