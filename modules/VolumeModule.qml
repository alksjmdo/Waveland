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
    property bool pillHovered: false

    property var audio: Pipewire.defaultAudioSink.audio

    property real _opacity: active ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    onPillHoveredChanged: {
        if (pillHovered) {
            volumeModule.show()
        } else if (volumeModule.active) {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            if (!volumeModule.pillHovered)
                volumeModule.active = false
            else
                hideTimer.restart()
        }
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio
        function onVolumeChanged() { volumeModule.show() }
        function onMutedChanged() { volumeModule.show() }
    }

    Timer {
        id: repaintTimer
        interval: 50
        onTriggered: ringCanvas.requestPaint()
    }

    function show() {
        if (!active) volumeModule.active = true
        hideTimer.restart()
        repaintTimer.restart()
    }

    function volumeIcon() {
        if (audio.muted || audio.volume === 0) return "󰝟"
        if (audio.volume <= 0.33) return "󰕿"
        if (audio.volume <= 0.66) return "󰖀"
        return "󰕾"
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Item {
            id: iconCell
            width: 30
            height: 42

            Canvas {
                id: ringCanvas
                anchors.fill: parent

                onPaint: {
                    if (width < 4 || height < 4) return
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var vol = volumeModule.audio.muted ? 0 : volumeModule.audio.volume
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
            }
        }

        Text {
            id: volPct
            text: Math.round(volumeModule.audio.volume * 100) + "%"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter

            property real _hoverOpacity: volumeModule.pillHovered ? 1 : 0
            Behavior on _hoverOpacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            opacity: _hoverOpacity
            width: _hoverOpacity > 0.01 ? implicitWidth : 0
            clip: true
        }
    }
}
