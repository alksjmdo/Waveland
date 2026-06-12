import QtQuick
Item {
    id: container
    default property alias content: island.data
    property alias island: island
    property alias islandColor: island.color

    property int glowMargin: 6
    width: island.width + glowMargin * 2
    height: island.height + glowMargin * 2
    property int pillRadius: 0

    Rectangle {
        id: glow
        anchors.centerIn: parent
        anchors.topMargin:0
        width: island.width + 4
        height: island.height + 4
        radius: (container.pillRadius > 0 ? container.pillRadius : island.height / 2) + 6
        color: "#94e2d5"
        opacity: container.hovered ? 0.40 : 0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }
    }

    Rectangle {
        id: island
        anchors.centerIn: parent
        color: "#1e1e2e"
        radius: container.pillRadius > 0 ? container.pillRadius : height / 2
    }

    property bool hovered: hoverArea.containsMouse

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
    }
}
