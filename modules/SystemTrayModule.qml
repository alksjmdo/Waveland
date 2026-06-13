import QtQuick
import QtQuick.Window
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

    property var shellWindow: null

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

        stdout: StdioCollector {
            onStreamFinished: {
                var pid = parseInt(text.trim())
                if (!isNaN(pid) && pid > 1) {
                    killProc2.exec(["kill", "-9", String(pid)])
                }
            }
        }
    }

    Process {
        id: killProc2
    }

    function killApp(id) {
        killProc.exec(["sh", "-c",
            "dbus-send --session --print-reply=literal --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.GetConnectionUnixProcessID string:" + id + " 2>/dev/null | grep -oP 'uint32 \\K\\d+' | head -1"])
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
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                killProc.exec(["touch", "/tmp/tray-pressed-" + modelData.id])
                            }
                        }
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                killProc.exec(["touch", "/tmp/tray-clicked-" + modelData.id])
                            } else {
                                modelData.activate()
                            }
                        }
                    }
                }
            }
        }
    }
}
