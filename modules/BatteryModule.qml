import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: batteryModule
    implicitHeight: 42
    implicitWidth: active ? iconCell.width + row.spacing + battPct.implicitWidth : row.implicitWidth
    width: implicitWidth
    height: 42

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    property alias component: batteryModule
    property bool pillHovered: false
    property bool active: false
    property bool _contentVisible: false
    property bool _pctVisible: false

    property double percentage: 100
    property string status: "Full"
    property bool charging: status !== "Discharging"
    property string powerProfile: "balanced"
    property bool profileMode: false

    onPercentageChanged: ringCanvas.requestPaint()
    onProfileModeChanged: ringCanvas.requestPaint()
    onPowerProfileChanged: ringCanvas.requestPaint()

    onPillHoveredChanged: {
        if (pillHovered) {
            batteryModule.show()
        } else {
            batteryModule.hide()
        }
    }

    function show() {
        if (!active) {
            batteryModule.active = true
            showContentTimer.restart()
        }
    }

    function hide() {
        _pctVisible = false
        _contentVisible = false
        hideActiveTimer.restart()
    }

    function ringColor() {
        if (profileMode) return profileColor()
        if (charging) return "#a6e3a1"
        if (percentage > 60) return "#a6e3a1"
        if (percentage > 20) return "#f9e2af"
        return "#f38ba8"
    }

    function profileIcon() {
        if (powerProfile === "performance") return ""
        if (powerProfile === "balanced") return ""
        return ""
    }

    function profileColor() {
        if (powerProfile === "performance") return "#d20f39"
        if (powerProfile === "balanced") return "#8aadf4"
        return "#a6e3a1"
    }

    function profileLabel() {
        if (powerProfile === "performance") return "性能"
        if (powerProfile === "balanced") return "均衡"
        return "节能"
    }

    function profileNext() {
        if (powerProfile === "performance") return "balanced"
        if (powerProfile === "balanced") return "power-saver"
        return "performance"
    }

    function cycleProfile() {
        var next = profileNext()
        batteryModule.powerProfile = next
        profileProc.exec(["powerprofilesctl", "set", next])
    }

    Process {
        id: battProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(" ")
                if (parts.length >= 2) {
                    var val = parseFloat(parts[0])
                    if (!isNaN(val)) {
                        batteryModule.percentage = val
                    }
                    batteryModule.status = parts[1]
                }
            }
        }
    }

    Process {
        id: profileProc
        running: false
    }

    Process {
        id: profileGetProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim()
                if (p) batteryModule.powerProfile = p
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            battProcess.exec(["sh", "-c",
                "echo $(cat /sys/class/power_supply/BAT1/capacity) $(cat /sys/class/power_supply/BAT1/status)"])
            profileGetProc.exec(["powerprofilesctl", "get"])
        }
    }

    Timer {
        id: profileExitTimer
        interval: 5000
        onTriggered: batteryModule.profileMode = false
    }

    Timer {
        id: hideActiveTimer
        interval: 250
        onTriggered: batteryModule.active = false
    }

    Timer {
        id: showContentTimer
        interval: 600
        onTriggered: {
            batteryModule._contentVisible = true
            batteryModule._pctVisible = true
        }
    }

    function toggleProfile() {
        if (!profileMode) {
            profileMode = true
            profileExitTimer.restart()
        } else {
            cycleProfile()
            profileExitTimer.restart()
            ringCanvas.requestPaint()
        }
    }

    function batteryIcon() {
        var pct = Math.round(percentage)
        if (pct <= 5) return "󰂎"
        if (pct <= 15) return "󰁺"
        if (pct <= 25) return "󰁻"
        if (pct <= 35) return "󰁼"
        if (pct <= 45) return "󰁽"
        if (pct <= 55) return "󰁾"
        if (pct <= 65) return "󰁿"
        if (pct <= 75) return "󰂀"
        if (pct <= 85) return "󰂁"
        if (pct <= 95) return "󰂂"
        return "󰁹"
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
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var pct = batteryModule.percentage / 100
                    if (pct <= 0) return

                    var cx = width / 2
                    var cy = height / 2
                    var r = 12
                    var col = batteryModule.ringColor()

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + pct * 2 * Math.PI, false)
                    ctx.strokeStyle = col
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }

            Text {
                id: battIcon
                text: batteryModule.charging ? "󰚥" : batteryModule.batteryIcon()
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 18
                color: batteryModule.ringColor()
                anchors.centerIn: parent
                visible: !batteryModule.profileMode
            }

            Text {
                text: batteryModule.profileIcon()
                font.family: "JetBrainsMonoNL Nerd Font"
                font.pixelSize: 14
                color: batteryModule.profileColor()
                anchors.centerIn: parent
                visible: batteryModule.profileMode
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (batteryModule.pillHovered)
                        batteryModule.toggleProfile()
                }
            }
        }

        Text {
            id: battPct
            text: Math.round(batteryModule.percentage) + "%"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter

            property real _opacity: batteryModule._pctVisible && !batteryModule.profileMode ? 1 : 0
            Behavior on _opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            opacity: _opacity
            width: _opacity > 0.01 ? implicitWidth : 0
            clip: true
        }
    }

    Component.onCompleted: profileGetProc.exec(["powerprofilesctl", "get"])
}
