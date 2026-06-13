# 歌词模式实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 点击音符图标切换歌词模式，从 LRCLIB API 获取 LRC 歌词并逐句显示，通知/停止播放时自动退出。

**Architecture:** MusicModule 新增 lyricsMode 状态 + LRC 解析 + curl 获取 + Timer 匹配当前歌词句；IslandLayout 新增 lyricsOverlay 层（音符 + 歌词文本），歌词模式下隐藏其他组件。

**Tech Stack:** QML + quickshell Process (curl) + Mpris position + LRCLIB API

---

### Task 1: MusicModule 新增 lyricsMode 属性和切换函数

**Files:**
- Modify: `modules/MusicModule.qml`

- [ ] **Step 1: 添加 lyricsMode 和相关属性**

在 `MusicModule.qml` 的 `Item { id: musicModule }` 块内，`isPlaying` 等现有属性后添加：

```qml
    property bool lyricsMode: false
    property var _lrcLines: []
    property int _currentLyricIndex: -1
    property string _currentLyricText: ""
    property string _displayText: ""
    property var _lyricsCache: ({})
    property bool _lyricsLoading: false

    function toggleLyricsMode() {
        lyricsMode = !lyricsMode
    }

    function exitLyricsMode() {
        lyricsMode = false
    }

    signal lyricsModeChanged()
```

在 `Component.onCompleted: refreshState()` 之上添加自动退出监听：

```qml
    function checkAutoExit() {
        if (!lyricsMode) return
        if (workspaceModule.notifActive || workspaceModule.notifCenterExpanded || !isPlaying) {
            exitLyricsMode()
        }
    }
```

修改 `refreshState()` 在状态变化后调用 `checkAutoExit()`：

```qml
    function refreshState() {
        // ... existing code (players loop) ...
        // 在 found = false 处理之后、函数结束之前添加:
        checkAutoExit()
    }
```

- [ ] **Step 2: 提交**

```bash
git add modules/MusicModule.qml && git commit -m "feat: add lyricsMode toggle and auto-exit signals to MusicModule"
```

---

### Task 2: MusicModule 实现歌词获取和 LRC 解析

**Files:**
- Modify: `modules/MusicModule.qml`

- [ ] **Step 1: 添加 Process 调用 curl 获取歌词**

在 MusicModule.qml 末尾（Timer 之后）添加：

```qml
    property var _pendingTitle: ""
    property var _pendingArtist: ""

    function fetchLyrics(title, artist) {
        if (_lyricsLoading) return
        var cacheKey = title + "||" + artist
        if (_lyricsCache[cacheKey]) {
            _lrcLines = _lyricsCache[cacheKey]
            _currentLyricIndex = -1
            updateDisplayText()
            return
        }
        _pendingTitle = title
        _pendingArtist = artist
        _lyricsLoading = true
        lrcProcess.running = true
    }

    Quickshell.Io.Process {
        id: lrcProcess
        command: "curl"
        running: false

        property var args: []

        Component.onCompleted: {
            args = ["-G", "https://lrclib.net/api/get",
                    "--data-urlencode", "track_name=" + musicModule._pendingTitle,
                    "--data-urlencode", "artist_name=" + musicModule._pendingArtist]
            arguments = args
        }

        onFinished: {
            musicModule._lyricsLoading = false
            if (exitCode !== 0) {
                musicModule._lrcLines = []
                musicModule.updateDisplayText()
                return
            }
            try {
                var resp = JSON.parse(stdout)
                if (resp.syncedLyrics) {
                    var lines = musicModule.parseLrc(resp.syncedLyrics)
                    var cacheKey = musicModule._pendingTitle + "||" + musicModule._pendingArtist
                    var keys = Object.keys(musicModule._lyricsCache)
                    if (keys.length >= 20) delete musicModule._lyricsCache[keys[0]]
                    musicModule._lyricsCache[cacheKey] = lines
                    musicModule._lrcLines = lines
                    musicModule._currentLyricIndex = -1
                    musicModule.updateDisplayText()
                } else if (resp.plainLyrics) {
                    musicModule._lrcLines = [{timeMs: 0, text: resp.plainLyrics}]
                    musicModule._currentLyricIndex = -1
                    musicModule.updateDisplayText()
                } else {
                    musicModule._lrcLines = []
                    musicModule.updateDisplayText()
                }
            } catch(e) {
                musicModule._lrcLines = []
                musicModule.updateDisplayText()
            }
        }
    }
```

**注意：** 每次 `lrcProcess.running = true` 前需要更新 `arguments`。但由于 `Component.onCompleted` 只在首次运行，需要改为在 `fetchLyrics` 中直接设置 arguments。

修正 — 在 `fetchLyrics` 中设置：

