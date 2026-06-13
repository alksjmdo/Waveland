# Waveland 工作区概览面板设计文档

**日期**: 2026-06-13
**状态**: 已确认
**前序设计**: 2026-06-12-waveland-design.md, 2026-06-13-lyrics-mode-design.md

---

## 1. 功能概述

点击灵动岛中工作区图标（`󰮯`）展开工作区概览面板。多列卡片展示所有工作区及其窗口，支持点击切换工作区、点击聚焦窗口、拖拽移动窗口到其他工作区。

| 状态 | 显示内容 | 岛形态 |
|------|----------|--------|
| 收缩态 | 工作区图标 + 时钟 + 托盘 + 通知铃 | 药丸，280-400px × 42px |
| 工作区面板 | 所有工作区卡片（多列） | 卡片，400-700px × 200px，圆角 16px |

---

## 2. 面板布局

```
┌─────────────────────────────────────────────────────────┐
│  󰈹 Web            │  󰨞 Code [活跃]   │   Empty      │
│  ─────────        │  ─────────       │  ─────────      │
│  ▸ Chromium       │  ▸ VSCode        │  (无窗口)       │
│  ▸ Firefox        │  ▸ Terminal      │                 │
│                   │                  │                 │
└─────────────────────────────────────────────────────────┘
```

**规则：**
- 水平排列，每列一个工作区卡片
- 活跃工作区卡片：边框 `#cba6f7` 1px，窗口文字 `#cdd6f4`
- 非活跃工作区卡片：无边框，窗口文字 `#a6adc8`
- 空工作区卡片：降低 opacity (0.6)，文字 `#585b70`
- 卡片内窗口列表垂直排列，超出高度内部可滚动
- 面板圆角 16px，与通知中心统一

**宽度计算：**
```
列宽 = max(100, 最宽窗口名 implicitWidth + 内边距24)
面板宽 = 列数 × 列宽 + 间距10 × (列数-1) + 左右内边距40
最小 400px，最大 700px
```

---

## 3. 交互

| 操作 | 效果 | 实现 |
|------|------|------|
| 点击工作区图标 `󰮯` | 展开/关闭面板 | `workspaceModule.overviewExpanded = !...` |
| 点击工作区卡片 | 关闭面板，切换到该工作区 | `niri msg action focus-workspace --id <id>` |
| 点击窗口条目 | 切换到该工作区并聚焦窗口 | `niri msg action focus-window --id <id>` |
| 拖拽窗口到另一列 | 移动窗口到目标工作区 | `niri msg action move-window-to-workspace --id <win> <ws>` |
| 点击 `󰮯` / Esc 键 | 关闭面板 | `workspaceModule.overviewExpanded = false` |
| 新通知到达 | 自动关闭面板 | 和歌词模式同样的自动退出机制 |

### 3.1 拖拽实现

```qml
// 窗口条目
Rectangle {
    property string windowId: ...
    Drag.active: dragArea.drag.active
    Drag.hotSpot: { x: width/2, y: height/2 }
    
    MouseArea {
        id: dragArea
        drag.target: parent
        onClicked: /* 聚焦窗口 */
    }
}

// 工作区卡片
DropArea {
    onDropped: function(drop) {
        // drop.source.windowId → 目标工作区 ID
        // 执行 niri move-window-to-workspace
    }
}
```

### 3.2 互斥逻辑

```
overviewExpanded && notifCenterExpanded → 关闭通知中心
overviewExpanded && lyricsMode → 关闭歌词模式
notifCenterExpanded && overviewExpanded → 关闭面板
```

---

## 4. 数据流

现有 Niri event-stream 已提供全部数据，无需额外 IPC：

```
Niri event-stream
  ├── WorkspacesChanged → _workspaces: { id → {name, idx, isActive} }
  ├── WindowsChanged → _windows: { id → {title, app_id, workspace_id} }
  ├── WorkspaceActivated → activeWsId 更新
  ├── WindowOpenedOrChanged → 更新/新增窗口
  └── WindowClosed → 删除窗口
```

