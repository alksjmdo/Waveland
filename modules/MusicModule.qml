import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Item {
    id: musicModule
    implicitWidth: 0
    implicitHeight: 42
    Layout.alignment: Qt.AlignVCenter

    property bool isPlaying: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackArtUrl: ""
    property var activePlayer: null

    function refreshState() {
        var players = Mpris.players.values
        var found = false
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p && p.isPlaying) {
                if (!found) {
                    found = true
                    isPlaying = true
                    activePlayer = p
                    trackTitle = p.trackTitle || ""
                    trackArtist = p.trackArtist || ""
                    trackArtUrl = p.trackArtUrl || ""
                }
            }
        }
        if (!found) {
            isPlaying = false
            activePlayer = null
            trackTitle = ""
            trackArtist = ""
            trackArtUrl = ""
        }
    }

    Component.onCompleted: refreshState()

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: musicModule.refreshState()
    }
}
