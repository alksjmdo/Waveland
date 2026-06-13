import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: trayModule
    implicitWidth: Math.max(40, trayRow.implicitWidth + 8)
    implicitHeight: 42
    Layout.alignment: Qt.AlignVCenter

    Behavior on x {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    Process {
        id: killProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var pid = parseInt(text.trim())
                if (!isNaN(pid) && pid > 1) {
                    finalKill.exec(["kill", "-9", String(pid)])
                }
            }
        }
    }

    Process {
        id: finalKill
        running: false
    }

    function killApp(id) {
        killProc.exec(["dbus-send", "--session", "--print-reply=literal",
            "--dest=org.freedesktop.DBus", "/org/freedesktop/DBus",
            "org.freedesktop.DBus.GetConnectionUnixProcessID", "string:" + id])
    }

        Rectangle {
            id: capsule
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        width: trayRow.implicitWidth + 8
        height: 28
        radius: 14
        color: "#313244"

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 2
            Repeater {
                model: SystemTray.items
                Item {
                    id: trayItem
                    width: visible ? 20 : 0
                    height: 20
                    visible: modelData.id !== "nm-applet"
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    IconImage {
                        anchors.fill: parent
                        source: modelData.icon
                    }
                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: function(mouse) {
                            if (mouse.button === Qt.RightButton)
                                trayModule.killApp(modelData.id)
                        }
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton)
                                modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
