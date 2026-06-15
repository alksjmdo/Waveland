import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: volumeModule
    implicitWidth: active ? iconCell.width + row.spacing + volPct.implicitWidth : 0
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
    property bool _pctVisible: false

    on_ContentVisibleChanged: {
        if (_contentVisible) repaintTimer.restart()
    }

    property real _opacity: _contentVisible ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    function sinkAudio() {
        var node = Pipewire.defaultAudioSink
        return node ? node.audio : null
    }

    onPillHoveredChanged: {
        if (pillHovered) {
            _shownByHover = true
            volumeModule.show()
        } else if (_shownByHover) {
            _shownByHover = false
            _pctVisible = false
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
        interval: 500
        onTriggered: {
            volumeModule._contentVisible = true
            if (volumeModule.pillHovered) volumeModule._pctVisible = true
        }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            if (volumeModule.pillHovered) {
                hideTimer.restart()
            } else {
                volumeModule.active = false
            }
        }
    }

    Timer {
        id: volumePollTimer
        interval: 300
        running: volumeModule._ready
        repeat: true
        property double _lastVol: NaN
        property bool _lastMuted: false
        onTriggered: {
            var a = volumeModule.sinkAudio()
            if (!a) return
            var vol = a.muted ? 0 : a.volume
            if (isNaN(_lastVol)) {
                _lastVol = vol
                _lastMuted = a.muted
            } else if (vol !== _lastVol || a.muted !== _lastMuted) {
                _lastVol = vol
                _lastMuted = a.muted
                volumeModule.showVolume()
            }
        }
    }

    Timer {
        id: repaintTimer
        interval: 50
        onTriggered: ringCanvas.requestPaint()
    }

    function show() {
        if (!active) {
            _contentVisible = false
            volumeModule.active = true
            showContentTimer.restart()
        } else {
            repaintTimer.restart()
        }
        hideTimer.restart()
    }

    function showVolume() {
        if (!_ready) return
        _shownByHover = false
        show()
    }

    function volumeIcon() {
        var a = sinkAudio()
        if (!a) return "󰕾"
        if (a.muted) return ""
        if (a.volume <= 0.01) return ""
        if (a.volume <= 0.20) return ""
        if (a.volume <= 0.40) return ""
        if (a.volume <= 0.60) return "󰕾"
        if (a.volume <= 0.80) return ""
        return ""
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
                opacity: volumeModule._opacity
                visible: volumeModule._opacity > 0.01

                onPaint: {
                    if (width < 4 || height < 4) return
                    var a = volumeModule.sinkAudio()
                    if (!a) return
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var vol = a.muted ? 0 : a.volume
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

        Text {
            id: volPct
            text: {
                var a = volumeModule.sinkAudio()
                return a ? Math.round(a.volume * 100) + "%" : "0%"
            }
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter

            property real _hoverOpacity: volumeModule._pctVisible ? 1 : 0
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
