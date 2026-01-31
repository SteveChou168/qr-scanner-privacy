# 历史卡片设计规格

> 参考 tpml_app 的 `OutlookStyleNoteTile` 设计

---

## 一、设计对比

| 元素 | tpml_app 笔记卡片 | QR Scanner 历史卡片 |
|------|------------------|-------------------|
| **左侧缩略图** | 笔记附图 (56x56) | QR Code 截图 (56x56) |
| **主标题** | 笔记标题/第一行 | 语意类型 + 图标 (📚 书籍 ISBN) |
| **内容预览** | 笔记内容第一行 | 解析出的文字 |
| **元数据行** | 图片数量 + 地点 | 条码格式 + 地点 |
| **右侧** | 日期 + 删除按钮 | 日期 + 操作按钮 |

---

## 二、卡片布局

```
┌──────────────────────────────────────────────────────────────┐
│ ┌────────┐                                                   │
│ │        │  📚 书籍 ISBN                           14:30    │
│ │  QR    │  9784567890123                                    │
│ │ IMAGE  │  ─────────────────────────────────────            │
│ │        │  EAN-13 · 台北市, 大安區               [复制][⋮] │
│ └────────┘                                                   │
└──────────────────────────────────────────────────────────────┘
   56x56px      主内容区（Expanded）                  右侧48px
```

---

## 三、视觉规格

### 3.1 卡片容器

```dart
Container(
  margin: const EdgeInsets.symmetric(vertical: 4),
  decoration: BoxDecoration(
    color: tokens.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: tokens.border,
      width: 1,
    ),
  ),
  // ...
)
```

### 3.2 左侧 - QR Code 截图

```dart
// 尺寸: 56x56, 圆角: 10
Widget _buildThumbnail() {
  const double size = 56;
  const double radius = 10;

  if (imagePath != null) {
    // 有截图：显示截图
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(imagePath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  } else {
    // 无截图：显示类型图标
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          semanticType.icon,  // 📚 🔗 📞 etc.
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
```

### 3.3 中间 - 主内容区

```dart
Widget _buildContent() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // 第一行：类型标签 (带图标)
      _buildTypeLabel(),
      const SizedBox(height: 4),

      // 第二行：解析内容 (可点击)
      _buildParsedContent(),

      // 第三行：元数据 (格式 + 地点)
      if (_hasMetadata())
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _buildMetadataRow(),
        ),
    ],
  );
}
```

#### 类型标签样式

```dart
Widget _buildTypeLabel() {
  return Row(
    children: [
      // 图标
      Text(
        semanticType.icon,  // 📚
        style: TextStyle(fontSize: 14),
      ),
      const SizedBox(width: 4),
      // 主标签
      Text(
        record.primaryLabel,  // "书籍 ISBN"
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    ],
  );
}
```

#### 解析内容样式

```dart
Widget _buildParsedContent() {
  final displayText = record.displayText ?? record.rawText;

  // URL 类型：特殊样式（可点击）
  if (record.semanticType == SemanticType.url) {
    return GestureDetector(
      onTap: () => _openUrl(displayText),
      child: Text(
        displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // ISBN 类型：显示完整 ISBN
  if (record.semanticType == SemanticType.isbn) {
    return Row(
      children: [
        Expanded(
          child: Text(
            displayText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: tokens.textSecondary,
              fontFamily: 'monospace',  // 等宽字体
            ),
          ),
        ),
        // 快速搜索按钮
        GestureDetector(
          onTap: () => _searchIsbn(displayText),
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.search,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // 其他类型：普通文字
  return Text(
    displayText,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 14,
      color: tokens.textSecondary,
    ),
  );
}
```

#### 元数据行

```dart
Widget _buildMetadataRow() {
  return Row(
    children: [
      // 条码格式 (副标签)
      Text(
        record.secondaryLabel,  // "EAN-13"
        style: TextStyle(
          fontSize: 11,
          color: tokens.textTertiary,
        ),
      ),

      // 分隔点
      if (record.placeName != null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '·',
            style: TextStyle(color: tokens.textTertiary),
          ),
        ),

        // 地点
        Icon(Icons.location_on, size: 12, color: tokens.textTertiary),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            record.placeName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: tokens.textTertiary,
            ),
          ),
        ),
      ],
    ],
  );
}
```

