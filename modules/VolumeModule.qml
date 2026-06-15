import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: volumeModule
    implicitWidth: active ? 30 : 0
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

    property real displayVolume: 0

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
        displayVolume = audio.muted ? 0 : audio.volume
        if (!active) volumeModule.active = true
        hideTimer.restart()
        ringCanvas.requestPaint()
    }

    function volumeIcon() {
        if (audio.muted || audio.volume === 0) return "󰝟"
        if (audio.volume <= 0.33) return "󰕿"
        if (audio.volume <= 0.66) return "󰖀"
        return "󰕾"
    }

    Canvas {
        id: ringCanvas
        anchors.fill: parent
        opacity: volumeModule._opacity
        visible: volumeModule._opacity > 0.01

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var vol = volumeModule.displayVolume
            if (vol <= 0) return

            var cx = width / 2
            var cy = height / 2
            var r = 12

            ctx.beginPath()
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + vol * 2 * Math.PI, false)
            ctx.strokeStyle = "#89b4fa"
            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.stroke()
        }
    }

    Text {
        text: volumeModule.volumeIcon()
        font.family: "JetBrainsMonoNL Nerd Font"
        font.pixelSize: 18
        color: "#89b4fa"
        anchors.centerIn: parent
        opacity: volumeModule._opacity
        visible: volumeModule._opacity > 0.01
    }
}
