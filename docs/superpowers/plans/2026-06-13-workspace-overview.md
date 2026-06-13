# 工作区概览面板实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 点击工作区图标展开多列工作区面板，支持切换工作区、聚焦窗口、拖拽移动窗口。

**Architecture:** WorkspaceModule 新增 overviewExpanded + niri IPC Process；IslandLayout 新增 overviewOverlay（水平卡片 Repeater + 拖拽支持）+ recalc 分支。

**Tech Stack:** QML + quickshell Process (niri msg) + Niri event-stream + Drag/DropArea

---

### Task 1: WorkspaceModule 简化 hover + 新增 overviewExpanded

**Files:**
- Modify: `modules/WorkspaceModule.qml`

- [ ] **Step 1: 移除 hover 展开逻辑，精简 refreshDisplay**

找到 `refreshDisplay()` 函数，移除 hover 分支：

```qml
    function refreshDisplay() {
        _displayList = activeWsId >= 0 ? [activeWsId] : []
    }
```

删除 `property bool hovered: false`（第12行）。

删除 `collapseTimer` 和相关逻辑。

- [ ] **Step 2: 新增 overviewExpanded 属性**

```qml
    property bool overviewExpanded: false
```

- [ ] **Step 3: 更新 capsule 内的工作区图标 click 行为**

在 capsule Row 中的 delegate Text 的 MouseArea，将原来的 click 改为 toggle overview：

```qml
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: workspaceModule.overviewExpanded = !workspaceModule.overviewExpanded
    }
```

- [ ] **Step 4: 提交**

---

### Task 2: WorkspaceModule 新增辅助函数 + niri 命令

**Files:**
- Modify: `modules/WorkspaceModule.qml`

- [ ] **Step 1: 新增 getSortedWsList() 和 windowsOfWs()**

```qml
    function getSortedWsList() {
        var ids = Object.keys(_workspaces)
        ids.sort(function(a, b) {
            return (_workspaces[a] ? _workspaces[a].idx : 0) -
                   (_workspaces[b] ? _workspaces[b].idx : 0)
        })
        return ids
    }

    function windowsOfWs(wsId) {
        var wins = []
        var wids = Object.keys(_windows)
        for (var i = 0; i < wids.length; i++) {
            if (_windows[wids[i]].workspace_id == wsId) {
                wins.push({id: wids[i], title: _windows[wids[i]].title, app_id: _windows[wids[i]].app_id})
            }
        }
        return wins
    }
```

- [ ] **Step 2: 新增 niri 命令 Process**

```qml
    function niriAction(msg) {
        niriProc.command = ["niri", "msg", "action", msg]
        niriProc.running = true
    }

    Process {
        id: niriProc
        command: ["niri", "msg", "action"]
        running: false
    }
```

- [ ] **Step 3: 提交**

---

### Task 3: IslandLayout 新增 overviewOverlay

**Files:**
- Modify: `modules/IslandLayout.qml`

- [ ] **Step 1: 在 recalc() 中添加 overviewExpanded 分支**

```qml
    function recalc() {
        if (workspaceModule.notifCenterExpanded) { ... }
        if (workspaceModule.overviewExpanded) {
            pillRadius = 16
            var ids = workspaceModule.getSortedWsList()
            var count = ids.length
            var colW = 100
            for (var i = 0; i < count; i++) {
                var wins = workspaceModule.windowsOfWs(ids[i])
                for (var w = 0; w < wins.length; w++) {
                    var ww = wins[w].title ? wins[w].title.length * 8 + 24 : 80
                    colW = Math.max(colW, ww)
                }
            }
            var total = count * Math.max(100, colW) + Math.max(0, count - 1) * 10 + 40
            targetWidth = Math.min(700, Math.max(400, total))
            targetHeight = 200
            return
        }
        if (musicModule.lyricsMode) { ... }
```

- [ ] **Step 2: 添加 overviewOverlay 组件**

在 `lyricsOverlay` 后面、`notifCenter` 前面添加：

```qml
    Item {
        id: overviewOverlay
        anchors.fill: parent
        anchors.margins: 4

        property real _opacity: workspaceModule.overviewExpanded ? 1 : 0
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01

        Row {
            id: overviewRow
            anchors.centerIn: parent
            spacing: 10
            Repeater {
                model: workspaceModule.getSortedWsList()
                Item {
                    id: wsColumn
                    width: Math.max(100, colLabel.implicitWidth + 24)
                    height: overviewOverlay.height - 24
                    anchors.verticalCenter: parent.verticalCenter

                    property string wsId: String(modelData)
                    property bool isActive: String(wsId) === String(workspaceModule.activeWsId)

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "#313244"
                        border.width: isActive ? 1 : 0
                        border.color: "#cba6f7"
                        opacity: workspaceModule.windowsOfWs(wsId).length > 0 ? 1 : 0.6
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        spacing: 6

                        Text {
                            id: colLabel
                            text: workspaceModule.iconForWs(wsId) + " " + (workspaceModule._workspaces[wsId] ? workspaceModule._workspaces[wsId].name || "WS" + wsId : "WS" + wsId)
                            color: "#cba6f7"
                            font.pixelSize: 12
                            font.family: "JetBrainsMonoNL Nerd Font"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Repeater {
                            model: workspaceModule.windowsOfWs(wsId)
                            Rectangle {
                                width: parent.width
                                height: 24
                                radius: 4
                                color: mouseArea.containsMouse ? "#45475a" : "transparent"

                                property var winData: modelData

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    text: winData.title || winData.app_id || "Window"
                                    color: "#a6adc8"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width - 8
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        workspaceModule.niriAction("focus-window --id " + winData.id)
                                        workspaceModule.overviewExpanded = false
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            workspaceModule.niriAction("focus-workspace --id " + wsId)
                            workspaceModule.overviewExpanded = false
                        }
                    }
                }
            }
        }
    }
```

- [ ] **Step 3: layoutContent._opacity 加入 overviewExpanded 条件**

```qml
        property real _opacity: (workspaceModule.notifCenterExpanded || musicModule.lyricsMode || workspaceModule.overviewExpanded) ? 0 : 1
```

- [ ] **Step 4: 添加互斥逻辑**

在 existing workspaceModule Connections 中添加 overviewExpanded changed handler：

```qml
    Connections {
        target: workspaceModule
        function onNotifCenterExpandedChanged() {
            layout.recalc()
            if (workspaceModule.notifCenterExpanded) {
                workspaceModule.overviewExpanded = false
            }
        }
        function onNotifActiveChanged() {
            layout.recalc()
            if (workspaceModule.notifActive && workspaceModule.overviewExpanded)
                workspaceModule.overviewExpanded = false
        }
    }
```

需要更新已有的 workspaceModule Connections 块。

- [ ] **Step 5: 提交**

---

### Task 4: 验证

- [ ] **Step 1: 运行测试**

```bash
qs -p ~/Projects/Waveland/shell.qml
```

- [ ] **Step 2: 验证功能**

确认：点击工作区图标打开面板 → 卡片正常显示 → 点击卡片切换工作区 → 点击窗口聚焦 → 面板关闭

- [ ] **Step 3: 提交**