```qml
    function fetchLyrics(title, artist) {
        if (_lyricsLoading) return
        var cacheKey = title + "||" + artist
        if (_lyricsCache[cacheKey]) {
            _lrcLines = _lyricsCache[cacheKey]
            _currentLyricIndex = -1
            updateDisplayText()
            return
        }
        _pendingTitle = title
        _pendingArtist = artist
        _lyricsLoading = true
        lrcProcess.arguments = ["-G", "https://lrclib.net/api/get",
            "--data-urlencode", "track_name=" + title,
            "--data-urlencode", "artist_name=" + artist]
        lrcProcess.running = true
    }

    Quickshell.Io.Process {
        id: lrcProcess
        command: "curl"
        running: false

        onFinished: {
            musicModule._lyricsLoading = false
            if (exitCode !== 0) {
                musicModule._lrcLines = []
                musicModule.updateDisplayText()
                return
            }
            try {
                var resp = JSON.parse(stdout)
                if (resp.syncedLyrics) {
                    var lines = musicModule.parseLrc(resp.syncedLyrics)
                    var cacheKey = musicModule._pendingTitle + "||" + musicModule._pendingArtist
                    var keys = Object.keys(musicModule._lyricsCache)
                    if (keys.length >= 20) {
                        var k = keys[0]
                        delete musicModule._lyricsCache[k]
                    }
                    musicModule._lyricsCache[cacheKey] = lines
                    musicModule._lrcLines = lines
                    musicModule._currentLyricIndex = -1
                    musicModule.updateDisplayText()
                } else if (resp.plainLyrics) {
                    musicModule._lrcLines = [{timeMs: 0, text: resp.plainLyrics}]
                    musicModule._currentLyricIndex = -1
                    musicModule.updateDisplayText()
                } else {
                    musicModule._lrcLines = []
                    musicModule.updateDisplayText()
                }
            } catch(e) {
                musicModule._lrcLines = []
                musicModule.updateDisplayText()
            }
        }
    }
```

- [ ] **Step 2: 添加 parseLrc 和 updateDisplayText 函数**

在 MusicModule.qml 中 `toggleLyricsMode()` 之后添加：

```qml
    function parseLrc(lrcText) {
        var lines = lrcText.split("\n")
        var result = []
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(/\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/)
            if (match) {
                var min = parseInt(match[1], 10)
                var sec = parseInt(match[2], 10)
                var cs = parseInt(match[3], 10)
                var ms = min * 60000 + sec * 1000 + (match[3].length === 2 ? cs * 10 : cs)
                var text = match[4].trim()
                if (text.length > 0) {
                    result.push({timeMs: ms, text: text})
                }
            }
        }
        result.sort(function(a, b) { return a.timeMs - b.timeMs })
        return result
    }

    function updateDisplayText() {
        if (_currentLyricIndex >= 0 && _currentLyricIndex < _lrcLines.length) {
            _currentLyricText = _lrcLines[_currentLyricIndex].text
            _displayText = _currentLyricText
        } else if (trackTitle) {
            _displayText = trackTitle + " - " + trackArtist
            _currentLyricText = ""
        } else {
            _displayText = ""
            _currentLyricText = ""
        }
    }
```

- [ ] **Step 3: 在切歌时触发歌词获取**

修改 `refreshState()`，在找到播放器并设置信息后添加：

```qml
    function refreshState() {
        var players = Mpris.players.values
        var found = false
        var newTitle = ""
        var newArtist = ""
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p && p.isPlaying) {
                if (!found) {
                    found = true
                    newTitle = p.trackTitle || ""
                    newArtist = p.trackArtist || ""
                    isPlaying = true
                    activePlayer = p
                    trackTitle = newTitle
                    trackArtist = newArtist
                    trackArtUrl = p.trackArtUrl || ""
                }
            }
        }
        if (!found) {
            isPlaying = false
            activePlayer = null
            trackTitle = ""
            trackArtist = ""
            trackArtUrl = ""
        }
        var key = newTitle + "||" + newArtist
        var oldKey = ""
        // 如果歌曲变了且有标题，尝试获取歌词
        if (found && newTitle && _lastFetchedKey !== key) {
            _lastFetchedKey = key
            _lrcLines = []
            _currentLyricIndex = -1
            updateDisplayText()
            fetchLyrics(newTitle, newArtist)
        }
        checkAutoExit()
    }
```

需要添加 `property string _lastFetchedKey: ""` 到属性区。

- [ ] **Step 4: 添加歌词匹配 Timer**

在 MusicModule.qml 末尾添加：

```qml
    Timer {
        id: lyricTimer
        interval: 200
        running: musicModule.lyricsMode && musicModule.isPlaying && musicModule._lrcLines.length > 0
        repeat: true
        onTriggered: {
            if (!musicModule.activePlayer) return
            var pos = musicModule.activePlayer.position / 1000
            var idx = musicModule._lrcLines.length - 1
            for (var i = 0; i < musicModule._lrcLines.length; i++) {
                if (musicModule._lrcLines[i].timeMs > pos) {
                    idx = Math.max(0, i - 1)
                    break
                }
            }
            if (idx !== musicModule._currentLyricIndex) {
                musicModule._currentLyricIndex = idx
                musicModule.updateDisplayText()
            }
        }
    }
```

