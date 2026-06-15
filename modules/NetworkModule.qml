import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: networkModule
    implicitWidth: active ? row.implicitWidth : 0
    implicitHeight: 42
    width: implicitWidth
    clip: true

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    property alias component: networkModule
    property bool active: false
    property bool pillHovered: false
    property bool _shownByHover: false
    property bool _contentVisible: false
    property bool _pctVisible: false
    property bool networkExpanded: false

    on_ContentVisibleChanged: {
        if (!_contentVisible) hideActiveTimer.restart()
    }

    property real _opacity: _contentVisible ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    property double signalPct: 0
    property string ssid: ""
    property bool connected: false
    property bool _ready: false

    onPillHoveredChanged: {
        if (pillHovered) {
            _shownByHover = true
            networkModule.show()
        } else if (_shownByHover) {
            _shownByHover = false
            _pctVisible = false
            _contentVisible = false
        }
    }

    Process {
        id: nmcliProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n")
                if (parts.length >= 3) {
                    var conn = parts[0] === "1"
                    var pct = 0
                    if (parts[1] !== "") pct = parseFloat(parts[1])
                    if (isNaN(pct)) pct = 0
                    var name = parts[2] || ""
                    if (conn !== networkModule.connected || pct !== networkModule.signalPct) {
                        networkModule.connected = conn
                        networkModule.signalPct = pct
                        networkModule.ssid = name
                        if (networkModule._ready) networkModule.showNetwork()
                    }
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: nmcliProc.exec(["sh", "-c",
            "nmcli -t -f WIFI g 2>/dev/null | grep -q enabled && echo 1 || echo 0;" +
            "nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list 2>/dev/null | grep '^\\*' | cut -d: -f2;" +
            "nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list 2>/dev/null | grep '^\\*' | cut -d: -f3"])
    }

    Timer {
        id: readyTimer
        interval: 2000
        running: true
        onTriggered: networkModule._ready = true
    }

    function show() {
        if (!active) {
            _contentVisible = false
            networkModule.active = true
            showContentTimer.restart()
        }
        hideTimer.restart()
    }

    function showNetwork() {
        _shownByHover = false
        show()
    }

    Timer {
        id: hideActiveTimer
        interval: 250
        onTriggered: networkModule.active = false
    }

    Timer {
        id: showContentTimer
        interval: 600
        onTriggered: {
            networkModule._contentVisible = true
            if (networkModule.pillHovered) networkModule._pctVisible = true
        }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            if (networkModule.pillHovered || !networkModule.connected) {
                hideTimer.restart()
            } else {
                networkModule._contentVisible = false
            }
        }
    }

    function signalIcon() {
        if (!connected) return "󰤫"
        if (signalPct <= 25) return "󰤟"
        if (signalPct <= 50) return "󰤢"
        if (signalPct <= 75) return "󰤥"
        return "󰤨"
    }

    function labelColor() {
        return connected ? "#b4befe" : "#f38ba8"
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            id: networkLabel
            text: networkModule.connected ? networkModule.ssid + " " + Math.round(networkModule.signalPct) + "%" : "已断开"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 13
            color: networkModule.labelColor()
            anchors.verticalCenter: parent.verticalCenter

            property real _hoverOpacity: networkModule._pctVisible ? 1 : 0
            Behavior on _hoverOpacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            opacity: _hoverOpacity
            width: _hoverOpacity > 0.01 ? implicitWidth : 0
            clip: true
        }

        Text {
            text: networkModule.signalIcon()
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 18
            color: networkModule.labelColor()
            anchors.verticalCenter: parent.verticalCenter
            opacity: networkModule._opacity
            visible: networkModule._opacity > 0.01
        }
    }

    MouseArea {
        width: row.implicitWidth
        height: 42
        anchors.verticalCenter: parent.verticalCenter
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (networkModule.pillHovered)
                networkModule.networkExpanded = !networkModule.networkExpanded
        }
    }
}
