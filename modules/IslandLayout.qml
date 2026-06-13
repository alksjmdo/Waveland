import QtQuick
import QtQuick.Layouts
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
    property int hoverBonusW: 10
    property int hoverBonusH: 10
    property alias workspaceModule: workspaceModule
    property alias trayModule: trayModule
    property alias musicModule: musicModule
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
    property int effectiveHPadding: hPadding + (musicModule.isPlaying ? musicWaveWidth : 0)

    Behavior on effectiveHPadding {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    property real _musicOpacity: (musicModule.isPlaying || musicModule.lyricsMode) ? 1 : 0
    Behavior on _musicOpacity {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    property int targetWidth: minWidth
    property int targetHeight: 42

    Behavior on targetWidth {
        SpringAnimation {
            spring: 3.0
            damping: 0.7
            mass: 3.6
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
            targetWidth = 420
            targetHeight = 240
            pillRadius = 16
            return
        }
        if (musicModule.lyricsMode) {
            pillRadius = 0
            var lyricsContentW = lyricsNoteIcon.implicitWidth + 8 + lyricDisplayText.implicitWidth
            var totalW = leftWaves.implicitWidth + rightWaves.implicitWidth + lyricsContentW + 32
            var bonusW = hovered ? hoverBonusW : 0
            var bonusH = hovered ? hoverBonusH : 0
            targetWidth = Math.max(300, Math.min(600, totalW)) + bonusW
            targetHeight = 42 + bonusH
            return
        }
        pillRadius = 0
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
        if (musicModule.isPlaying) {
            lw += spacing + 20
            var artW = layout.hovered ? 100 : 28
            rw += spacing + artW
        }
        halfWidth = Math.max(lw, rw) + minClockGap
        clockWidth = clockModule.implicitWidth
        var bonusW = hovered ? hoverBonusW : 0
        var bonusH = hovered ? hoverBonusH : 0
        targetWidth = Math.max(minWidth, halfWidth * 2 + clockWidth + effectiveHPadding * 2) + bonusW
        targetHeight = clockModule.implicitHeight + bonusH
    }

    onHoveredChanged: recalc()

    Component.onCompleted: recalc()

    Connections {
        target: workspaceModule
        function onNotifCenterExpandedChanged() {
            layout.recalc()
            if (workspaceModule.notifCenterExpanded && musicModule.lyricsMode)
                musicModule.exitLyricsMode()
        }
        function onNotifActiveChanged() {
            layout.recalc()
            if (workspaceModule.notifActive && musicModule.lyricsMode)
                musicModule.exitLyricsMode()
        }
        function onNotifFadingChanged() {
            layout.recalc()
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

    Item {
        id: layoutContent
        anchors.left: parent.left
        anchors.leftMargin: layout.effectiveHPadding
        anchors.right: parent.right
        anchors.rightMargin: layout.effectiveHPadding
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        property real _opacity: (workspaceModule.notifCenterExpanded || musicModule.lyricsMode) ? 0 : 1
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
                            hovered: layout.hovered
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
                            height: 28
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
                            color: "#cba6f7"
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
                    Text {
                        text: "󰂞"
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 18
                        color: "#cba6f7"
                        opacity: workspaceModule.notifOpacity
                        visible: workspaceModule.notifOpacity > 0.01
                        anchors.right: trayModule.left
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
        opacity: layout._musicOpacity
        visible: layout._musicOpacity > 0.01
        Repeater {
            model: waveModel
            Rectangle {
                width: 2
                height: model.barHeight
                radius: 1
                color: "#cba6f7"
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
        opacity: layout._musicOpacity
        visible: layout._musicOpacity > 0.01
        layoutDirection: Qt.RightToLeft
        Repeater {
            model: waveModel
            Rectangle {
                width: 2
                height: model.barHeight
                radius: 1
                color: "#cba6f7"
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
        anchors.leftMargin: 10
        anchors.right: rightWaves.left
        anchors.rightMargin: 10
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
            color: "#cba6f7"
            anchors.left: parent.left
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
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: musicModule._displayText
            color: "#cdd6f4"
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"

            onImplicitWidthChanged: layout.recalc()
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

        Row {
            id: notifTopRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            spacing: 8

            Text {
                id: notifIconTop
                text: "󰂞"
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 22
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
                font.pixelSize: 20
                color: "#6c7086"
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        workspaceModule._notificationHistory = []
                        workspaceModule.clearNotification = true
                    }
                }
            }
        }

        ListView {
            anchors.top: notifTopRow.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            clip: true
            spacing: 6
            model: workspaceModule._notificationHistory

            delegate: Rectangle {
                width: ListView.view.width
                height: 36
                radius: 8
                color: "#313244"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 8

                    Text {
                        text: modelData.appName
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        width: 80
                        elide: Text.ElideRight
                    }
                    Text {
                        text: modelData.summary
                        color: "#a6adc8"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    text: modelData.time
                    color: "#585b70"
                    font.pixelSize: 11
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
        interval: 500
        running: true
        repeat: true
        onTriggered: layout.recalc()
    }
}
