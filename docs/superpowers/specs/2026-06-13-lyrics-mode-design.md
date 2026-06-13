# Waveland 歌词模式设计文档

**日期**: 2026-06-13
**状态**: 待确认
**前序设计**: 2026-06-12-waveland-design.md

---

## 1. 功能概述

点击灵动岛中音符图标（`󰽰`）在 **普通模式** 和 **歌词模式** 之间切换。

| 模式 | 显示内容 | 岛形态 |
|------|----------|--------|
| 普通模式 | 工作区 + 音符图标 + 时钟 + 专辑封面/控制 + 托盘 + 通知铃 | 药丸，宽 280-420px |
| 歌词模式 | 左声波 + 音符图标 + 歌词滚动 + 右声波 | 药丸，宽约 320px |

---

## 2. 歌词模式布局

```
歌词模式 island:
┌──────────────────────────────────────────────┐
│ ║║ ║║ ║║  󰽰  ♪ 原来你是我最想留住的幸运 ♪  ║║ ║║ ║║ │
│ 左声波     音符    ←── 歌词水平滚动 ──→     右声波   │
└──────────────────────────────────────────────┘
```

**规则：**
- 左声波图 `anchors.left: parent.left + 6`（与普通模式一致）
- 右声波图 `anchors.right: parent.right + 6`（与普通模式一致）
- 音符图标紧接左声波右侧
- 歌词文本填充剩余空间，单行水平滚动
- 歌词模式下其他组件（工作区、时钟、专辑封面、控制钮、托盘、通知铃）opacity→0，visible→false

---

## 3. 歌词数据流

```
MprisPlayer.trackTitle + trackArtist
        │
        ▼
LRCLIB API (curl GET)
  http://lrclib.net/api/get?track_name=...&artist_name=...
        │
        ▼
解析 JSON → 提取 syncedLyrics (LRC 格式时间戳文本)
        │
        ▼
MusicModule._lrcLines: [{timeMs, text}, ...]
        │
        ▼
Timer 200ms 读取 MprisPlayer.position (微秒)
  匹配当前句 → currentLyricIndex
        │
        ▼
IslandLayout 歌词区显示当前句 + marquee 滚动
```

### 3.1 LRCLIB API

**请求：**
```bash
curl -G "https://lrclib.net/api/get" \
  --data-urlencode "track_name=$TITLE" \
  --data-urlencode "artist_name=$ARTIST" \
  --data-urlencode "duration=$DURATION_SEC"
```

**响应字段：**
- `syncedLyrics`: 带时间戳的 LRC 文本（如 `[00:12.34]第一句歌词\n[00:18.90]第二句歌词`）
- `plainLyrics`: 无时间戳的纯文本（备用）

**限速：** 每分钟约 10 次请求，需缓存已获取的歌词。

### 3.2 歌词缓存策略

```
MusicModule._lyricsCache: { "trackTitle||trackArtist": [lrcLines] }
```
- 切歌时先查缓存，命中则直接使用
- 未命中再发 curl 请求
- 缓存上限 20 条，超出删除最旧条目

---

## 4. 组件改动

### 4.1 MusicModule.qml 新增属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `lyricsMode` | `bool` | 是否在歌词模式（初始 false） |
| `_lrcLines` | `var` (array of objects) | 已解析的歌词行 `[{timeMs: int, text: string}]` |
| `_currentLyricIndex` | `int` | 当前歌词句索引（-1 表示无匹配） |
| `_currentLyricText` | `string` | 当前歌词文本（绑定到 _lrcLines[_currentLyricIndex].text） |
| `_displayText` | `string` | 歌词区实际显示的文字：有歌词用歌词，无歌词回退 `trackTitle - trackArtist` |
| `_lyricsCache` | `var` (object) | `{"title||artist": [{timeMs, text}]}` |
| `_lyricsLoading` | `bool` | 是否正在获取歌词 |

### 4.2 MusicModule.qml 新增函数

```
function toggleLyricsMode()          // 切换 lyricsMode
function fetchLyrics(title, artist)  // 调用 curl 获取歌词
function parseLrc(lrcText)           // 解析 LRC → [{timeMs, text}]
function updateCurrentLyric()        // 根据 position 匹配当前句
```

### 4.3 歌词获取实现

使用 `Quickshell.Io.Process` 调用 `curl`：

```qml
Process {
    id: lrcProcess
    command: "curl"
    running: false
    
    // 发起请求:
    function fetch(title, artist) {
        var args = ["-G", "https://lrclib.net/api/get",
                    "--data-urlencode", "track_name=" + title,
                    "--data-urlencode", "artist_name=" + artist]
        lrcProcess.arguments = args
        lrcProcess.running = true
    }
    
    // onFinished: 读取 stdout, JSON.parse, 调用 parseLrc
}
```

### 4.4 歌词匹配 Timer

