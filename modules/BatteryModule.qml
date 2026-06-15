import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: batteryModule
    property int maxWidth: battIcon.implicitWidth + 2 + battPct.implicitWidth
    implicitWidth: maxWidth
    implicitHeight: 42
    width: row.implicitWidth
    height: 42

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    property alias component: batteryModule
    property bool pillHovered: false

    property double percentage: 100
    property string status: "Full"
    property bool charging: status !== "Discharging"

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

    Timer {
        id: pollTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: battProcess.exec(["sh", "-c",
            "echo $(cat /sys/class/power_supply/BAT1/capacity) $(cat /sys/class/power_supply/BAT1/status)"])
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

        Text {
            id: battIcon
            text: batteryModule.charging ? "󰚥" : batteryModule.batteryIcon()
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 18
            color: "#a6e3a1"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: battPct
            text: Math.round(batteryModule.percentage) + "%"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter

            property real _opacity: batteryModule.pillHovered ? 1 : 0
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
}
