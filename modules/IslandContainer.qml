import QtQuick
Item {
    id: container
    default property alias content: island.data
    property alias island: island
    property alias islandColor: island.color

    property int glowMargin: 5
    width: island.width + glowMargin * 2
    height: island.height + glowMargin * 2
    property int pillRadius: 0

    Rectangle {
        id: glow
        anchors.fill: parent
        radius: (container.pillRadius > 0 ? container.pillRadius : island.height / 2) + glowMargin
        color: "#94e2d5"
        opacity: container.hovered ? 0.4 : 0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }
    }

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: glowMargin
        color: "#1e1e2e"
        radius: container.pillRadius > 0 ? container.pillRadius : height / 2
        clip: true
    }

    property bool hovered: hoverArea.containsMouse

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }
}
