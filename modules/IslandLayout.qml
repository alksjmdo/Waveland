import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
Item {
    id: layout
    anchors.centerIn: parent
    property var registry
    property var eventBus
    property int spacing: 8
    property int hPadding: 12
    property int minWidth: 280
    property int minClockGap: 16
    property bool hovered: false
    property int hoverBonusH: 10
    property alias workspaceModule: workspaceModule
    property alias trayModule: trayModule
    property alias musicModule: musicModule
    property alias batteryModule: batteryModule
    property alias volumeModule: volumeModule
    property alias brightnessModule: brightnessModule
    property alias networkModule: networkModule
    property int musicWaveWidth: 70

    PwNodePeakMonitor {
        id: peakMonitor
        node: Pipewire.defaultAudioSink
        enabled: musicModule.isPlaying
    }

    ListModel {
        id: waveModel
        Component.onCompleted: {
            for (var i = 0; i < 12; i++) append({ barHeight: 4 })
        }
    }

    function updatePeaks() {
        if (!peakMonitor || peakMonitor.peaks.length === 0) return
        var peak = Math.min(1.0, peakMonitor.peak * 2.0)
        for (var i = 0; i < 12; i++) {
            var factor = 0.3 + Math.random() * 0.7
            var target = Math.max(4, peak * 24 * factor)
            waveModel.setProperty(i, "barHeight", target)
        }
    }

    Timer {
        id: peakTimer
        interval: 100
        running: musicModule.isPlaying && layout._musicOpacity > 0.5
        repeat: true
        onTriggered: updatePeaks()
    }

    property int pillRadius: 0

    property int leftContentWidth: 0
    property int rightContentWidth: 0
    property int halfWidth: 0
    property int clockWidth: 64
    property int effectiveHPadding: hPadding + ((musicModule._showControls && musicModule.isPlaying) ? musicWaveWidth : 0)

    Behavior on effectiveHPadding {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    property real _musicOpacity: (musicModule._showControls || musicModule.lyricsMode) && !workspaceModule.notifCenterExpanded && !networkModule.networkExpanded ? 1 : 0
    Behavior on _musicOpacity {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    property int targetWidth: minWidth
    property int targetHeight: 42

    property bool _shrinking: false
    Behavior on targetWidth {
        NumberAnimation {
            duration: layout._shrinking ? 200 : 400
            easing.type: layout._shrinking ? Easing.InQuad : Easing.OutQuad
        }
    }
    Behavior on targetHeight {
        SpringAnimation {
            spring: 3.0
            damping: 0.7
            mass: 3.6
        }
    }

    implicitWidth: targetWidth
    implicitHeight: targetHeight

    function recalc() {
        if (workspaceModule.notifCenterExpanded) {
            targetWidth = 840
            targetHeight = 480
            pillRadius = 16
            return
        }
        if (networkModule.networkExpanded) {
            targetWidth = 420
            targetHeight = 280
            pillRadius = 16
            return
        }
        if (workspaceModule.overviewExpanded) {
            pillRadius = 0
            var contentW = wsReturnBtn.implicitWidth + 8 + wsPillRow.implicitWidth
            var totalW = leftWaves.implicitWidth + rightWaves.implicitWidth + contentW + 60
            targetWidth = Math.max(300, Math.min(700, totalW))
            targetHeight = 42
            return
        }
        if (musicModule.lyricsMode) {
            pillRadius = 0
            var lyricsContentW = lyricsNoteIcon.implicitWidth + 8 + lyricDisplayText.implicitWidth + 8 + controlsContent.implicitWidth
            var totalW = leftWaves.implicitWidth + rightWaves.implicitWidth + lyricsContentW + 52
            targetWidth = Math.max(300, totalW)
            targetHeight = 42 + (hovered ? hoverBonusH : 0)
            return
        }
        var lw = 0
        var rw = 0
        if (registry) {
            var llist = registry.leftActive
            for (var i = 0; i < llist.length; i++) {
                var mod = registry.modules[llist[i]]
                var cw = mod.component ? (mod.component.width || mod.idleWidth) : mod.idleWidth
                lw += cw
                if (i < llist.length - 1) lw += spacing
            }
            var rlist = registry.rightActive
            for (var j = 0; j < rlist.length; j++) {
                var rmod = registry.modules[rlist[j]]
                var rcw = rmod.component ? (rmod.component.width || rmod.idleWidth) : rmod.idleWidth
                rw += rcw
                if (j < rlist.length - 1) rw += spacing
            }
        }
        leftContentWidth = lw
        rightContentWidth = rw
        lw += spacing + batteryModule.implicitWidth + spacing + volumeModule.implicitWidth + spacing + brightnessModule.implicitWidth
        rw += spacing + networkModule.implicitWidth + spacing + notifBell.implicitWidth
        if (musicModule._showControls) {
            lw += spacing + 20
            var artW = layout.hovered ? 100 : 28
            rw += spacing + artW
        }
        halfWidth = Math.max(lw, rw) + minClockGap
        clockWidth = clockModule.implicitWidth
        targetWidth = Math.max(minWidth, halfWidth * 2 + clockWidth + effectiveHPadding * 2)
        _shrinking = targetWidth < layout.implicitWidth
        targetHeight = clockModule.implicitHeight + (hovered ? hoverBonusH : 0)
    }

    onHoveredChanged: {
        recalc()
        if (!hovered && workspaceModule.overviewExpanded)
            workspaceModule.overviewExpanded = false
    }

    Component.onCompleted: recalc()

    Connections {
        target: workspaceModule
        function onNotifCenterExpandedChanged() {
            layout.recalc()
            if (!workspaceModule.notifCenterExpanded) {
                notifCenter.expandedIndex = -1
                radiusRestoreTimer.restart()
                if (layout.hovered) {
                    volumeModule.show()
                    brightnessModule.show()
                }
            }
        }
        function onNotifActiveChanged() {
            layout.recalc()
            if (workspaceModule.notifActive && musicModule.lyricsMode)
                musicModule.exitLyricsMode()
            if (workspaceModule.notifActive && workspaceModule.overviewExpanded)
                workspaceModule.overviewExpanded = false
        }
        function onNotifFadingChanged() {
            layout.recalc()
        }
        function onOverviewExpandedChanged() {
            layout.recalc()
            if (workspaceModule.overviewExpanded) {
                if (workspaceModule.notifCenterExpanded)
                    workspaceModule.notifCenterExpanded = false
                if (musicModule.lyricsMode)
                    musicModule.exitLyricsMode()
                workspaceModule.resolveAllIcons()
            } else if (layout.hovered) {
                volumeModule.show()
                brightnessModule.show()
            }
        }
    }

    Connections {
        target: musicModule
        function onIsPlayingChanged() {
            layout.recalc()
        }
        function onLyricsModeChanged() {
            layout.recalc()
        }
    }

    Connections {
        target: batteryModule
        function onWidthChanged() { layout.recalc() }
    }

    Connections {
        target: volumeModule
        function onWidthChanged() { layout.recalc() }
    }

    Connections {
        target: brightnessModule
        function onWidthChanged() { layout.recalc() }
    }

    Timer {
        id: networkRefresh
        interval: 100
        onTriggered: wifiScan.exec(["sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null | grep -v '^$'"])
    }

    Process {
        id: wifiScan
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var seen = {}
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length < 4 || !parts[1]) continue
                    var ssid = parts[1]
                    var sig = parseInt(parts[2]) || 0
                    var inUse = parts[0] === "*"
                    if (seen[ssid] === undefined) {
                        seen[ssid] = { signal: sig, inUse: inUse, security: parts[3] || "", secured: parts[3] !== "" && parts[3] !== "--" }
                    } else {
                        if (sig > seen[ssid].signal) seen[ssid].signal = sig
                        if (inUse) seen[ssid].inUse = true
                        if (seen[ssid].security === "" && parts[3] !== "" && parts[3] !== "--") {
                            seen[ssid].security = parts[3]
                            seen[ssid].secured = true
                        }
                    }
                }
                var items = []
                for (var key in seen) {
                    items.push({
                        inUse: seen[key].inUse,
                        ssid: key,
                        signal: seen[key].signal,
                        security: seen[key].security,
                        secured: seen[key].secured
                    })
                }
                items.sort(function(a, b) { return b.signal - a.signal })
                wifiModel.clear()
                for (var j = 0; j < items.length; j++)
                    wifiModel.append(items[j])
            }
        }
    }

    ListModel { id: wifiModel }

    Timer {
        id: wifiRescan
        interval: 100
        onTriggered: wifiScan.exec(["sh", "-c",
            "nmcli dev wifi rescan 2>/dev/null; sleep 2; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null | grep -v '^$'"])
    }

    Process {
        id: wifiConnect
        running: false
    }

    Connections {
        target: networkModule
        function onNetworkExpandedChanged() {
            layout.recalc()
            if (!networkModule.networkExpanded) {
                radiusRestoreTimer.restart()
                if (layout.hovered) {
                    volumeModule.show()
                    brightnessModule.show()
                }
            }
            if (networkModule.networkExpanded) {
                if (workspaceModule.notifCenterExpanded)
                    workspaceModule.notifCenterExpanded = false
                if (workspaceModule.overviewExpanded)
                    workspaceModule.overviewExpanded = false
                if (musicModule.lyricsMode)
                    musicModule.exitLyricsMode()
                networkRefresh.restart()
            }
        }
    }

    Connections {
        target: networkModule
        function onWidthChanged() { layout.recalc() }
    }

    Item {
        id: layoutContent
        anchors.left: parent.left
        anchors.leftMargin: layout.effectiveHPadding
        anchors.right: parent.right
        anchors.rightMargin: layout.effectiveHPadding
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        property real _opacity: (workspaceModule.notifCenterExpanded || musicModule.lyricsMode || workspaceModule.overviewExpanded || networkModule.networkExpanded) ? 0 : 1
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01

        RowLayout {
            anchors.fill: parent
            spacing: 0
            Item {
                id: leftPanel
                Layout.preferredWidth: (layoutContent.width - clockPanel.Layout.preferredWidth) / 2
                Layout.fillHeight: true
                Item {
                    id: leftContent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: layout.leftContentWidth
                    height: parent.height
                    RowLayout {
                        anchors.fill: parent
                        spacing: layout.spacing
                        WorkspaceModule {
                            id: workspaceModule
                            Layout.alignment: Qt.AlignVCenter
                        }
                        BatteryModule {
                            id: batteryModule
                            pillHovered: layout.hovered
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignVCenter
                        }
                        VolumeModule {
                            id: volumeModule
                            pillHovered: layout.hovered
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignVCenter
                        }
                        BrightnessModule {
                            id: brightnessModule
                            pillHovered: layout.hovered
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignVCenter
                        }
                        MusicModule {
                            id: musicModule
                        }
                    }
                }
                Text {
                    text: "󰽰"
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 20
                    color: "#cba6f7"
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: layout._musicOpacity
                    visible: layout._musicOpacity > 0.01

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: musicModule.toggleLyricsMode()
                    }
                }
            }
            Item {
                id: clockPanel
                Layout.preferredWidth: clockModule.implicitWidth
                Layout.fillHeight: true

                ClockModule {
                    id: clockModule
                    anchors.centerIn: parent
                }
            }
            Item {
                id: rightPanel
                Layout.preferredWidth: (layoutContent.width - clockPanel.Layout.preferredWidth) / 2
                Layout.fillHeight: true
                Item {
                    id: albumArtContainer
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: layout.hovered ? artRow.implicitWidth + 12 : 28
                    height: 28
                    opacity: layout._musicOpacity
                    visible: layout._musicOpacity > 0.01

                    property bool artPlaying: musicModule.isPlaying

                    Behavior on width {
                        SpringAnimation { spring: 2.5; damping: 0.6; mass: 1.5 }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: "#313244"
                        opacity: layout.hovered && layout._musicOpacity > 0.01 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    }

                    Row {
                        id: artRow
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Rectangle {
                            id: artFrame
                            width: 28
        height: 30
                            radius: 12
                            clip: true
                            color: "#313244"
                            anchors.verticalCenter: parent.verticalCenter

                            IconImage {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: musicModule.trackArtUrl !== "" ? musicModule.trackArtUrl : ""
                                asynchronous: true
                            }
                        }

                        Text {
                            text: "\uF048"
                            font.family: "JetBrainsMonoNL Nerd Font"
                            font.pixelSize: 18
                            color: "#cdd6f4"
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: layout.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (musicModule.activePlayer && musicModule.activePlayer.canGoPrevious)
                                        musicModule.activePlayer.previous()
                                }
                            }
                        }

                        Text {
                            text: albumArtContainer.artPlaying ? "\uF04D" : "\uF04B"
                            font.family: "JetBrainsMonoNL Nerd Font"
                            font.pixelSize: 18
                color: musicModule._coverPrimary
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: layout.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (musicModule.activePlayer && musicModule.activePlayer.canTogglePlaying)
                                        musicModule.activePlayer.togglePlaying()
                                }
                            }
                        }

                        Text {
                            text: "\uF051"
                            font.family: "JetBrainsMonoNL Nerd Font"
                            font.pixelSize: 18
                            color: "#cdd6f4"
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: layout.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (musicModule.activePlayer && musicModule.activePlayer.canGoNext)
                                        musicModule.activePlayer.next()
                                }
                            }
                        }
                    }
                }
                Item {
                    id: rightContent
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: layout.rightContentWidth
                    height: parent.height
                    SystemTrayModule {
                        id: trayModule
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    NetworkModule {
                        id: networkModule
                        pillHovered: layout.hovered
                        anchors.right: trayModule.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: notifBell
                        text: "󰂞"
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 18
                    color: "#cba6f7"
                        opacity: workspaceModule.notifOpacity
                        visible: workspaceModule.notifOpacity > 0.01
                        anchors.right: networkModule.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: workspaceModule.notifCenterExpanded = !workspaceModule.notifCenterExpanded
                        }
                    }
                }
            }
        }
    }

    Row {
        id: leftWaves
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        opacity: layout._musicOpacity * (musicModule.isPlaying ? 1 : 0)
        visible: layout._musicOpacity > 0.01 && musicModule.isPlaying
        Repeater {
            model: waveModel
            Rectangle {
                width: 2
                height: model.barHeight
                radius: 1
                color: musicModule.lyricsMode ? musicModule._coverPrimary : "#cba6f7"
                Behavior on color {
                    ColorAnimation { duration: 500 }
                }
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                }
            }
        }
    }

    Row {
        id: rightWaves
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        opacity: layout._musicOpacity * (musicModule.isPlaying ? 1 : 0)
        visible: layout._musicOpacity > 0.01 && musicModule.isPlaying
        layoutDirection: Qt.RightToLeft
        Repeater {
            model: waveModel
            Rectangle {
                width: 2
                height: model.barHeight
                radius: 1
                color: musicModule.lyricsMode ? musicModule._coverPrimary : "#cba6f7"
                Behavior on color {
                    ColorAnimation { duration: 500 }
                }
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                }
            }
        }
    }

    Item {
        id: lyricsOverlay
        anchors.left: leftWaves.right
        anchors.leftMargin: 20
        anchors.right: rightWaves.left
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        height: 28

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
            color: musicModule._coverSecondary
            Behavior on color {
                ColorAnimation { duration: 500 }
            }
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: musicModule.toggleLyricsMode()
            }
        }

        Item {
            id: lyricsControlsWrapper
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: controlsContent.implicitWidth
            height: 30

            Row {
                id: controlsContent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Item {
                    width: layout.hovered ? prevBtn.implicitWidth : 0
                    height: 30
                    clip: true
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    Text {
                        id: prevBtn
                        text: "\uF048"
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 16
                        color: musicModule._coverSecondary
                        Behavior on color {
                            ColorAnimation { duration: 500 }
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: layout.hovered ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (musicModule.activePlayer && musicModule.activePlayer.canGoPrevious)
                                    musicModule.activePlayer.previous()
                            }
                        }
                    }
                }

                Item {
                    width: layout.hovered ? playBtn.implicitWidth : 0
                    height: 30
                    clip: true
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    Text {
                        id: playBtn
                        text: musicModule.isPlaying ? "\uF04D" : "\uF04B"
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 16
                        color: musicModule._coverPrimary
                        Behavior on color {
                            ColorAnimation { duration: 500 }
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: layout.hovered ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (musicModule.activePlayer && musicModule.activePlayer.canTogglePlaying)
                                    musicModule.activePlayer.togglePlaying()
                            }
                        }
                    }
                }

                Item {
                    width: layout.hovered ? nextBtn.implicitWidth : 0
                    height: 30
                    clip: true
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    Text {
                        id: nextBtn
                        text: "\uF051"
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 16
                        color: musicModule._coverSecondary
                        Behavior on color {
                            ColorAnimation { duration: 500 }
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: layout.hovered ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (musicModule.activePlayer && musicModule.activePlayer.canGoNext)
                                    musicModule.activePlayer.next()
                            }
                        }
                    }
                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 12
                    clip: true
                    color: "#313244"
                    anchors.verticalCenter: parent.verticalCenter

                    IconImage {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: musicModule.trackArtUrl !== "" ? musicModule.trackArtUrl : ""
                        asynchronous: true
                    }
                }
            }
        }

        Text {
            id: lyricDisplayText
            anchors.left: lyricsNoteIcon.right
            anchors.leftMargin: 8
            anchors.right: lyricsControlsWrapper.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: musicModule._displayText
            color: musicModule._coverPrimary
            Behavior on color {
                ColorAnimation { duration: 500 }
            }
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"

            onImplicitWidthChanged: layout.recalc()
        }
    }

    Item {
        id: wsOverlay
        anchors.left: leftWaves.right
        anchors.leftMargin: 20
        anchors.right: rightWaves.left
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        height: 28

        property real _opacity: workspaceModule.overviewExpanded ? 1 : 0
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01

        Text {
            id: wsReturnBtn
            text: "\uF311"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 20
            color: "#f38ba8"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: workspaceModule.overviewExpanded = false
            }
        }

        Row {
            id: wsPillRow
            anchors.left: wsReturnBtn.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: {
                    var all = workspaceModule.getSortedWsList()
                    var filtered = []
                    for (var i = 0; i < all.length; i++) {
                        if (workspaceModule.windowsOfWs(all[i]).length > 0)
                            filtered.push(all[i])
                    }
                    return filtered
                }

                Rectangle {
                    id: wsPill
                    width: pillRow.implicitWidth + 24
                    height: 30
                    radius: 14
                    color: "#313244"
                    border.width: isActiveWs ? 1 : 0
                    border.color: "#cba6f7"

                    property string wsId: String(modelData)
                    property bool isActiveWs: String(wsId) === String(workspaceModule.activeWsId)

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var ws = workspaceModule._workspaces[wsPill.wsId]
                            var idx = ws ? ws.idx : 0
                            workspaceModule.niriAction("focus-workspace " + idx)
                        }
                    }

                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: workspaceModule.iconForWs(wsPill.wsId)
                            font.family: "JetBrainsMonoNL Nerd Font"
                            font.pixelSize: 20
                            color: "#cba6f7"
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                }

                        Repeater {
                            model: workspaceModule.windowsOfWs(wsPill.wsId)
                            IconImage {
                                width: 20
                                height: 20
                                asynchronous: true
                                source: workspaceModule._iconPaths[modelData.app_id] || ""
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        workspaceModule.niriAction("focus-window --id " + modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: notifCenter
        anchors.fill: parent

        property real _opacity: workspaceModule.notifCenterExpanded ? 1 : 0
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01

        scale: workspaceModule.notifCenterExpanded ? 1 : 0.8
        Behavior on scale {
            SpringAnimation { spring: 2.0; damping: 0.5; mass: 1.0 }
        }

        property int expandedIndex: -1
        property bool clearing: false

        onClearingChanged: {
            if (clearing) clearTimer.restart()
        }

        Timer {
            id: clearTimer
            interval: 200
            onTriggered: {
                workspaceModule._notificationHistory = []
                workspaceModule.clearNotification = true
                notifCenter.clearing = false
            }
        }

        Row {
            id: notifTopRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 24
            spacing: 12

            Text {
                id: notifIconTop
                text: "󰂞"
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 33
                color: "#cba6f7"
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: workspaceModule.notifCenterExpanded = false
                }
            }

            ClockModule {
                id: notifClock
                scale: workspaceModule.notifCenterExpanded ? 0.7 : 1

                Behavior on scale {
                    SpringAnimation { spring: 2.0; damping: 0.5; mass: 1.0 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: workspaceModule.notifCenterExpanded = false
                }
            }

            Text {
                text: "󰂛"
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 30
                color: "#6c7086"
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { notifCenter.clearing = true }
                }
            }
        }

        ListView {
            id: notifList
            anchors.top: notifTopRow.bottom
            anchors.topMargin: 18
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            clip: true
            spacing: 10
            opacity: notifCenter.clearing ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            model: workspaceModule._notificationHistory

            delegate: Rectangle {
                id: notifDelegate
                property int myIndex: index
                property bool expanded: notifCenter.expandedIndex === myIndex
                width: ListView.view.width
                height: expanded ? notifSummary.implicitHeight + 6 + bodyText.implicitHeight + 24 : (modelData.body && modelData.body !== "" ? 78 : 54)
                radius: 8
                color: "#313244"

                Behavior on height {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                Text {
                    id: notifAppName
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    text: modelData.appName
                    color: "#cdd6f4"
                    font.pixelSize: 18
                    width: Math.min(implicitWidth + 12, 135)
                    elide: Text.ElideRight
                }
                Text {
                    id: notifTime
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    text: modelData.time
                    color: "#585b70"
                    font.pixelSize: 17
                }
                Text {
                    id: notifSummary
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.left: notifAppName.right
                    anchors.leftMargin: 10
                    anchors.right: notifTime.left
                    anchors.rightMargin: 10
                    text: modelData.summary
                    color: "#a6adc8"
                    font.pixelSize: 18
                    elide: notifDelegate.expanded ? Text.ElideNone : Text.ElideRight
                    wrapMode: notifDelegate.expanded ? Text.WordWrap : Text.NoWrap
                    maximumLineCount: notifDelegate.expanded ? 0 : 1
                }
                Text {
                    id: bodyText
                    anchors.top: notifSummary.bottom
                    anchors.topMargin: 6
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    text: modelData.body || ""
                    color: notifDelegate.expanded ? "#cdd6f4" : "#6c7086"
                    font.pixelSize: notifDelegate.expanded ? 22 : 16
                    elide: notifDelegate.expanded ? Text.ElideNone : Text.ElideRight
                    wrapMode: notifDelegate.expanded ? Text.WordWrap : Text.NoWrap
                    maximumLineCount: notifDelegate.expanded ? 0 : 1
                    visible: modelData.body && modelData.body !== ""
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (notifCenter.expandedIndex === myIndex)
                            notifCenter.expandedIndex = -1
                        else
                            notifCenter.expandedIndex = myIndex
                    }
                }
            }
        }
    }

    Item {
        id: networkOverlay
        anchors.fill: parent

        property real _opacity: networkModule.networkExpanded ? 1 : 0
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01

        property string _selectedSsid: ""
        property bool _needPassword: false
        property bool _showPassword: false

        Row {
            id: networkTopRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            spacing: 8

            Text {
                text: "󰛍"
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 22
                color: "#89b4fa"
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: networkModule.networkExpanded = false
                }
            }

            ClockModule {
                id: networkClock
                scale: networkModule.networkExpanded ? 0.7 : 1
                Behavior on scale {
                    SpringAnimation { spring: 2.0; damping: 0.5; mass: 1.0 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: networkModule.networkExpanded = false
                }
            }

            Text {
                text: "󰑐"
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 20
                color: "#6c7086"
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiRescan.restart()
                }
            }
        }

        Item {
            id: wifiListView
            anchors.top: networkTopRow.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            clip: true

            ListView {
                anchors.fill: parent
                spacing: 4
                model: wifiModel

                delegate: Rectangle {
                    id: wifiDelegate
                    width: ListView.view.width
                    height: 40
                    radius: 8
                    color: "transparent"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        spacing: 10

                        Text {
                            text: model.secured ? (model.signal <= 25 ? "󰤡" : model.signal <= 50 ? "󰤤" : model.signal <= 75 ? "󰤧" : "󰤪") : (model.signal <= 25 ? "󰤟" : model.signal <= 50 ? "󰤢" : model.signal <= 75 ? "󰤥" : "󰤨")
                            font.family: "JetBrainsMonoNL Nerd Font"
                            font.pixelSize: 20
                            color: model.inUse ? "#7dc4e4" : "#6c7086"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: model.ssid
                            color: model.inUse ? "#7dc4e4" : "#cdd6f4"
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: model.inUse ? 52 : 40
                        height: 24
                        radius: 12
                        color: model.inUse ? "#313244" : "#89b4fa"

                        Text {
                            text: model.inUse ? "已连接" : "连接"
                            font.pixelSize: 11
                            color: model.inUse ? "#6c7086" : "#1e1e2e"
                            anchors.centerIn: parent
                        }

                    MouseArea {
                        id: wifiMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.secured) {
                                networkOverlay._selectedSsid = model.ssid
                                wifiPasswordDialog.restart()
                            } else {
                                wifiConnect.exec(["nmcli", "dev", "wifi", "connect", model.ssid])
                            }
                        }
                    }
        }
    }

    Timer {
        id: wifiPasswordDialog
        interval: 50
        onTriggered: wifiPasswordProc.exec(["sh", "-c",
            "zenity --password --title='连接 " + networkOverlay._selectedSsid + "' 2>/dev/null"])
    }

    Process {
        id: wifiPasswordProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var pwd = text.trim()
                if (pwd) {
                    wifiConnect.exec(["nmcli", "dev", "wifi", "connect",
                        networkOverlay._selectedSsid,
                        "password", pwd])
                }
            }
        }
    }

    Connections {
        target: registry
        function onLayoutChanged() {
            layout.recalc()
        }
    }

    Timer {
        id: recalcTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: layout.recalc()
    }

    Item {
        width: 1
        height: 1
        opacity: 0
    }

    Timer {
        id: radiusRestoreTimer
        interval: 400
        onTriggered: {
            if (!workspaceModule.notifCenterExpanded && !workspaceModule.overviewExpanded && !musicModule.lyricsMode && !networkModule.networkExpanded)
                pillRadius = 0
        }
    }
}
}
}
}
}
