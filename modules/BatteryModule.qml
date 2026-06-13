import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: batteryModule
    width: row.implicitWidth
    height: row.implicitHeight
    property alias component: batteryModule

    property double percentage: 100

    Process {
        id: battProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseFloat(text.trim())
                if (!isNaN(val)) {
                    batteryModule.percentage = val
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: battProcess.exec(["cat", "/sys/class/power_supply/BAT1/capacity"])
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
            text: batteryModule.batteryIcon()
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 16
            color: "#a6e3a1"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Math.round(batteryModule.percentage) + "%"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
