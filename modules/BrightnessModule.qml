import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: brightnessModule
    implicitWidth: active ? iconCell.width + row.spacing + brightPct.implicitWidth : 0
    implicitHeight: 42
    width: implicitWidth
    clip: true

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    property alias component: brightnessModule
    property bool active: false
    property bool pillHovered: false
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

    property double brightness: 0
    property bool _ready: false

    onPillHoveredChanged: {
        if (pillHovered) {
            _shownByHover = true
            brightnessModule.show()
        } else if (_shownByHover) {
            _shownByHover = false
            _pctVisible = false
            _contentVisible = false
            _hideActiveTimer.restart()
        }
    }

    Process {
        id: backlightProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n")
                if (parts.length >= 2) {
                    var b = parseFloat(parts[0])
                    var m = parseFloat(parts[1])
                    if (!isNaN(b) && !isNaN(m) && m > 0) {
                        var newB = b / m
                        if (brightnessModule._ready && brightnessModule.brightness !== newB) {
                            brightnessModule.brightness = newB
                            brightnessModule.showBrightness()
                        } else if (!brightnessModule._ready) {
                            brightnessModule.brightness = newB
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 300
        running: true
        repeat: true
        onTriggered: backlightProc.exec(["sh", "-c",
            "cat /sys/class/backlight/*/brightness; cat /sys/class/backlight/*/max_brightness"])
    }

    Timer {
        id: readyTimer
        interval: 1000
        running: true
        onTriggered: brightnessModule._ready = true
    }

    Timer {
        id: showContentTimer
        interval: 600
        onTriggered: {
            brightnessModule._contentVisible = true
            if (brightnessModule.pillHovered) brightnessModule._pctVisible = true
        }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            if (brightnessModule.pillHovered) {
                hideTimer.restart()
            } else {
                brightnessModule._contentVisible = false
                brightnessModule._hideActiveTimer.restart()
            }
        }
    }

    Timer {
        id: _hideActiveTimer
        interval: 250
        onTriggered: brightnessModule.active = false
    }

    Timer {
        id: repaintTimer
        interval: 50
        onTriggered: ringCanvas.requestPaint()
    }

    function show() {
        if (!active) {
            _contentVisible = false
            brightnessModule.active = true
            showContentTimer.restart()
        } else {
            repaintTimer.restart()
        }
        hideTimer.restart()
    }

    function showBrightness() {
        _shownByHover = false
        show()
    }

    function brightnessIcon() {
        if (brightness <= 0.33) return "󰃜"
        if (brightness <= 0.66) return "󰃛"
        return "󰃚"
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
                opacity: brightnessModule._opacity
                visible: brightnessModule._opacity > 0.01

                onPaint: {
                    if (width < 4 || height < 4) return
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var b = brightnessModule.brightness
                    if (b <= 0 || isNaN(b)) return

                    var cx = width / 2
                    var cy = height / 2
                    var r = 12

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + b * 2 * Math.PI, false)
                    ctx.strokeStyle = "#f9e2af"
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }

            Text {
                text: brightnessModule.brightnessIcon()
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 18
                color: "#f9e2af"
                anchors.centerIn: parent
                opacity: brightnessModule._opacity
                visible: brightnessModule._opacity > 0.01
            }
        }

        Text {
            id: brightPct
            text: Math.round(brightnessModule.brightness * 100) + "%"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter

            property real _hoverOpacity: brightnessModule._pctVisible ? 1 : 0
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
