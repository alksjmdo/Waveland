import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var networkModule

    property real _opacity: networkModule.networkExpanded ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    opacity: _opacity
    visible: _opacity > 0.01

    property string _selectedSsid: ""
    property bool _needPassword: false
    property bool _showPassword: false

    Connections {
        target: networkModule
        function onNetworkExpandedChanged() {
            if (networkModule.networkExpanded) refreshWifi()
        }
    }

    function refreshWifi() {
        wifiScan.exec(["sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null | grep -v '^$'"])
    }

    Process {
        id: wifiScan
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var seen = {}
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length < 4 || !parts[1]) continue
                    var ssid = parts[1]
                    var sig = parseInt(parts[2]) || 0
                    var inUse = parts[0] === "*"
                    if (seen[ssid] === undefined) {
                        seen[ssid] = { signal: sig, inUse: inUse, security: parts[3] || "", secured: parts[3] !== "" && parts[3] !== "--" }
                    } else {
                        if (sig > seen[ssid].signal) seen[ssid].signal = sig
                        if (inUse) seen[ssid].inUse = true
                        if (seen[ssid].security === "" && parts[3] !== "" && parts[3] !== "--") {
                            seen[ssid].security = parts[3]
                            seen[ssid].secured = true
                        }
                    }
                }
                var items = []
                for (var key in seen) {
                    items.push({
                        inUse: seen[key].inUse,
                        ssid: key,
                        signal: seen[key].signal,
                        security: seen[key].security,
                        secured: seen[key].secured
                    })
                }
                items.sort(function(a, b) { return b.signal - a.signal })
                wifiModel.clear()
                for (var j = 0; j < items.length; j++)
                    wifiModel.append(items[j])
            }
        }
    }

    ListModel { id: wifiModel }

    Timer {
        id: wifiRescan
        interval: 100
        onTriggered: wifiScan.exec(["sh", "-c",
            "nmcli dev wifi rescan 2>/dev/null; sleep 2; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null | grep -v '^$'"])
    }

    Process {
        id: wifiConnect
        running: false
    }

    Row {
        id: networkTopRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 16
        spacing: 8

        Text {
            text: "󰛍"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 22
            color: "#89b4fa"
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: networkModule.networkExpanded = false
            }
        }

        ClockModule {
            id: networkClock
            scale: networkModule.networkExpanded ? 0.7 : 1
            Behavior on scale {
                SpringAnimation { spring: 2.0; damping: 0.5; mass: 1.0 }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: networkModule.networkExpanded = false
            }
        }

        Text {
            text: "󰑐"
            font.family: "JetBrainsMonoNL Nerd Font"
            font.pixelSize: 20
            color: "#6c7086"
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: wifiRescan.restart()
            }
        }
    }

    Item {
        id: wifiListView
        anchors.top: networkTopRow.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        clip: true

        ListView {
            anchors.fill: parent
            spacing: 4
            model: wifiModel

            delegate: Rectangle {
                id: wifiDelegate
                width: ListView.view.width
                height: 40
                radius: 8
                color: "transparent"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    spacing: 10

                    Text {
                        text: model.secured ? (model.signal <= 25 ? "󰤡" : model.signal <= 50 ? "󰤤" : model.signal <= 75 ? "󰤧" : "󰤪") : (model.signal <= 25 ? "󰤟" : model.signal <= 50 ? "󰤢" : model.signal <= 75 ? "󰤥" : "󰤨")
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 20
                        color: model.inUse ? "#7dc4e4" : "#6c7086"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: model.ssid
                        color: model.inUse ? "#7dc4e4" : "#cdd6f4"
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: model.inUse ? 52 : 40
                    height: 24
                    radius: 12
                    color: model.inUse ? "#313244" : "#89b4fa"

                    Text {
                        text: model.inUse ? "已连接" : "连接"
                        font.pixelSize: 11
                        color: model.inUse ? "#6c7086" : "#1e1e2e"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.secured) {
                                root._selectedSsid = model.ssid
                                wifiPasswordDialog.restart()
                            } else {
                                wifiConnect.exec(["nmcli", "dev", "wifi", "connect", model.ssid])
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: wifiPasswordDialog
        interval: 50
        onTriggered: wifiPasswordProc.exec(["sh", "-c",
            "zenity --password --title='连接 " + root._selectedSsid + "' 2>/dev/null"])
    }

    Process {
        id: wifiPasswordProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var pwd = text.trim()
                if (pwd) {
                    wifiConnect.exec(["nmcli", "dev", "wifi", "connect",
                        root._selectedSsid,
                        "password", pwd])
                }
            }
        }
    }
}
