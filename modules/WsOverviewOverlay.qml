import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var workspaceModule

    property real _opacity: workspaceModule.overviewExpanded ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    opacity: _opacity
    visible: _opacity > 0.01
    implicitWidth: _opacity > 0.01 ? (wsReturnBtn.implicitWidth + 8 + wsPillRow.implicitWidth) : 0

    Text {
        id: wsReturnBtn
        text: "\uF311"
        font.family: "JetBrainsMonoNL Nerd Font"
        font.pixelSize: 20
        color: "#f38ba8"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: workspaceModule.overviewExpanded = false
        }
    }

    Row {
        id: wsPillRow
        anchors.left: wsReturnBtn.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: {
                var all = workspaceModule.getSortedWsList()
                var filtered = []
                for (var i = 0; i < all.length; i++) {
                    if (workspaceModule.windowsOfWs(all[i]).length > 0)
                        filtered.push(all[i])
                }
                return filtered
            }

            Rectangle {
                id: wsPill
                width: pillRow.implicitWidth + 24
                height: 30
                radius: 14
                color: "#313244"
                border.width: isActiveWs ? 1 : 0
                border.color: "#cba6f7"

                property string wsId: String(modelData)
                property bool isActiveWs: String(wsId) === String(workspaceModule.activeWsId)

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var ws = workspaceModule._workspaces[wsPill.wsId]
                        var idx = ws ? ws.idx : 0
                        workspaceModule.niriAction("focus-workspace " + idx)
                    }
                }

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: workspaceModule.iconForWs(wsPill.wsId)
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 20
                        color: "#cba6f7"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: workspaceModule.windowsOfWs(wsPill.wsId)
                        IconImage {
                            width: 20
                            height: 20
                            asynchronous: true
                            source: workspaceModule._iconPaths[modelData.app_id] || ""
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    workspaceModule.niriAction("focus-window --id " + modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
