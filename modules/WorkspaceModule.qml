import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: workspaceModule
    implicitWidth: Math.max(80, capsule.width)
    implicitHeight: 42
    Layout.alignment: Qt.AlignVCenter
    property bool hovered: false

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

    property var _workspaces: ({})
    property var _windows: ({})
    property int activeWsId: -1
    property var _filteredList: []
    property var _displayList: []
    property bool _collapsing: false
    property var _pendingDisplayList: []

    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: {
            _collapsing = false
            _displayList = _pendingDisplayList
        }
    }

    function refreshDisplay() {
        if (_collapsing) {
            _pendingDisplayList = activeWsId >= 0 ? [activeWsId] : []
            return
        }
        if (hovered) {
            _displayList = _filteredList.slice()
            if (activeWsId >= 0 && _filteredList.indexOf(activeWsId) < 0) {
                _displayList.push(activeWsId)
            }
            _displayList.sort(function(a, b) {
                return (_workspaces[a] ? _workspaces[a].idx : 0) -
                       (_workspaces[b] ? _workspaces[b].idx : 0)
            })
        } else {
            _displayList = activeWsId >= 0 ? [activeWsId] : []
        }
    }
    property var _iconMap: ({
        "web": "󰈹",
        "code": "󰨞",
        "chat": "",
        "wps": "󰈬",
        "vpn": "",
        "game": "",
        "urgent": "",
        "default": "",
        "empty": "",
        "active": "󰮯"
    })

    function hasWindows(wsId) {
        var wins = Object.keys(_windows)
        for (var i = 0; i < wins.length; i++) {
            if (_windows[wins[i]].workspace_id == wsId) return true
        }
        return false
    }

    function iconForWs(wsId) {
        var ws = _workspaces[wsId]
        if (!ws) return _iconMap["default"]
        if (!hasWindows(wsId)) return _iconMap["empty"]
        var name = ws.name
        if (name && _iconMap[name]) return _iconMap[name]
        return _iconMap["default"]
    }

    function refreshFiltered() {
        var seen = {}
        var ids = []
        var winKeys = Object.keys(_windows)
        for (var i = 0; i < winKeys.length; i++) {
            var wsid = _windows[winKeys[i]].workspace_id
            if (wsid && !seen[wsid] && _workspaces[wsid]) {
                seen[wsid] = true
                ids.push(wsid)
            }
        }
        ids.sort(function(a, b) {
            return (_workspaces[a] ? _workspaces[a].idx : 0) -
                   (_workspaces[b] ? _workspaces[b].idx : 0)
        })
        if (_collapsing) {
            _collapsing = false
            collapseTimer.stop()
        }
        _filteredList = ids
        refreshDisplay()
    }

    onHoveredChanged: {
        if (!hovered && _displayList.length > 1) {
            _collapsing = true
            _pendingDisplayList = activeWsId >= 0 ? [activeWsId] : []
            collapseTimer.restart()
        } else {
            _collapsing = false
            collapseTimer.stop()
            refreshDisplay()
        }
    }

    Socket {
        id: niriSocket
        path: Quickshell.env("NIRI_SOCKET") || ""
        connected: true
        parser: SplitParser {
            splitMarker: "\n"
            onRead: function(data) {
                if (data.length > 0 && data.startsWith("{")) {
                    try {
                        var event = JSON.parse(data)
                        workspaceModule.handleEvent(event)
                    } catch(e) {}
                }
            }
        }
        onConnectedChanged: function() {
            if (niriSocket.connected) {
                niriSocket.write('{"EventStream":null}\n')
                niriSocket.flush()
            }
        }
        onError: function(err) {
            console.log("niri socket error:", err)
        }
    }

    Component.onCompleted: {
        if (niriSocket.connected) {
            niriSocket.write('{"EventStream":null}\n')
            niriSocket.flush()
        }
    }

    function handleEvent(event) {
        if (event.WorkspacesChanged) {
            var ws = {}
            var list = event.WorkspacesChanged.workspaces
            for (var i = 0; i < list.length; i++) {
                var w = list[i]
                ws[w.id] = {
                    name: w.name || String(w.id),
                    isActive: w.is_active || false,
                    idx: w.idx || 0
                }
                if (w.is_active) activeWsId = w.id
            }
            _workspaces = ws
            refreshFiltered()
        }
        if (event.WindowsChanged) {
            var wl = {}
            var wins = event.WindowsChanged.windows
            for (var j = 0; j < wins.length; j++) {
                var w = wins[j]
                wl[w.id] = {
                    title: w.title || "",
                    app_id: w.app_id || "",
                    workspace_id: w.workspace_id || 0
                }
            }
            _windows = wl
            refreshFiltered()
        }
        if (event.WindowOpenedOrChanged) {
            var w = event.WindowOpenedOrChanged.window
            if (w) _windows[w.id] = {
                title: w.title || "", app_id: w.app_id || "", workspace_id: w.workspace_id || 0
            }
            refreshFiltered()
        }
        if (event.WindowClosed) {
            delete _windows[event.WindowClosed.id]
            refreshFiltered()
        }
        if (event.WorkspaceActivated) {
            activeWsId = event.WorkspaceActivated.id
            refreshDisplay()
        }
    }

    Rectangle {
        id: capsule
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: wsRow.implicitWidth + 18
        height: 28
        radius: 14
        color: "#313244"

        Behavior on width {
            SpringAnimation {
                spring: 3.0
                damping: 0.7
                mass: 1.0
            }
        }

        Row {
            id: wsRow
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: workspaceModule._displayList
                Text {
                    id: delegateItem
                    property bool isActive: String(modelData) === String(workspaceModule.activeWsId)
                    property bool _entered: isActive
                    property bool shouldFade: !isActive && workspaceModule._collapsing

                    states: [
                        State {
                            name: "entering"
                            when: !_entered && !isActive
                            PropertyChanges { target: delegateItem; opacity: 0; scale: 0.3 }
                        },
                        State {
                            name: "visible"
                            when: _entered && !shouldFade
                        },
                        State {
                            name: "fading"
                            when: _entered && shouldFade
                            PropertyChanges { target: delegateItem; opacity: 0 }
                        }
                    ]

                    transitions: [
                        Transition {
                            from: "entering"; to: "visible"
                            NumberAnimation { property: "opacity"; duration: 300; easing.type: Easing.InOutQuad }
                            NumberAnimation { property: "scale"; duration: 300; easing.type: Easing.OutQuad }
                        },
                        Transition {
                            from: "visible"; to: "fading"
                                NumberAnimation { property: "opacity"; duration: 300; easing.type: Easing.InOutQuad }
                            }
                    ]

                    Component.onCompleted: {
                        _entered = true
                    }

                    text: workspaceModule.iconForWs(modelData)
                    color: isActive ? "#cba6f7" : "#6c7086"
                    font.pixelSize: isActive ? 18 : 14
                    font.family: "JetBrainsMonoNL Nerd Font"
                }
            }
        }
    }

    property bool notifActive: false
    property bool notifFading: false
    property real notifOpacity: 0
    property bool notifCenterExpanded: false
    property var _notificationHistory: []

    Behavior on notifOpacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    NotificationServer {
        onNotification: function(notification) {
            var item = {
                summary: notification.summary || "",
                body: notification.body || "",
                appName: notification.appName || "",
                appIcon: notification.appIcon || "",
                time: new Date().toLocaleString(Qt.locale("en_US"), "HH:mm")
            }
            var newList = [item]
            for (var i = 0; i < workspaceModule._notificationHistory.length; i++)
                newList.push(workspaceModule._notificationHistory[i])
            workspaceModule._notificationHistory = newList.slice(0, 20)
            workspaceModule.refreshNotifIcon()
        }
    }

    property bool clearNotification: false

    onClearNotificationChanged: {
        if (clearNotification) {
            _notificationHistory = []
            refreshNotifIcon()
            clearNotification = false
            notifCenterExpanded = false
        }
    }

    function refreshNotifIcon() {
        notifOpacity = _notificationHistory.length > 0 ? 0.5 : 0
    }

    onNotifCenterExpandedChanged: {
        if (notifCenterExpanded) {
            notifOpacity = 1
        } else {
            refreshNotifIcon()
        }
    }

    onNotifActiveChanged: {
        if (notifActive) {
            notifOpacity = 1
            fadeTimer.restart()
        }
    }

    Timer {
        id: fadeTimer
        interval: 5000
        onTriggered: {
            workspaceModule.notifActive = false
            if (!workspaceModule.notifCenterExpanded) {
                workspaceModule.refreshNotifIcon()
            }
        }
    }

    onNotifOpacityChanged: {
        if (notifOpacity === 0 && notifFading) {
            notifFading = false
        }
    }
}
