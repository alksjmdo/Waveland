import QtQuick
import Quickshell
import Quickshell.Services.UPower

Item {
    id: batteryModule
    property int idleWidth: row.implicitWidth
    property alias component: batteryModule
    property bool available: false
    property double percentage: 0
    property bool charging: false

    property string iconText: available ? batteryIcon() : ""

    Component.onCompleted: {
        var dev = UPower.displayDevice
        if (dev) {
            available = true
            refresh()
        }
    }

    Connections {
        target: UPower.displayDevice
        function onPercentageChanged() { refresh() }
        function onStateChanged() { refresh() }
    }

    function refresh() {
        var dev = UPower.displayDevice
        if (!dev || !available) return
        percentage = dev.percentage
        var st = dev.state
        charging = (st === UPowerDeviceState.Charging || st === UPowerDeviceState.PendingCharge)
    }

    function batteryIcon() {
        var dec = Math.round(percentage / 10)
        if (dec < 0) dec = 0
        if (dec > 10) dec = 10
        var icons = [
            "\uF008E", // 0%
            "\uF007A", // 10%
            "\uF007B", // 20%
            "\uF007C", // 30%
            "\uF007D", // 40%
            "\uF007E", // 50%
            "\uF007F", // 60%
            "\uF0080", // 70%
            "\uF0081", // 80%
            "\uF0082", // 90%
            "\uF0079"  // 100%
        ]
        return icons[dec]
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        visible: batteryModule.available

        Text {
            text: batteryModule.iconText
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