### 3.4 右侧 - 日期与操作

```dart
Widget _buildRightSection() {
  return SizedBox(
    width: 48,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 日期/时间
        Text(
          _formatShortDate(record.scannedAt),
          style: TextStyle(
            fontSize: 11,
            color: tokens.textTertiary,
          ),
        ),
        const SizedBox(height: 8),

        // 操作按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 复制按钮
            _buildIconButton(
              icon: Icons.copy,
              onTap: () => _copyToClipboard(),
            ),
            // 更多操作
            _buildIconButton(
              icon: Icons.more_vert,
              onTap: () => _showMoreOptions(),
            ),
          ],
        ),
      ],
    ),
  );
}
```

---

## 四、完整组件代码

```dart
// lib/widgets/history/scan_history_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/scan_record.dart';

class ScanHistoryCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Function(String)? onCopy;
  final Function(String)? onOpenUrl;
  final Function(String)? onSearchIsbn;

  const ScanHistoryCard({
    Key? key,
    required this.record,
    required this.onTap,
    this.onLongPress,
    this.onCopy,
    this.onOpenUrl,
    this.onSearchIsbn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：缩略图
                _buildThumbnail(colorScheme),
                const SizedBox(width: 10),

                // 中间：内容
                Expanded(
                  child: _buildContent(context, colorScheme),
                ),
                const SizedBox(width: 8),

                // 右侧：日期 + 操作
                _buildRightSection(context, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme) {
    const double size = 56;
    const double radius = 10;

    if (record.imagePath != null) {
      return GestureDetector(
        onTap: () {
          // 点击查看大图
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(record.imagePath!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildPlaceholder(colorScheme, size, radius),
          ),
        ),
      );
    }
    return _buildPlaceholder(colorScheme, size, radius);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme, double size, double radius) {
    final typeColor = _getTypeColor(colorScheme);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          record.semanticType.icon,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Color _getTypeColor(ColorScheme colorScheme) {
    return switch (record.semanticType) {
      SemanticType.url => colorScheme.primary,
      SemanticType.email => Colors.orange,
      SemanticType.phone => Colors.green,
      SemanticType.wifi => Colors.blue,
      SemanticType.isbn => Colors.purple,
      SemanticType.vcard => Colors.teal,
      _ => colorScheme.outline,
    };
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 类型标签
        _buildTypeLabel(colorScheme),
        const SizedBox(height: 4),

        // 解析内容
        _buildParsedContent(context, colorScheme),

        // 元数据行
        if (_hasMetadata())
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _buildMetadataRow(colorScheme),
          ),
      ],
    );
  }

  Widget _buildTypeLabel(ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          record.semanticType.icon,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          record.primaryLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildParsedContent(BuildContext context, ColorScheme colorScheme) {
    final displayText = record.displayText ?? record.rawText;

    // URL: 带下划线，可点击
    if (record.semanticType == SemanticType.url) {
      return GestureDetector(
        onTap: () => onOpenUrl?.call(displayText),
        child: Text(
          displayText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: colorScheme.primary.withOpacity(0.5),
          ),
        ),
      );
    }

    // ISBN: 等宽字体 + 搜索按钮
    if (record.semanticType == SemanticType.isbn) {
      return Row(
        children: [
          Expanded(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onSearchIsbn?.call(displayText),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.search,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    // Wi-Fi: 显示 SSID
    if (record.semanticType == SemanticType.wifi) {
      return Row(
        children: [
          Icon(Icons.wifi, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    // 默认：普通文字
    return Text(
      displayText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  bool _hasMetadata() {
    return record.placeName != null && record.placeName!.isNotEmpty;
  }

  Widget _buildMetadataRow(ColorScheme colorScheme) {
    final tertiaryColor = colorScheme.outline.withOpacity(0.7);

    return Row(
      children: [
        // 条码格式
        Text(
          record.secondaryLabel,
          style: TextStyle(fontSize: 11, color: tertiaryColor),
        ),

        // 地点
        if (record.placeName != null && record.placeName!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('·', style: TextStyle(color: tertiaryColor)),
          ),
          Icon(Icons.location_on, size: 12, color: tertiaryColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              record.placeName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: tertiaryColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRightSection(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 日期
          Text(
            _formatShortDate(record.scannedAt),
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.outline.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          // 复制按钮
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: record.rawText));
                onCopy?.call(record.rawText);
              },
              icon: Icon(
                Icons.copy_outlined,
                size: 18,
                color: colorScheme.outline,
              ),
              padding: EdgeInsets.zero,
              tooltip: '复制',
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;

    if (isToday) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (dt.year == now.year) {
      return '${dt.month}/${dt.day}';
    } else {
      return '${dt.year}/${dt.month}/${dt.day}';
    }
  }
}
```

