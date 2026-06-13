# Project Instructions

- 一个基于quickshell的一个简约灵动岛项目，所有东西都通过灵动岛来显示，开发期间，ai负责查询资料和分析程序，不需要修改任何程序。
- 项目运行环境是Arch Linux+ Niri

## Project Type: Unknown

<!-- Add build/test commands here -->

### Documentation
See README.md for project overview.

quickshell的指导文档：https://quickshell.org/docs/v0.3.0/guide/

Qt的指导文档：https://doc.qt.io/qt-6/qml-tutorial1.html

### Version Control
This project uses Git. See .gitignore for excluded files.

推送时用git push github main 和 git push gitee main，因为这个项目有两个remote
- **docs/ 目录不推送**：所有设计文档、计划文档仅保存在本地，使用 `git add -f` 强制添加后再 `git rm --cached` 移除跟踪。永远不要将 docs/ 推送到远程仓库。

## Agent Guidance

<!-- How should an AI agent approach this project? Fill in tool gotchas, -->
<!-- file patterns to avoid, and anything that helps a model navigate -->
<!-- the codebase without reading every file. -->

- **CodeWhale reads this file as:** <!-- WHALE.md (CodeWhale-native) or AGENTS.md (compatible with other agents) -->
- **Read-only surface:**  "~/Projects/Waveland/*",项目文件夹外的所有文档
- **Never edit:** "~/.config/*"
- **Always test with:** qs -p ~/Projects/Waveland/shell.qml
- **资料查询**： 遇到需要查询资料的情况，一定要到官方文档查询，如果遇到还没被允许的网站，要告诉我并且让我添加允许之后再继续进行查询
- **python环境**： 如果需要用到python，要先用'conda activate ocean'来激活环境
- 不要直接修改我的程序，只需要告诉我要怎么写，如果有必要生成程序我会主动告诉你的

## Architecture

<!-- Describe the high-level structure. What are the key modules and how -->
<!-- do they connect? Focus on the context a new contributor would need. -->

### Entry Points
<!-- Where does execution start? Binary entry, request handler, main loop? -->

- ~/Projects/Waveland/shell.qml

### Key Modules
<!-- List the 3-6 most important directories/files and their role -->

| 文件        | 职责                                 |
| ----------- | ------------------------------------ |
| 'shell.qml' | 项目入口                             |
| './test'    | 用于测试的程序                       |
| './scripts' | 指令程序(可能会用到自定义功能面板)   |
| './modules' | 模块文件，以后程序太长了用来拆分程序 |

### Data Flow
- 所有的信息都通过灵动岛显示，默认形态是只有一个clock显示时间，如果要显示更多的信息就让灵动岛变宽来显示更多信息
- 其他功能还未设计，设计之后再加进来

## Cache Stability

<!-- DeepSeek V4 uses a byte-stable prefix cache (128-token granularity). -->
<!-- Keeping these things stable turn-over-turn saves ~90% on input tokens. -->

- **Frequently-rebuilt files:** <!-- Generated code, lockfiles, build artifacts → mark as cache-churn -->
- **Stable scaffolding:** <!-- Config files, project instructions, model cards → keep byte-stable -->
- **Append, don't reorder:** <!-- New context goes at the end of the request; reordering invalidates cache -->

## Guidelines

- Follow existing code style and patterns
- Write tests for new functionality
- Keep changes focused and atomic
- Document public APIs
- Update this file when project conventions change
- **动画规范**: 所有组件的出现和消失都要加上渐隐渐现的动画（NumberAnimation on opacity, 200ms, Easing.InOutQuad）。使用独立的 `_opacity` property + Behavior 模式以确保动画可靠触发。
- **布局规范**: 所有组件必须位于药丸的水平中线上（verticalCenter 对齐）。Layout 中使用 `Layout.alignment: Qt.AlignVCenter`，非 Layout 中使用 `anchors.verticalCenter: parent.verticalCenter`。
