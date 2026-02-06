# Challenge Mode (挑戰模式) - 完整規格書 v3

## 一、目前問題總結

### 嚴重問題
1. **按下 Challenge Button 只扣次數，不開始挑戰** - `_startChallenge()` 調用順序錯誤
2. **廣告系統未整合** - `_watchAdForQuota()` 只是 TODO，沒有實際調用 AdService
3. **UI 重複顯示** - Playing 狀態下 overlay 和 top cards 同時顯示 TIME/SCORE
4. **Countdown "GO!" 不顯示** - 狀態立即切換，沒有延遲

---

## 二、狀態機設計

```
┌─────────────────────────────────────────────────────────────────┐
│                      CHALLENGE MODE STATE MACHINE                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐                                                   │
│   │   IDLE   │◄────────────────────────────────────────────┐    │
│   └────┬─────┘                                              │    │
│        │                                                    │    │
│        │ [點擊左上 Quota Card]                              │    │
│        ▼                                                    │    │
│   ┌──────────────────────────────────────┐                  │    │
│   │ CONFIRM DIALOG (每次都問)             │                  │    │
│   │ "開始挑戰？" + 顯示剩餘次數            │                  │    │
│   │                                      │                  │    │
│   │ [取消]  [📺看廣告+5]  [開始 ×N]      │                  │    │
│   └────┬─────────┬─────────────┬─────────┘                  │    │
│        │         │             │                            │    │
│        │         │             │                            │    │
│   [取消]    [看廣告]      [開始]                            │    │
│        │         │             │                            │    │
│        │         ▼             │                            │    │
│        │   ┌───────────┐       │                            │    │
│        │   │ WATCH AD  │       │                            │    │
│        │   └─────┬─────┘       │                            │    │
│        │         │             │                            │    │
│        │         │ [+5次數]    │                            │    │
│        │         │             │                            │    │
│        │◄────────┴─────────────┘                            │    │
│        │                       │                            │    │
│        │                       │ [扣除 1 次數]              │    │
│        │                       ▼                            │    │
│        │                 ┌───────────┐                      │    │
│        │                 │ COUNTDOWN │  3 → 2 → 1 → GO!    │    │
│        │                 │ (覆蓋中心) │  直接蓋在 Spinner 上 │    │
│        │                 └─────┬─────┘                      │    │
│        │                       │                            │    │
│        │                       │ [GO! 顯示 500ms]           │    │
│        │                       ▼                            │    │
│        │                 ┌───────────┐                      │    │
│        │                 │  PLAYING  │  30秒倒數            │    │
│        │                 └─────┬─────┘                      │    │
│        │                       │                            │    │
│        │                   ┌───┴───┐                        │    │
│        │                   │       │                        │    │
│        │                   ▼       ▼                        │    │
│        │                 時間到   [Stop]                    │    │
│        │                   │       │                        │    │
│        │                   └───┬───┘                        │    │
│        │                       │                            │    │
│        │                       ▼                            │    │
│        │                 ┌───────────┐                      │    │
│        │                 │  RESULT   │                      │    │
│        │                 └─────┬─────┘                      │    │
│        │                       │                            │    │
│        │                   ┌───┴───┐                        │    │
│        │                   │       │                        │    │
│        │                   ▼       ▼                        │    │
│        │                [重玩]   [退出]                     │    │
│        │                   │       │                        │    │
│        │                   │       └────────────────────────┘    │
│        │                   │                                     │
│        │                   └──► CONFIRM DIALOG (重玩也要確認)    │
│        │                                                         │
│        └─────────────────────────────────────────────────────────┘
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 三、UI 佈局設計

### 卡片位置定義

| 位置 | IDLE 狀態 | PLAYING 狀態 |
|------|-----------|--------------|
| **左上** | 🎮 Quota Card (剩餘次數，點擊開始) | ⏱️ TIME Card (倒數計時) |
| **右上** | 🏆 Score Card (最高分，點擊看 TOP5) | 🎯 SCORE Card (即時分數) |

### IDLE 狀態 - Portrait

```
┌────────────────────────────────────────┐
│ ┌─────────────────┐ ┌─────────────────┐│
│ │  QUOTA CARD     │ │   SCORE CARD    ││
│ │  🎮 ×5          │ │   🏆 12,345     ││  ◄── 左上：剩餘次數
│ │  TAP TO START   │ │   TAP FOR TOP5  ││  ◄── 右上：最高分
│ └─────────────────┘ └─────────────────┘│
│                                        │
│          ┌─────────────────┐           │
│          │                 │           │
│          │    🔧 EMOJI     │           │  ◄── Spinner 區域
│          │   (可以轉動)     │           │
│          │                 │           │
│          └─────────────────┘           │
│                                        │
│                                        │
│     [🧭]                    [🔥]       │
│                                        │
│         ⚙️ WORKSHOP IDLE ⚙️            │
│          Tap spinner to forge          │
│                                        │
│            [ Tap to close ]            │
└────────────────────────────────────────┘
```

### 確認對話框 (參考生成頁設計)

```
┌────────────────────────────────────────┐
│                                        │
│    ┌────────────────────────────────┐  │
│    │        🎮 開始挑戰？            │  │
│    │                                │  │
│    │     30秒內盡可能轉動轉盤        │  │
│    │     累積最高分數！              │  │
│    │                                │  │
│    │     剩餘次數: 5                 │  │
│    │                                │  │
│    │ ┌────────┐ ┌────────┐ ┌──────┐│  │
│    │ │  取消  │ │📺+5次  │ │開始! ││  │  ◄── 三個按鈕
│    │ └────────┘ └────────┘ └──────┘│  │
│    │                                │  │
│    └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘

