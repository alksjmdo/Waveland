import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    required property var notifServer

    property real _opacity: notifServer.notifCenterExpanded ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    opacity: _opacity
    visible: _opacity > 0.01

    scale: notifServer.notifCenterExpanded ? 1 : 0.8
    Behavior on scale {
        SpringAnimation { spring: 2.0; damping: 0.5; mass: 1.0 }
    }

    property int expandedIndex: -1
    property bool clearing: false

    onClearingChanged: {
        if (clearing) clearTimer.restart()
    }

    Timer {
        id: clearTimer
        interval: 200
        onTriggered: {
            notifServer._notificationHistory = []
            notifServer.clearNotification = true
            root.clearing = false
        }
    }

    Row {
        id: notifTopRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        spacing: 12

        Text {
            id: notifIconTop
            text: "󰂞"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 33
            color: "#cba6f7"
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: notifServer.notifCenterExpanded = false
            }
        }

        ClockModule {
            id: notifClock
            scale: notifServer.notifCenterExpanded ? 0.7 : 1

            Behavior on scale {
                SpringAnimation { spring: 2.0; damping: 0.5; mass: 1.0 }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: notifServer.notifCenterExpanded = false
            }
        }

        Text {
            text: "󰂛"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 30
            color: "#6c7086"
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.clearing = true }
            }
        }
    }

    ListView {
        id: notifList
        anchors.top: notifTopRow.bottom
        anchors.topMargin: 18
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        clip: true
        spacing: 10
        opacity: root.clearing ? 0 : 1
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        model: notifServer._notificationHistory

        delegate: Rectangle {
            id: notifDelegate
            property int myIndex: index
            property bool expanded: root.expandedIndex === myIndex
            width: ListView.view.width
            height: expanded ? notifSummary.implicitHeight + 6 + bodyText.implicitHeight + 24 : (modelData.body && modelData.body !== "" ? 78 : 54)
            radius: 8
            color: "#313244"

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            Text {
                id: notifAppName
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.leftMargin: 15
                text: modelData.appName
                color: "#cdd6f4"
                font.pixelSize: 18
                width: Math.min(implicitWidth + 12, 135)
                elide: Text.ElideRight
            }

            Text {
                id: notifTime
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 15
                text: modelData.time
                color: "#585b70"
                font.pixelSize: 17
            }

            Text {
                id: notifSummary
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.left: notifAppName.right
                anchors.leftMargin: 10
                anchors.right: notifTime.left
                anchors.rightMargin: 10
                text: modelData.summary
                color: "#a6adc8"
                font.pixelSize: 18
                elide: notifDelegate.expanded ? Text.ElideNone : Text.ElideRight
                wrapMode: notifDelegate.expanded ? Text.WordWrap : Text.NoWrap
                maximumLineCount: notifDelegate.expanded ? 0 : 1
            }

            Text {
                id: bodyText
                anchors.top: notifSummary.bottom
                anchors.topMargin: 6
                anchors.left: parent.left
                anchors.leftMargin: 15
                anchors.right: parent.right
                anchors.rightMargin: 15
                text: modelData.body || ""
                color: notifDelegate.expanded ? "#cdd6f4" : "#6c7086"
                font.pixelSize: notifDelegate.expanded ? 22 : 16
                elide: notifDelegate.expanded ? Text.ElideNone : Text.ElideRight
                wrapMode: notifDelegate.expanded ? Text.WordWrap : Text.NoWrap
                maximumLineCount: notifDelegate.expanded ? 0 : 1
                visible: modelData.body && modelData.body !== ""
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.expandedIndex === myIndex)
                        root.expandedIndex = -1
                    else
                        root.expandedIndex = myIndex
                }
            }
        }
    }
}
