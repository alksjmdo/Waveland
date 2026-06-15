import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: volumeModule
    implicitWidth: active ? row.implicitWidth : 0
    implicitHeight: 42
    width: implicitWidth

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    property alias component: volumeModule
    property bool active: false

    property var audio: Pipewire.defaultAudioSink.audio

    property real _opacity: active ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio
        function onVolumeChanged() { volumeModule.show() }
        function onMutedChanged() { volumeModule.show() }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: volumeModule.active = false
    }

    function show() {
        if (!active) volumeModule.active = true
        hideTimer.restart()
    }

    function volumeIcon() {
        if (audio.muted || audio.volume === 0) return "\uF5FF"
        if (audio.volume <= 0.33) return "\uF57F"
        if (audio.volume <= 0.66) return "\uF580"
        return "\uF57E"
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        opacity: volumeModule._opacity
        visible: volumeModule._opacity > 0.01

        Text {
            text: volumeModule.volumeIcon()
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 18
            color: "#89b4fa"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Math.round(volumeModule.audio.volume * 100) + "%"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