按鈕說明：
- 取消: 關閉對話框，回到 IDLE
- 📺+5次: 觀看廣告獲得 +5 次數，然後關閉對話框（不自動開始）
- 開始!: 扣除 1 次數，進入 COUNTDOWN
```

### 次數為 0 時的對話框

```
┌────────────────────────────────────────┐
│                                        │
│    ┌────────────────────────────────┐  │
│    │        🎮 開始挑戰？            │  │
│    │                                │  │
│    │     30秒內盡可能轉動轉盤        │  │
│    │     累積最高分數！              │  │
│    │                                │  │
│    │     ⚠️ 剩餘次數: 0              │  │  ◄── 紅色警告
│    │                                │  │
│    │ ┌────────────┐  ┌────────────┐ │  │
│    │ │    取消    │  │  📺+5次    │ │  │  ◄── 開始按鈕隱藏
│    │ └────────────┘  └────────────┘ │  │
│    │                                │  │
│    └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### TOP 5 對話框 (點擊右上 Score Card)

```
┌────────────────────────────────────────┐
│                                        │
│    ┌────────────────────────────────┐  │
│    │      🏆 TOP 5 SCORES 🏆        │  │
│    │                                │  │
│    │   #1  🥇 150,000   02/05       │  │
│    │   #2      123,456   02/04       │  │
│    │   #3       98,765   02/03       │  │
│    │   #4       87,654   02/02       │  │
│    │   #5       76,543   02/01       │  │
│    │                                │  │
│    │  ┌────────────────────────────┐│  │
│    │  │           OK               ││  │
│    │  └────────────────────────────┘│  │
│    │                                │  │
│    └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### COUNTDOWN 狀態 - 覆蓋在 Spinner 上

```
┌────────────────────────────────────────┐
│ ┌─────────────────┐ ┌─────────────────┐│
│ │  🎮 ×4          │ │   🏆 12,345     ││  ◄── 次數已扣除
│ │  (dimmed)       │ │   (dimmed)      ││
│ └─────────────────┘ └─────────────────┘│
│                                        │
│          ┌─────────────────┐           │
│          │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│           │
│          │▓               ▓│           │
│          │▓   ╔═══════╗   ▓│           │
│          │▓   ║   3   ║   ▓│           │  ◄── 大數字覆蓋中心
│          │▓   ╚═══════╝   ▓│           │      半透明黑色遮罩
│          │▓  (cyan glow)  ▓│           │
│          │▓               ▓│           │
│          │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│           │
│          └─────────────────┘           │
│                                        │
│     [🧭]                    [🔥]       │  ◄── 按鈕 disabled
│                                        │
│         🎮 GET READY! 🎮               │
│                                        │
└────────────────────────────────────────┘

時序：
  0.0s: "3" + lightImpact
  1.0s: "2" + lightImpact
  2.0s: "1" + lightImpact
  3.0s: "GO!" + heavyImpact (放大 + 金色光暈)
  3.5s: 進入 PLAYING
