import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root

    property bool musicPlaying: false
    property bool lyricsMode: false
    property color peakColor: "#cba6f7"
    property real musicOpacity: 0

    readonly property int barCount: 12
    readonly property int barWidth: 2
    readonly property int barSpacing: 4
    readonly property int clusterWidth: barCount * (barWidth + barSpacing) - barSpacing
    readonly property int leftMargin: 6
    readonly property int rightMargin: 6

    readonly property int leftWaveRightEdgeMargin: leftMargin + clusterWidth
    readonly property int rightWaveLeftEdgeMargin: rightMargin + clusterWidth
    readonly property int overlayLeftInset: leftMargin + clusterWidth + 20
    readonly property int overlayRightInset: rightMargin + clusterWidth + 20

    PwNodePeakMonitor {
        id: peakMonitor
        node: Pipewire.defaultAudioSink
        enabled: musicPlaying
    }

    ListModel {
        id: waveModel
        Component.onCompleted: {
            for (var i = 0; i < barCount; i++) append({ barHeight: 4 })
        }
    }

    function updatePeaks() {
        if (!peakMonitor || peakMonitor.peaks.length === 0) return
        var peak = Math.min(1.0, peakMonitor.peak * 2.0)
        for (var i = 0; i < barCount; i++) {
            var factor = 0.3 + Math.random() * 0.7
            var target = Math.max(4, peak * 24 * factor)
            waveModel.setProperty(i, "barHeight", target)
        }
    }

    Timer {
        id: peakTimer
        interval: 100
        running: musicPlaying && musicOpacity > 0.5
        repeat: true
        onTriggered: updatePeaks()
    }

    Row {
        id: leftWaves
        anchors.left: parent.left
        anchors.leftMargin: root.leftMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: barSpacing
        opacity: musicOpacity * (musicPlaying ? 1 : 0)
        visible: musicOpacity > 0.01 && musicPlaying
        Repeater {
            model: waveModel
            Rectangle {
                width: barWidth
                height: model.barHeight
                radius: 1
                color: lyricsMode ? root.peakColor : "#cba6f7"
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
        anchors.rightMargin: root.rightMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: barSpacing
        opacity: musicOpacity * (musicPlaying ? 1 : 0)
        visible: musicOpacity > 0.01 && musicPlaying
        layoutDirection: Qt.RightToLeft
        Repeater {
            model: waveModel
            Rectangle {
                width: barWidth
                height: model.barHeight
                radius: 1
                color: lyricsMode ? root.peakColor : "#cba6f7"
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
}
