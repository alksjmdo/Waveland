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
    property bool overviewExpanded: false

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

    function refreshDisplay() {
        _displayList = activeWsId >= 0 ? [activeWsId] : []
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
        var name = ws.name
        if (name && _iconMap[name]) return _iconMap[name]
        if (!hasWindows(wsId)) return _iconMap["empty"]
        return _iconMap["default"]
    }

    function getSortedWsList() {
        var ids = Object.keys(_workspaces)
        ids.sort(function(a, b) {
            return (_workspaces[a] ? _workspaces[a].idx : 0) -
                   (_workspaces[b] ? _workspaces[b].idx : 0)
        })
        return ids
    }

    function windowsOfWs(wsId) {
        var wins = []
        var wids = Object.keys(_windows)
        for (var i = 0; i < wids.length; i++) {
            if (_windows[wids[i]].workspace_id == wsId) {
                wins.push({id: wids[i], title: _windows[wids[i]].title, app_id: _windows[wids[i]].app_id})
            }
        }
        return wins
    }

    function niriAction(msg) {
        var parts = ["niri", "msg", "action"]
        var args = msg.split(" ")
        for (var i = 0; i < args.length; i++)
            parts.push(args[i])
        niriProc.exec(parts)
    }

    property var _iconPaths: ({})

    function getIconPath(appId) {
        return _iconPaths[appId] || ""
    }

    function resolveIconPath(appId) {
        if (!appId) return
        if (_iconPaths[appId] !== undefined) return
        var entry = DesktopEntries.heuristicLookup(appId)
        if (!entry || !entry.icon) {
            var c1 = {}
            for (var k in _iconPaths) c1[k] = _iconPaths[k]
            c1[appId] = ""
            _iconPaths = c1
            return
        }
        iconFinder.appId = appId
        iconFinder.exec(["sh", "-c", "python3 -c \"import glob,sys;f=glob.glob('/usr/share/icons/hicolor/*/apps/'+sys.argv[1]+'.[ps][nv][gg]');print(f[0]if f else'')\" " + entry.icon])
    }

    Process {
        id: iconFinder
        command: ["sh", "-c", ""]
        running: false

        property string appId: ""

        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim()
                var newPaths = {}
                for (var key in workspaceModule._iconPaths)
                    newPaths[key] = workspaceModule._iconPaths[key]
                if (path) {
                    newPaths[iconFinder.appId] = "file://" + path
                } else {
                    newPaths[iconFinder.appId] = ""
                }
                workspaceModule._iconPaths = newPaths
            }
        }
    }

    property var _appIconMap: ({
        "firefox": "\uF269",
        "chromium": "\uF268",
        "google-chrome": "\uF268",
        "code-oss": "\uF121",
        "com.visualstudio.code": "\uF121",
        "alacritty": "\uF120",
        "kitty": "\uF120",
        "org.wezfurlong.wezterm": "\uF120",
        "utilities-terminal": "\uF120",
        "org.telegram.desktop": "\uF2C6",
        "spotify-client": "\uF1BC",
        "steam": "\uF1B6",
        "thunderbird": "\uF0E0",
        "org.gnome.Nautilus": "\uF07C",
        "vlc": "\uF008",
        "discord": "\uF392",
        "org.gimp.GIMP": "\uF03E",
        "libreoffice-startcenter": "\uF15B"
    })

    function appIconFor(appId) {
        if (!appId) return "\uF2D0"
        var entry = DesktopEntries.heuristicLookup(appId)
        var iconKey = ""
        if (entry) {
            iconKey = entry.icon || ""
            if (_appIconMap[iconKey]) return _appIconMap[iconKey]
            if (entry.name && _appIconMap[entry.name]) return _appIconMap[entry.name]
        }
        var lower = appId.toLowerCase()
        if (_appIconMap[lower]) return _appIconMap[lower]
        if (lower.indexOf("firefox") >= 0) return "\uF269"
        if (lower.indexOf("chrome") >= 0 || lower.indexOf("chromium") >= 0) return "\uF268"
        if (lower.indexOf("code") >= 0 || lower.indexOf("codium") >= 0) return "\uF121"
        if (lower.indexOf("terminal") >= 0 || lower.indexOf("kitty") >= 0 || lower.indexOf("alacritty") >= 0) return "\uF120"
        if (lower.indexOf("telegram") >= 0) return "\uF2C6"
        if (lower.indexOf("spotify") >= 0) return "\uF1BC"
        if (lower.indexOf("steam") >= 0) return "\uF1B6"
        return "\uF2D0"
    }

    Process {
        id: niriProc
        command: ["niri", "msg", "action"]
        running: false
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
        _filteredList = ids
        refreshDisplay()
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

    function handleEvent(event) {
        if (event.WorkspacesChanged) {
            var ws = {}
            var wss = event.WorkspacesChanged.workspaces
            for (var i = 0; i < wss.length; i++) {
                var w = wss[i]
                if (w && w.id !== undefined) ws[w.id] = {
                    name: w.name || "",
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
            if (w) {
                var nw = {}
                for (var key in _windows) nw[key] = _windows[key]
                nw[w.id] = {
                    title: w.title || "", app_id: w.app_id || "", workspace_id: w.workspace_id || 0
                }
                _windows = nw
            }
            refreshFiltered()
        }
        if (event.WindowClosed) {
            var replaced = {}
            for (var k in _windows) {
                if (String(k) !== String(event.WindowClosed.id))
                    replaced[k] = _windows[k]
            }
            _windows = replaced
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
            y: (capsule.height - height) / 2
            x: (capsule.width - width) / 2
            spacing: 6

            Behavior on x {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            Repeater {
                model: workspaceModule._displayList
                Text {
                    id: delegateText
                    property bool isActive: String(modelData) === String(workspaceModule.activeWsId)

                    text: workspaceModule.iconForWs(modelData)
                    color: isActive ? "#cba6f7" : "#6c7086"
                    font.pixelSize: 18
                    font.family: "JetBrainsMonoNL Nerd Font"
                    opacity: 1
                    scale: 1

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: workspaceModule.overviewExpanded = !workspaceModule.overviewExpanded
                    }
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
            workspaceModule.notifActive = true
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
