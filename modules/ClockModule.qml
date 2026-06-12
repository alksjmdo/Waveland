import QtQuick

Item {
    id: clock
    implicitWidth: 64
    implicitHeight: 42

    Text {
        id: timeLabel
        anchors.centerIn: parent
        color: "#cdd6f4"
        font.pixelSize: 24
    }

    Timer {
        interval: 500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            timeLabel.text = now.toLocaleString(Qt.locale("en_US"), "HH:mm")
        }
    }
}
