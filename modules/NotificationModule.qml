import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

Item {
    id: notifModule
    implicitWidth: notifIcon.visible ? 24 : 0
    implicitHeight: 42
    Layout.alignment: Qt.AlignVCenter

    Behavior on x {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    property bool active: false

    NotificationServer {
        onNotification: function(notification) {
            notifModule.active = true
        }
    }

    Timer {
        id: dismissTimer
        interval: 5000
        onTriggered: notifModule.active = false
    }

    onActiveChanged: {
        if (active) {
            _opacity = 1
            dismissTimer.restart()
        } else {
            _opacity = 0
        }
    }

    property real _opacity: 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    Text {
        id: notifIcon
        anchors.centerIn: parent
        text: "󱅫"
        font.family: "JetBrainsMonoNL Nerd Font"
        font.pixelSize: 18
        color: "#cba6f7"
        opacity: notifModule._opacity
        visible: notifModule._opacity > 0.01
    }
}
