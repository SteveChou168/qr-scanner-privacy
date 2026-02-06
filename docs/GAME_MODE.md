# Game Mode: Cyber Fortress (賽博堡壘)

## 核心概念

Workshop 的旋轉球體化身為「堡壘」，玩家透過**旋轉手機**控制堡壘方向，防禦從四面八方湧來的敵方零件。本質上是一種**球體塔防**變體。

---

## 遊戲機制

### 基礎設定

| 元素 | 說明 |
|------|------|
| 堡壘 | Workshop 中心的旋轉球體 |
| 砲管 | 從球體表面伸出，自動攻擊射程內敵人 |
| 敵人 | 從外圍衝向球體的「零件」|
| 控制 | 雙模式可選（見下方）|

### 操作模式（設定可選）

| 模式 | 操作方式 | 適合場景 |
|------|----------|----------|
| 陀螺儀 | 旋轉手機 = 旋轉堡壘 | 沉浸體驗、站立遊玩 |
| 手勢 | 螢幕上畫圓 = 旋轉堡壘 | 躺著玩、陀螺儀故障 |

**手勢模式細節：**
- 順時針畫圓 → 球體右旋
- 逆時針畫圓 → 球體左旋
- 畫圓速度 → 控制旋轉速度
- 上下滑動 → 控制俯仰角（可選）

### 初始狀態

- 球體上只有 **1 根砲管**
- 玩家旋轉手機讓砲管對準來襲敵人
- 砲管自動開火（或點擊螢幕手動射擊）

### 敵人波次

```
Wave 1-5:   單方向進攻，熟悉操作
Wave 6-10:  雙方向夾擊
Wave 11+:   360° 全方位包圍
```

---

## 成長系統

### 積分獲取

- 擊敗零件 → 獲得積分
- 連擊加成 / 無傷害波次獎勵

### 砲管升級

| 等級 | 效果 |
|------|------|
| Lv.1 | 基礎攻擊 |
| Lv.2 | 射速 +20% |
| Lv.3 | 傷害 +30% |
| Lv.4 | 射程 +25% |
| Lv.5 | 雙發射擊 |

### 購買新砲管

- 消耗積分購買額外砲管
- **玩家自行決定插入位置**（球體表面任意點）
- 策略考量：集中火力 vs 分散防禦

---

## 特殊道具

| 道具 | 效果 | 持續時間 |
|------|------|----------|
| 護盾 | 抵擋 N 次傷害 | 直到消耗完 |
| 時間減速 | 敵人移動速度 -50% | 10 秒 |
| 全域掃射 | 所有砲管同時 360° 掃射 | 3 秒 |
| 磁鐵 | 自動吸收掉落積分 | 15 秒 |
| 修復 | 回復堡壘生命值 | 即時 |

---

## 視覺風格

延續 Workshop 的賽博龐克美學：
- 霓虹砲管光束
- 敵方零件帶有電路紋理
- 擊破時的粒子爆炸效果
- 球體表面的能量護盾波紋

---

## 技術考量

### 操作模式實作

```dart
// ===== 模式 1: 陀螺儀 =====
import 'package:sensors_plus/sensors_plus.dart';

gyroscopeEvents.listen((GyroscopeEvent event) {
  // event.x, event.y, event.z → 旋轉球體
  _rotateFortress(event.x, event.y);
});

// ===== 模式 2: 手勢畫圓 =====
GestureDetector(
  onPanUpdate: (details) {
    // 計算相對於球體中心的角度變化
    final center = Offset(screenWidth / 2, screenHeight / 2);
    final current = details.globalPosition;
    final previous = current - details.delta;

    // 計算角度差（順/逆時針）
    final angleDelta = _calculateAngleDelta(center, previous, current);
    _rotateFortress(angleDelta, 0);
  },
)

double _calculateAngleDelta(Offset center, Offset prev, Offset curr) {
  final prevAngle = atan2(prev.dy - center.dy, prev.dx - center.dx);
  final currAngle = atan2(curr.dy - center.dy, curr.dx - center.dx);
  return currAngle - prevAngle;
}
```

### 效能優化

- 敵人物件池（Object Pool）避免頻繁 GC
- 簡化碰撞檢測（球體 vs 點）
- 限制同時顯示敵人數量

---

## 與主 App 整合

| 整合點 | 說明 |
|--------|------|
| 入口 | Workshop 頁面的隱藏彩蛋 / 長按觸發 |
| CP 連動 | 遊戲積分可轉換為少量 CP |
| 零件收集 | 擊敗的零件可解鎖為 Workshop 裝飾 |
| 每日挑戰 | 限時模式，排行榜 |

---

## 開發階段

### Phase 1: 原型驗證
- [ ] 陀螺儀控制球體旋轉
- [ ] 單砲管射擊機制
- [ ] 基礎敵人生成與移動

### Phase 2: 核心玩法
- [ ] 積分系統
- [ ] 砲管升級
- [ ] 多砲管放置

### Phase 3: 豐富內容
- [ ] 特殊道具
- [ ] 敵人種類
- [ ] 波次設計

### Phase 4: 打磨
- [ ] 視覺特效
- [ ] 音效
- [ ] 與主 App 整合

---

## 命名候選

- Cyber Fortress（賽博堡壘）
- Sphere Defense（球體防線）
- Gyro Guardian（陀螺守護者）
- Orbital Siege（軌道攻城）