```

### PLAYING 狀態

```
┌────────────────────────────────────────┐
│ ┌─────────────────┐ ┌─────────────────┐│
│ │   ⏱️ TIME       │ │   🎯 SCORE      ││
│ │     25.3        │ │    45,678       ││  ◄── 左上：倒數計時
│ │   (cyan glow)   │ │   (cyan glow)   ││  ◄── 右上：即時分數
│ └─────────────────┘ └─────────────────┘│
│                                        │
│          ┌─────────────────┐           │
│          │                 │           │
│          │   SPINNER AREA  │           │  ◄── 全力轉動！
│          │   ⚡ RPM: 4500   │           │
│          │   (火焰效果)     │           │
│          │                 │           │
│          └─────────────────┘           │
│                                        │
│                                        │
│          ┌─────────────────┐           │
│          │    ⏹️ STOP      │           │  ◄── 可以提前結束
│          └─────────────────┘           │
│                                        │
│     [🧭]                    [🔥]       │
│                                        │
│         🎮 CHALLENGE! 🎮               │
│                                        │
└────────────────────────────────────────┘

注意：
- 左上: TIME card (倒數計時，紅色警告 < 10秒)
- 右上: SCORE card (即時分數)
- 不需要 overlay 的 _buildPlayingDisplay()
```

### RESULT 狀態

```
┌────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│ ▓                                    ▓│
│ ▓    ┌────────────────────────────┐  ▓│
│ ▓    │                            │  ▓│
│ ▓    │    🎉 NEW RECORD! 🎉       │  ▓│
│ ▓    │                            │  ▓│
│ ▓    │        SCORE               │  ▓│
│ ▓    │       123,456              │  ▓│
│ ▓    │                            │  ▓│
│ ▓    │    BEST: 150,000  #2       │  ▓│
│ ▓    │                            │  ▓│
│ ▓    │  ┌────────┐  ┌────────┐   │  ▓│
│ ▓    │  │ RETRY  │  │  EXIT  │   │  ▓│
│ ▓    │  │  ×4    │  │        │   │  ▓│  ◄── RETRY 顯示剩餘次數
│ ▓    │  └────────┘  └────────┘   │  ▓│
│ ▓    │                            │  ▓│
│ ▓    └────────────────────────────┘  ▓│
│ ▓                                    ▓│
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└────────────────────────────────────────┘

