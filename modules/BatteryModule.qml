import QtQuick
import Quickshell
import Quickshell.Services.UPower

Item {
    id: batteryModule
    width: row.implicitWidth
    height: row.implicitHeight
    property alias component: batteryModule

    property double percentage: 100

    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            var dev = UPower.displayDevice
            if (dev) {
                batteryModule.percentage = dev.percentage
            }
        }
    }

    function batteryIcon() {
        var pct = Math.round(percentage)
        if (pct <= 5) return "\uF008E"
        if (pct <= 15) return "\uF007A"
        if (pct <= 25) return "\uF007B"
        if (pct <= 35) return "\uF007C"
        if (pct <= 45) return "\uF007D"
        if (pct <= 55) return "\uF007E"
        if (pct <= 65) return "\uF007F"
        if (pct <= 75) return "\uF0080"
        if (pct <= 85) return "\uF0081"
        if (pct <= 95) return "\uF0082"
        return "\uF0079"
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