---

## 五、不同类型的卡片变体

### 5.1 URL 类型

```
┌──────────────────────────────────────────────────────────────┐
│ ┌────────┐                                                   │
│ │  🔗    │  🔗 网址                               14:30    │
│ │(截图)  │  https://example.com/page...  ← 蓝色下划线      │
│ │        │  ─────────────────────────────────────            │
│ │        │  QR Code · 台北市                     [复制]     │
│ └────────┘                                                   │
└──────────────────────────────────────────────────────────────┘
```

### 5.2 ISBN 类型

```
┌──────────────────────────────────────────────────────────────┐
│ ┌────────┐                                                   │
│ │  📚    │  📚 书籍 ISBN                          14:30    │
│ │(截图)  │  9784567890123              [🔍]  ← 搜索按钮     │
│ │        │  ─────────────────────────────────────            │
│ │        │  EAN-13 · 台北市, 大安區              [复制]     │
│ └────────┘                                                   │
└──────────────────────────────────────────────────────────────┘
```

### 5.3 Wi-Fi 类型

```
┌──────────────────────────────────────────────────────────────┐
│ ┌────────┐                                                   │
│ │  📶    │  📶 Wi-Fi                              14:30    │
│ │(截图)  │  📶 MyHomeNetwork              ← WiFi 图标       │
│ │        │  ─────────────────────────────────────            │
│ │        │  QR Code                              [连接]     │
│ └────────┘                                                   │
└──────────────────────────────────────────────────────────────┘
```

### 5.4 纯文字类型

```
┌──────────────────────────────────────────────────────────────┐
│ ┌────────┐                                                   │
│ │  📝    │  📝 文字                               14:30    │
│ │(灰底)  │  Hello World, this is some text...               │
│ │        │  ─────────────────────────────────────            │
│ │        │  QR Code                              [复制]     │
│ └────────┘                                                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 六、交互行为

| 操作 | 触发 | 行为 |
|------|------|------|
| **点击卡片** | `onTap` | 进入详情页 |
| **长按卡片** | `onLongPress` | 显示更多操作菜单 |
| **点击缩略图** | - | 查看原图大图 |
| **点击 URL** | `onOpenUrl` | 打开 WebView |
| **点击 ISBN 搜索** | `onSearchIsbn` | 搜索书籍信息 |
| **点击复制** | `onCopy` | 复制到剪贴板 + Toast |

---

## 七、详情页设计

点击卡片进入详情页，显示完整信息：

```
┌─────────────────────────────────────────┐
│  [←]  扫描详情                          │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │     QR Code 截图 (大图)          │    │
│  │     可放大查看                    │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  📚 书籍 ISBN                           │
│  ────────────────────────────────       │
│                                         │
│  内容                                    │
│  9784567890123                          │
│                           [复制] [分享]  │
│                                         │
│  格式: EAN-13                           │
│  时间: 2024/01/15 14:30                 │
│  地点: 台北市, 大安區                    │
│                                         │
│  备注                                    │
│  ┌─────────────────────────────────┐    │
│  │ 用户可添加备注...                │    │
│  └─────────────────────────────────┘    │
│                                         │
│  标签                                    │
│  [工作] [购物] [+添加]                   │
│                                         │
├─────────────────────────────────────────┤
│  [🔍 搜索此书]    [🌐 打开链接]          │
└─────────────────────────────────────────┘
```

---

*设计版本: 1.0*
*参考: tpml_app/lib/screens/memo_screen.dart:1079-1309*
