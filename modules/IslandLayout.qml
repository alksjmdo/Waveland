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
    property alias notifServer: notifServer
    property int musicWaveWidth: 70

    property int pillRadius: 0

    property int leftContentWidth: 0
    property int rightContentWidth: 0
    property int halfWidth: 0
    property int clockWidth: 64
    property int effectiveHPadding: hPadding + ((musicModule._showControls && musicModule.isPlaying) ? musicWaveWidth : 0)

    Behavior on effectiveHPadding {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    property real _musicOpacity: (musicModule._showControls || musicModule.lyricsMode) && !notifServer.notifCenterExpanded && !networkModule.networkExpanded && !musicModule.lyricsExpanded ? 1 : 0
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

    AudioPeaks {
        id: audioPeaks
        anchors.fill: parent
        musicPlaying: musicModule.isPlaying
        lyricsMode: musicModule.lyricsMode
        peakColor: musicModule._coverPrimary
        musicOpacity: layout._musicOpacity
    }

    NotifServerModule {
        id: notifServer
    }

    function recalc() {
        if (notifServer.notifCenterExpanded) {
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
            var wsContentW = wsOverlay.implicitWidth
            var wsTotalW = audioPeaks.overlayLeftInset + wsContentW + audioPeaks.overlayRightInset
            targetWidth = Math.max(300, Math.min(700, wsTotalW + (hovered ? 20 : 0)))
            targetHeight = 42 + (hovered ? hoverBonusH : 0)
            return
        }
        if (musicModule.lyricsExpanded) {
            targetWidth = 720
            targetHeight = 340
            pillRadius = 20
            return
        }
        if (musicModule.lyricsMode) {
            var lyricsContentW = lyricsOverlay.implicitWidth
            var lyricsTotalW = audioPeaks.overlayLeftInset + lyricsContentW + audioPeaks.overlayRightInset
            targetWidth = Math.max(300, lyricsTotalW)
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
        rw += spacing + notifBell.implicitWidth
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
    }

    Component.onCompleted: {
        recalc()
        if (eventBus) {
            eventBus.subscribe("requestRecalc", function() { recalc() })
            eventBus.subscribe("modeChanged", function(data) { handleModeChange(data) })
        }
    }

    function handleModeChange(data) {
        if (!data) return
        if (data.mode === "notifCenterExpanded" && data.value) {
            if (musicModule.lyricsMode) musicModule.exitLyricsMode()
            if (musicModule.lyricsExpanded) musicModule.lyricsExpanded = false
        }
        if (data.mode === "overviewExpanded" && data.value) {
            if (notifServer.notifCenterExpanded) notifServer.notifCenterExpanded = false
            if (musicModule.lyricsMode) musicModule.exitLyricsMode()
            if (musicModule.lyricsExpanded) musicModule.lyricsExpanded = false
            workspaceModule.resolveAllIcons()
        } else if (data.mode === "overviewExpanded" && !data.value && layout.hovered) {
            volumeModule.show()
            brightnessModule.show()
        }
        if (data.mode === "lyricsExpanded" && data.value) {
            if (notifServer.notifCenterExpanded) notifServer.notifCenterExpanded = false
            if (workspaceModule.overviewExpanded) workspaceModule.overviewExpanded = false
            if (networkModule.networkExpanded) networkModule.networkExpanded = false
        } else if (data.mode === "lyricsExpanded" && !data.value) {
            radiusRestoreTimer.restart()
        }
        if (data.mode === "networkExpanded" && !data.value) {
            radiusRestoreTimer.restart()
            if (layout.hovered) {
                volumeModule.show()
                brightnessModule.show()
            }
        }
        if (data.mode === "networkExpanded" && data.value) {
            if (notifServer.notifCenterExpanded) notifServer.notifCenterExpanded = false
            if (workspaceModule.overviewExpanded) workspaceModule.overviewExpanded = false
            if (musicModule.lyricsMode) musicModule.exitLyricsMode()
            if (musicModule.lyricsExpanded) musicModule.lyricsExpanded = false
        }
        recalc()
    }

    Connections {
        target: notifServer
        function onNotifCenterExpandedChanged() {
            if (eventBus) {
                eventBus.publish("modeChanged", { mode: "notifCenterExpanded", value: notifServer.notifCenterExpanded })
            }
            if (!notifServer.notifCenterExpanded) {
                notifCenter.expandedIndex = -1
                radiusRestoreTimer.restart()
                if (layout.hovered) {
                    volumeModule.show()
                    brightnessModule.show()
                }
            }
        }
        function onNotifActiveChanged() {
            recalc()
            if (notifServer.notifActive && musicModule.lyricsMode)
                musicModule.exitLyricsMode()
            if (notifServer.notifActive && workspaceModule.overviewExpanded)
                workspaceModule.overviewExpanded = false
        }
        function onNotifFadingChanged() {
            recalc()
        }
    }

    Connections {
        target: workspaceModule
        function onOverviewExpandedChanged() {
            if (eventBus) {
                eventBus.publish("modeChanged", { mode: "overviewExpanded", value: workspaceModule.overviewExpanded })
            }
        }
    }

    Connections {
        target: musicModule
        function onIsPlayingChanged() { recalc() }
        function onLyricsModeChanged() {
            recalc()
            if (musicModule.lyricsMode && eventBus) {
                eventBus.publish("modeChanged", { mode: "lyricsMode", value: true })
            }
        }
        function onLyricsExpandedChanged() {
            if (eventBus) {
                eventBus.publish("modeChanged", { mode: "lyricsExpanded", value: musicModule.lyricsExpanded })
            }
        }
    }

    Connections {
        target: batteryModule
        function onWidthChanged() { recalc() }
    }

    Connections {
        target: volumeModule
        function onWidthChanged() { recalc() }
    }

    Connections {
        target: brightnessModule
        function onWidthChanged() { recalc() }
    }

    Connections {
        target: networkModule
        function onNetworkExpandedChanged() {
            if (eventBus) {
                eventBus.publish("modeChanged", { mode: "networkExpanded", value: networkModule.networkExpanded })
            }
        }
        function onWidthChanged() { recalc() }
    }

    Connections {
        target: registry
        function onLayoutChanged() { recalc() }
    }

    Item {
        id: layoutContent
        anchors.left: parent.left
        anchors.leftMargin: layout.effectiveHPadding
        anchors.right: parent.right
        anchors.rightMargin: layout.effectiveHPadding
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        property real _opacity: (notifServer.notifCenterExpanded || musicModule.lyricsMode || musicModule.lyricsExpanded || workspaceModule.overviewExpanded || networkModule.networkExpanded) ? 0 : 1
        Behavior on _opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        opacity: _opacity
        visible: _opacity > 0.01

        Row {
            id: moduleRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            WorkspaceModule {
                id: workspaceModule
                anchors.verticalCenter: parent.verticalCenter
            }
            BatteryModule {
                id: batteryModule
                pillHovered: layout.hovered
                anchors.verticalCenter: parent.verticalCenter
            }
            VolumeModule {
                id: volumeModule
                pillHovered: layout.hovered
                anchors.verticalCenter: parent.verticalCenter
            }
            BrightnessModule {
                id: brightnessModule
                pillHovered: layout.hovered
                anchors.verticalCenter: parent.verticalCenter
            }
            MusicModule {
                id: musicModule
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: lyricsIcon
                text: "󰽰"
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 20
                color: "#cba6f7"
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

        ClockModule {
            id: clockModule
            anchors.centerIn: parent
        }

        Row {
            id: rightRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: albumArtContainer
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
            Text {
                id: notifBell
                text: "󰂞"
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 18
                color: "#cba6f7"
                opacity: notifServer.notifOpacity
                visible: notifServer.notifOpacity > 0.01
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifServer.notifCenterExpanded = !notifServer.notifCenterExpanded
                }
            }
            NetworkModule {
                id: networkModule
                pillHovered: layout.hovered
                anchors.verticalCenter: parent.verticalCenter
            }
            SystemTrayModule {
                id: trayModule
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    LyricsCompactOverlay {
        id: lyricsOverlay
        anchors.left: parent.left
        anchors.leftMargin: audioPeaks.overlayLeftInset
        anchors.right: parent.right
        anchors.rightMargin: audioPeaks.overlayRightInset
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        musicModule: layout.musicModule
        hovered: layout.hovered
    }

    WsOverviewOverlay {
        id: wsOverlay
        anchors.left: parent.left
        anchors.leftMargin: audioPeaks.overlayLeftInset
        anchors.right: parent.right
        anchors.rightMargin: audioPeaks.overlayRightInset
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        workspaceModule: layout.workspaceModule
    }

    LyricsExpandedOverlay {
        id: lyricsExpandedOverlay
        anchors.fill: parent
        musicModule: layout.musicModule
    }

    NotifCenterOverlay {
        id: notifCenter
        anchors.fill: parent
        notifServer: layout.notifServer
    }

    NetworkOverlay {
        id: networkOverlay
        anchors.fill: parent
        networkModule: layout.networkModule
    }

    Timer {
        id: radiusRestoreTimer
        interval: 400
        onTriggered: {
            if (!notifServer.notifCenterExpanded && !workspaceModule.overviewExpanded && !musicModule.lyricsMode && !musicModule.lyricsExpanded && !networkModule.networkExpanded)
                pillRadius = 0
        }
    }
}