面板直接读取 `_workspaces` 和 `_windows`，按工作区 `idx` 排序展示。

---

## 5. 组件改动

### 5.1 WorkspaceModule.qml 新增

| 属性 | 类型 | 说明 |
|------|------|------|
| `overviewExpanded` | `bool` | 面板是否展开（初始 false） |
| `overviewOpacity` | `real` | 面板 opacity（绑定动画） |
| `getSortedWsList()` | `function` | 返回按 idx 排序的工作区 ID 列表 |
| `windowsOfWs(wsId)` | `function` | 返回某工作区下的窗口列表 |

**niri 命令执行：**
```qml
Process {
    id: niriProcess
    command: ["niri", "msg", "action"]
    // 通过 IpcHandler 或临时 Process 执行命令
}
```

### 5.2 IslandLayout.qml 新增

```qml
Item {
    id: overviewOverlay
    anchors.fill: parent
    visible: workspaceModule.overviewExpanded
    // ... 多列卡片布局
}
```

### 5.3 recalc() 新增分支

```qml
if (workspaceModule.overviewExpanded) {
    pillRadius = 16
    targetWidth = 计算面板宽度(400~700)
    targetHeight = 200
    return
}
```

---

## 6. 动画

| 过渡 | 属性 | 类型 | 时长 |
|------|------|------|------|
| 面板出现 | overviewOverlay._opacity 0→1 | NumberAnimation | 200ms, Easing.InOutQuad |
| 面板消失 | overviewOverlay._opacity 1→0 | NumberAnimation | 200ms, Easing.InOutQuad |
| 布局组件隐藏 | layoutContent._opacity 1→0 | NumberAnimation | 200ms |
| 岛体宽高变化 | targetWidth/Height | SpringAnimation | spring:3.0, damping:0.7 |
| 卡片 hover | 边框颜色变化 | ColorAnimation | 150ms |

---

## 7. 边缘情况

| 场景 | 处理 |
|------|------|
| 只有一个工作区 | 面板最小宽度 400px，单列居中 |
| 所有工作区为空 | 每个卡片显示 "无窗口" |
| 拖拽窗口到同一工作区 | 忽略操作 |
| 拖拽时面板关闭 | 取消拖拽状态，不执行命令 |
| niri 命令执行失败 | 静默忽略，不显示提示 |
| 工作区被外部删除 | 卡片立即消失，面板宽度重新计算 |

---

## 8. 行为变更：hover 不再展开工作区

有此功能后，鼠标悬停灵动岛时工作区组件**不再**水平展开显示其他工作区图标。工作区区域始终只显示活跃工作区图标 `󰮯`，点击即可打开面板查看全部。

**WorkspaceModule 变更：**
- `refreshDisplay()` 始终使用 collapsed 逻辑：`_displayList = [activeWsId]`
- 删除 `hovered` 属性和 `collapseTimer`
- 工作区图标始终显示 `󰮯`（活跃工作区图标），带单击 MouseArea

---

## 9. 文件改动清单

| 文件 | 改动 |
|------|------|
| `modules/WorkspaceModule.qml` | 新增 ~40 行：overviewExpanded、getSortedWsList、windowsOfWs、niri 命令 Process；删除 hover 展开逻辑、collapseTimer |
| `modules/IslandLayout.qml` | 新增 ~80 行：overviewOverlay 组件（卡片 Repeater）、recalc() 面板分支、互斥逻辑 |

---

## 10. 实施顺序

1. WorkspaceModule 移除 hover 展开逻辑（collapseTimer、_displayList hover 分支），新增 `overviewExpanded` 属性
2. WorkspaceModule 新增 `getSortedWsList()` / `windowsOfWs()` 辅助函数
3. IslandLayout 新增 `overviewOverlay` 卡片布局
4. IslandLayout recalc() 面板宽度计算
5. 拖拽逻辑实现
6. 互斥逻辑（通知中心、歌词模式）
7. 动画完善 + 边缘情况
8. 测试