RETRY 按鈕：
- 次數 > 0: 顯示 "RETRY ×N"，點擊彈出確認對話框
- 次數 = 0: 顯示 "📺 +5" 按鈕，點擊看廣告
```

---

## 四、左上角 Quota Card 設計

### IDLE 時 - 顯示次數 + 點擊開始

```dart
Widget _buildQuotaCard(YearConfig yearConfig, {double scale = 1.0, Key? key}) {
  final quota = GrowthService.instance.challengeQuota;
  final hasQuota = quota > 0;

  return GestureDetector(
    onTap: _showChallengeConfirmDialog,  // ← 點擊觸發確認對話框
    child: Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: hasQuota
              ? Colors.cyan.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎮', style: TextStyle(fontSize: 14 * scale)),
              SizedBox(width: 4 * scale),
              Text(
                '×$quota',
                style: TextStyle(
                  color: hasQuota ? Colors.cyan : Colors.red,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          Text(
            hasQuota ? 'TAP TO START' : 'NO QUOTA',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 8 * scale,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### PLAYING 時 - 切換為 TIME Card

保持原有的 `_buildChallengeTimeCard()`

---

## 五、右上角 Score Card 設計

### IDLE 時 - 顯示最高分 + 點擊看 TOP5

```dart
Widget _buildHighScoreCard(YearConfig yearConfig, {double scale = 1.0, Key? key}) {
  final topScore = GrowthService.instance.challengeScores.isNotEmpty
      ? GrowthService.instance.challengeScores.first.score
      : 0;

  return GestureDetector(
    onTap: _showScoreRecord,  // ← 點擊顯示 TOP5
    child: Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: yearConfig.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 14 * scale)),
              SizedBox(width: 4 * scale),
              Text(
                _formatScore(topScore),
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          Text(
            'TAP FOR TOP5',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 8 * scale,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### PLAYING 時 - 切換為即時 SCORE Card

保持原有的 `_buildChallengeScoreCard()`

---

## 六、確認對話框實現 (參考 generator_screen.dart)

```dart
Future<void> _showChallengeConfirmDialog() async {
  if (_challengeState != _ChallengeState.idle) return;
  if (_isForging) return;

  final quota = GrowthService.instance.challengeQuota;
  final hasQuota = quota > 0;

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.cyan.withValues(alpha: 0.5)),
      ),
      title: Text(
        '🎮 ${AppText.challengeStart}',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.cyan, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppText.challengeDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${AppText.challengeQuotaLabel}: ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              Text(
                '$quota',
                style: TextStyle(
                  color: hasQuota ? Colors.cyan : Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        // 取消按鈕
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'cancel'),
          child: Text(
            AppText.cancel,
            style: TextStyle(color: Colors.white54),
          ),
        ),
        // 看廣告按鈕
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'watch_ad'),
          child: Text(
            '📺 +5',
            style: TextStyle(color: Colors.amber),
          ),
        ),
        // 開始按鈕 (次數為0時隱藏)
        if (hasQuota)
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'start'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.cyan,
            ),
            child: Text(
              '${AppText.challengeGo}!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    ),
  );

  // 處理結果
  switch (result) {
    case 'start':
      await _beginCountdown();
      break;
    case 'watch_ad':
      await _watchAdForQuota();
      break;
    case 'cancel':
    default:
      // 什麼都不做
      break;
  }
}

Future<void> _watchAdForQuota() async {
  // 檢查今日是否還能看廣告
  final adService = AdService();
  final canWatch = await adService.canWatchAdProactively();

  if (!canWatch) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppText.adDailyLimitReached),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // 播放廣告
  final rewardAmount = await adService.showRewardedAd();

  if (rewardAmount > 0) {
    await adService.incrementAdWatchCount();
    await GrowthService.instance.addChallengeQuotaFromAd();

    if (!mounted) return;
    setState(() {});
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 +5 ${AppText.challengeQuotaAdded}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

Future<void> _beginCountdown() async {
  // 扣除次數
  final success = await GrowthService.instance.useChallengeQuota();
  if (!success) return;

  HapticFeedback.mediumImpact();
  setState(() {
    _challengeState = _ChallengeState.countdown;
    _countdownValue = 3;
    _challengeScore = 0;
    _challengeTimeLeft = _challengeDuration;
    _isNewHighScore = false;
  });

  _runCountdown();
}
```

---

## 七、Countdown 覆蓋實現

```dart
// 在 _buildForgeCenter 的 Stack 中添加
Widget _buildForgeCenter(...) {
  // ... 現有代碼 ...

  return GestureDetector(
    // ... 現有手勢 ...
    child: Stack(
      alignment: Alignment.center,
      children: [
        // 原有的所有 Spinner 內容 layers...
        // Layer 0: Outer neon wheel segments
        // Layer 1: SweepGradient trail effect
        // ...etc

        // 最後一層：Countdown 覆蓋 (蓋在所有東西上面)
        if (_challengeState == _ChallengeState.countdown)
          _buildCountdownOverlay(outerSize),
      ],
    ),
  );
}

Widget _buildCountdownOverlay(double size) {
  final text = _countdownValue > 0 ? '$_countdownValue' : 'GO!';
  final isGo = _countdownValue <= 0;

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black.withValues(alpha: 0.75),
    ),
    child: Center(
      child: AnimatedScale(
        scale: isGo ? 1.3 : 1.0,
        duration: Duration(milliseconds: 200),
        child: Text(
          text,
          style: TextStyle(
            color: isGo ? Colors.amber : Colors.cyan,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: (isGo ? Colors.amber : Colors.cyan).withValues(alpha: 0.8),
                blurRadius: 30,
              ),
              Shadow(
                color: (isGo ? Colors.amber : Colors.cyan).withValues(alpha: 0.5),
                blurRadius: 60,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

---

## 八、修正後的 _runCountdown

```dart
void _runCountdown() {
  Future.delayed(const Duration(seconds: 1), () {
    if (!mounted || _challengeState != _ChallengeState.countdown) return;

    if (_countdownValue > 1) {
      setState(() {
        _countdownValue--;
      });
      HapticFeedback.lightImpact();
      _runCountdown();
    } else if (_countdownValue == 1) {
      setState(() {
        _countdownValue = 0; // 顯示 "GO!"
      });
      HapticFeedback.heavyImpact();

      // GO! 顯示 500ms 後進入 playing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _challengeState = _ChallengeState.playing;
        });
      });
    }
  });
}
```

---

## 九、Portrait Layout 更新

```dart
Widget _buildPortraitLayout(...) {
  return Stack(
    children: [
      // 左上 - Quota 或 TIME
      Positioned(
        top: 16,
        left: 16,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _challengeState == _ChallengeState.playing
              ? _buildChallengeTimeCard(yearConfig, key: const ValueKey('time'))
              : _buildQuotaCard(yearConfig, key: const ValueKey('quota')),  // ← 左上 Quota
        ),
      ),

      // 右上 - HighScore 或 即時 SCORE
      Positioned(
        top: 16,
        right: 16,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _challengeState == _ChallengeState.playing
              ? _buildChallengeScoreCard(yearConfig, key: const ValueKey('score'))
              : _buildHighScoreCard(yearConfig, key: const ValueKey('highscore')),  // ← 右上最高分
        ),
      ),

      // 中心 - Forge/Spinner (含 countdown overlay)
      Center(
        child: _buildForgeCenter(currentPart, yearConfig, service.animationPhase),
      ),

      // 底部按鈕行
      Positioned(
        bottom: 100,
        left: 16,
        child: _buildGravityLockButton(yearConfig),
      ),

      // STOP 按鈕 (僅 playing 時顯示)
      if (_challengeState == _ChallengeState.playing)
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: Center(child: _buildStopButton()),
        ),

      Positioned(
        bottom: 100,
        right: 16,
        child: _buildFireButton(yearConfig),
      ),

      // 底部狀態文字
      Positioned(
        bottom: 56,
        left: 0,
        right: 0,
        child: _buildBottomStatus(yearConfig),
      ),

      // Result overlay (僅 result 時顯示)
      if (_challengeState == _ChallengeState.result)
        _buildResultOverlay(),
    ],
  );
}
```

---

## 十、需要刪除/簡化的代碼

### 刪除
- `_buildChallengeButton()` - 改用左上 Quota Card 觸發
- `_buildPlayingDisplay()` - 不再需要，PLAYING 時用 top cards
- `_buildHighScoreHint()` - 整合到右上 HighScore Card

### 簡化
- `_buildChallengeOverlay()` - 只處理 RESULT 狀態

```dart
Widget _buildChallengeOverlay() {
  // 只在 RESULT 時顯示覆蓋層
  if (_challengeState != _ChallengeState.result) {
    return const SizedBox.shrink();
  }

  return Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: _buildResultDisplay(),
    ),
  );
}
```

---

## 十一、檔案修改清單

| 檔案 | 修改內容 |
|------|----------|
| `workshop_view.dart` | 新增 `_buildQuotaCard()` 顯示在左上 |
| `workshop_view.dart` | 新增 `_buildHighScoreCard()` 顯示在右上 |
| `workshop_view.dart` | 新增 `_showChallengeConfirmDialog()` 確認對話框 |
| `workshop_view.dart` | 修改 `_watchAdForQuota()` 整合 AdService |
| `workshop_view.dart` | 新增 `_buildCountdownOverlay()` 覆蓋在 Spinner 上 |
| `workshop_view.dart` | 修改 `_runCountdown()` 讓 GO! 顯示 500ms |
| `workshop_view.dart` | 刪除 `_buildChallengeButton()` |
| `workshop_view.dart` | 刪除 `_buildPlayingDisplay()` |
| `workshop_view.dart` | 刪除 `_buildHighScoreHint()` |
| `workshop_view.dart` | 簡化 `_buildChallengeOverlay()` 只處理 result |
| `workshop_view.dart` | 更新 Portrait/Landscape Layout |
| `app_text.dart` | 新增 `challengeStart`, `challengeDescription`, `challengeQuotaLabel`, `challengeGo`, `challengeQuotaAdded` |

---

## 十二、測試檢查清單

- [ ] IDLE 時左上顯示 Quota Card (🎮 ×5, TAP TO START)
- [ ] IDLE 時右上顯示 HighScore Card (🏆 12,345, TAP FOR TOP5)
- [ ] 點擊左上 Quota Card 彈出確認對話框
- [ ] 點擊右上 HighScore Card 彈出 TOP5 對話框
- [ ] 確認對話框顯示三個按鈕：取消 / 📺+5 / 開始
- [ ] 次數為 0 時，開始按鈕隱藏
- [ ] 點擊 📺+5 看廣告後次數增加，對話框關閉
- [ ] 點擊開始後，扣除次數，進入 COUNTDOWN
- [ ] COUNTDOWN 數字覆蓋在 Spinner 中心（半透明黑底）
- [ ] 3-2-1-GO! 正確顯示，GO! 放大 + 金色 + 持續 500ms
- [ ] PLAYING 時左上變成 TIME，右上變成 SCORE
- [ ] PLAYING 時出現 STOP 按鈕
- [ ] TIME < 10秒時變紅色
- [ ] 時間到或點 STOP 後顯示 RESULT
- [ ] RESULT 的 RETRY 按鈕顯示剩餘次數 (×N)
- [ ] 點擊 RETRY 彈出確認對話框（不是直接開始）
- [ ] 次數為 0 時 RETRY 變成 📺+5 按鈕