```qml
Timer {
    id: lyricTimer
    interval: 200
    running: musicModule.lyricsMode && musicModule.isPlaying && musicModule._lrcLines.length > 0
    repeat: true
    onTriggered: {
        if (!musicModule.activePlayer) return
        var pos = musicModule.activePlayer.position / 1000 // 转毫秒
        var idx = musicModule._lrcLines.length - 1
        for (var i = 0; i < musicModule._lrcLines.length; i++) {
            if (musicModule._lrcLines[i].timeMs > pos) {
                idx = Math.max(0, i - 1)
                break
            }
        }
        if (idx !== musicModule._currentLyricIndex) {
            musicModule._currentLyricIndex = idx
        }
    }
}
```

### 4.5 IslandLayout.qml 改动

**新增属性：**
```qml
property bool lyricsMode: musicModule.lyricsMode
```

**音符图标：**
- 普通模式：位置不变（leftPanel 内 `anchors.right: parent.right`）
- 歌词模式：移出 leftPanel，放入歌词层，锚定在左声波右侧

**歌词模式布局组件（新增）：**
```qml
Item {
    id: lyricsOverlay
    anchors.fill: parent
    visible: musicModule.lyricsMode
    opacity: musicModule.lyricsMode ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; ... } }
    
    // 音符图标
    Text {
        text: "󰽰"
        anchors { left: leftWaves.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
        // click → musicModule.toggleLyricsMode()
    }
    
    // 歌词滚动文本
    Text {
        id: lyricText
        anchors { left: noteIcon.right; leftMargin: 12; right: rightWaves.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: musicModule._currentLyricText || (musicModule.trackTitle ? musicModule.trackTitle + " - " + musicModule.trackArtist : "♪ 等待歌词...")
        color: "#cdd6f4"
        font.pixelSize: 14
        elide: Text.ElideNone
        clip: true
        // marquee 滚动: NumberAnimation on x
    }
}
```

**普通模式组件隐藏：**
- `layoutContent` opacity → 0 当 `lyricsMode` 为 true
- 声波图始终显示（不受 lyricsMode 影响）

**recalc() 修改：**
```qml
function recalc() {
    // 通知中心优先
    if (workspaceModule.notifCenterExpanded) { ... }
    
    // 歌词模式宽度
    if (musicModule.lyricsMode) {
        targetWidth = 320 + (hovered ? hoverBonusW : 0)
        targetHeight = 42 + (hovered ? hoverBonusH : 0)
        pillRadius = 0
        return
    }
    
    // 原有逻辑...
}
```

---

## 5. 动画规范

| 过渡 | 属性 | 动画 | 时长 |
|------|------|------|------|
| 进入歌词模式 | lyricsOverlay.opacity | NumberAnimation | 200ms, Easing.InOutQuad |
| 退出歌词模式 | lyricsOverlay.opacity | NumberAnimation | 200ms, Easing.InOutQuad |
| 布局组件隐藏 | layoutContent._opacity | NumberAnimation | 200ms, Easing.InOutQuad |
| 歌词切换（换句） | 文本 x 归位 + 新文本 opacity | NumberAnimation | 300ms, Easing.OutQuad |
| 歌词 marquee | lyricText.x | NumberAnimation | 循环，根据文本长度计算 duration |

### 5.1 marquee 实现方案

不是真正的 HTML marquee，而是：

```
1. 歌词文本 implicitWidth 可能 > 可用空间
2. 文本先显示在左边缘，停留 500ms
3. 然后 x 从 0 动画到 -(implicitWidth - availableWidth)，循环播放
4. 换句时重置 x 到 0，再重新滚动
```

或者更简单：直接设置 `elide: Text.ElideRight`，不滚动，只在文本过长时截断末尾加 `…`。

> **推荐：先用 elide 方案，简单可靠。后续可迭代为 marquee。**

---

## 6. 边缘情况

| 场景 | 处理 |
|------|------|
| 无歌词数据 | 显示 `trackTitle + " - " + trackArtist`（回退到歌曲名+作者） |
| 歌词 API 请求失败 | 显示 `trackTitle + " - " + trackArtist`，3 秒后重试 |
| 尚未进入歌词模式就切歌 | 缓存新歌歌词，下次切到歌词模式直接显示 |
| 歌词模式中切歌 | 重新 fetch 新歌歌词，过渡期间显示 "♪ 加载中..." |
| 歌词模式中停止播放 | currentLyricIndex 保持不动，Timer 暂停 |
| Mpris.position 不准确 | 匹配最近的时间戳（向前最近一句） |

---

## 7. 文件改动清单

| 文件 | 改动 |
|------|------|
| `modules/MusicModule.qml` | 新增 ~80 行：lyricsMode、LRC 解析、curl Process、lyric Timer、缓存逻辑 |
| `modules/IslandLayout.qml` | 新增 ~40 行：lyricsOverlay 组件、recalc() 歌词模式分支、layoutContent 条件显示 |

---

## 8. 实施顺序

1. MusicModule 新增 `lyricsMode` 切换属性
2. MusicModule 实现 `curl` 歌词获取 + LRC 解析 + 缓存
3. MusicModule 实现 `currentLyricIndex` 匹配 Timer
4. IslandLayout 新增 `lyricsOverlay` + 声波保留 + 隐藏其他组件
5. IslandLayout recalc() 歌词模式宽度
6. 动画完善 + 边缘情况处理
7. 测试
