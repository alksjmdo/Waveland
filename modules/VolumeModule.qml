import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: volumeModule
    implicitWidth: active ? row.implicitWidth : 0
    implicitHeight: 42
    width: implicitWidth
    clip: true

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    property alias component: volumeModule
    property bool active: false
    property bool pillHovered: false
    property bool _ready: false
    property bool _shownByHover: false
    property bool _contentVisible: false

    property real _opacity: _contentVisible ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    onPillHoveredChanged: {
        if (pillHovered) {
            _shownByHover = true
            volumeModule.show()
        } else if (_shownByHover) {
            _shownByHover = false
            _contentVisible = false
            volumeModule.active = false
        }
    }

    Timer {
        id: readyTimer
        interval: 1000
        running: true
        onTriggered: volumeModule._ready = true
    }

    Timer {
        id: showContentTimer
        interval: 220
        onTriggered: volumeModule._contentVisible = true
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: volumeModule.active = false
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio
        function onVolumeChanged() { volumeModule.showVolume() }
        function onMutedChanged() { volumeModule.showVolume() }
    }

    Timer {
        id: repaintTimer
        interval: 50
        onTriggered: ringCanvas.requestPaint()
    }

    function show() {
        _contentVisible = false
        if (!active) volumeModule.active = true
        showContentTimer.restart()
        hideTimer.restart()
        repaintTimer.restart()
    }

    function showVolume() {
        if (!_ready) return
        _shownByHover = false
        show()
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
