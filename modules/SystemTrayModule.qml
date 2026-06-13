import QtQuick
import QtQuick.Layouts
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
                    width: visible ? 20 : 0
                    height: 20
                    visible: modelData.id !== "nm-applet"
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    IconImage {
                        anchors.fill: parent
                        source: modelData.icon
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton)
                                modelData.secondaryActivate()
                            else
                                modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