- [ ] **Step 5: 进入歌词模式时也触发歌词获取**

在 `toggleLyricsMode()` 中：

```qml
    function toggleLyricsMode() {
        lyricsMode = !lyricsMode
        if (lyricsMode && trackTitle && _lrcLines.length === 0) {
            fetchLyrics(trackTitle, trackArtist)
        }
    }
```

- [ ] **Step 6: 提交**

```bash
git add modules/MusicModule.qml && git commit -m "feat: add LRC fetch, parse, and lyric matching timer"
```

---

### Task 3: IslandLayout 新增歌词模式布局

**Files:**
- Modify: `modules/IslandLayout.qml`

- [ ] **Step 1: 添加歌词模式 overlay 组件**

在 `rightWaves` Row 之后、`notifCenter` Item 之前添加：

```qml
    Item {
        id: lyricsOverlay
        anchors.fill: parent

        property real _opacity: musicModule.lyricsMode ? 1 : 0
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01

        Text {
            id: lyricsNoteIcon
            text: "󰽰"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 20
            color: "#cba6f7"
            anchors.left: leftWaves.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: musicModule.toggleLyricsMode()
            }
        }

        Text {
            id: lyricDisplayText
            anchors.left: lyricsNoteIcon.right
            anchors.leftMargin: 8
            anchors.right: rightWaves.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: musicModule._displayText
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
            elide: Text.ElideRight
            clip: true
        }
    }
```

- [ ] **Step 2: layoutContent 在歌词模式下隐藏**

修改 `layoutContent` Item 的 `_opacity` 和 `visible` 绑定，加入歌词模式判断：

将现有：
```qml
        property real _opacity: workspaceModule.notifCenterExpanded ? 0 : 1
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01
```

改为：
```qml
        property real _opacity: (workspaceModule.notifCenterExpanded || musicModule.lyricsMode) ? 0 : 1
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01
```

- [ ] **Step 3: recalc() 添加歌词模式分支**

在 `recalc()` 函数中，通知中心代码之后、原有逻辑之前添加：

```qml
    function recalc() {
        if (workspaceModule.notifCenterExpanded) {
            targetWidth = 420
            targetHeight = 240
            pillRadius = 16
            return
        }
        if (musicModule.lyricsMode) {
            pillRadius = 0
            targetWidth = 320 + (hovered ? hoverBonusW : 0)
            targetHeight = 42 + (hovered ? hoverBonusH : 0)
            return
        }
        // ... 原有 recalc 逻辑
```

- [ ] **Step 4: 添加歌词模式变化的连接**

在现有 `Connections` 块后添加，监听歌词模式变化触发 recalc：

```qml
    Connections {
        target: musicModule
        function onLyricsModeChanged() {
            layout.recalc()
        }
    }
```

- [ ] **Step 5: 声波图的 _musicOpacity 绑定加上 lyricsMode 条件**

将 `_musicOpacity` 属性改为包含歌词模式：

```qml
    property real _musicOpacity: (musicModule.isPlaying || musicModule.lyricsMode) ? 1 : 0
```

这样歌词模式下声波图保持可见（即使 `isPlaying` 为 false）。

- [ ] **Step 6: 提交**

```bash
git add modules/IslandLayout.qml && git commit -m "feat: add lyrics overlay layout with mode switching"
```

---

### Task 4: 验证

**Files:**
- Test: 运行 `qs -p ~/Projects/Waveland/shell.qml`

- [ ] **Step 1: 验证普通模式功能未受影响**

确认：工作区、时钟、系统托盘、通知铃、音乐波形和控制器在播放时正常显示。

- [ ] **Step 2: 验证歌词模式切换**

播放音乐 → 点击音符图标 `󰽰` → 确认进入歌词模式：
- 除声波图外所有组件隐藏
- 音符图标移到左声波右侧
- 中间显示歌词或 "歌曲名 - 作者"

- [ ] **Step 3: 验证退出歌词模式**

再次点击音符图标 → 确认回到普通模式。

- [ ] **Step 4: 验证自动退出**

在歌词模式中发送通知 → 确认自动回到普通模式。

- [ ] **Step 5: 提交** (如有修复)

```bash
git add -A && git commit -m "fix: lyrics mode edge case fixes"
```

---

### 自检

1. **Spec 覆盖**：所有需求覆盖 — 歌词模式切换、LRCLIB 获取、LRC 解析、时间匹配、marquee/elide、自动退出、间距、回退显示。
2. **占位符扫描**：无 TBD/TODO，所有代码完整。
3. **类型一致性**：`_lrcLines: [{timeMs, text}]` — 全文件一致使用；`_displayText` 在 MusicModule 定义，IslandLayout 中通过 `musicModule._displayText` 绑定。
