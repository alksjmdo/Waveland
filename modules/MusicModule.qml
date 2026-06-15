import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Io

Item {
    id: musicModule
    implicitWidth: 0
    implicitHeight: 42
    Layout.alignment: Qt.AlignVCenter

    property bool isPlaying: false
    property bool _hasPlayer: false
    property bool _pauseExpired: false
    property bool _showControls: musicModule._hasPlayer && (musicModule.isPlaying || !musicModule._pauseExpired)
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackArtUrl: ""
    property var activePlayer: null

    property string _coverPrimary: "#cba6f7"
    property string _coverSecondary: "#b4befe"
    property string _coverTertiary: "#f5c2e7"

    property string _lastArtUrl: ""

    property bool lyricsMode: false
    property var _lrcLines: []
    property int _currentLyricIndex: -1
    property string _currentLyricText: ""
    property string _displayText: ""
    property var _lyricsCache: ({})
    property bool _lyricsLoading: false
    property string _lastFetchedKey: ""

    function toggleLyricsMode() {
        lyricsMode = !lyricsMode
        if (lyricsMode && trackTitle && _lrcLines.length === 0) {
            fetchLyrics(trackTitle, trackArtist)
        }
    }

    function exitLyricsMode() {
        lyricsMode = false
    }

    function parseLrc(lrcText) {
        var lines = lrcText.split("\n")
        var result = []
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(/\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/)
            if (match) {
                var min = parseInt(match[1], 10)
                var sec = parseInt(match[2], 10)
                var cs = parseInt(match[3], 10)
                var ms = min * 60000 + sec * 1000 + (match[3].length === 2 ? cs * 10 : cs)
                var text = match[4].trim()
                if (text.length > 0) {
                    result.push({timeMs: ms, text: text})
                }
            }
        }
        result.sort(function(a, b) { return a.timeMs - b.timeMs })
        return result
    }

    function updateDisplayText() {
        if (_currentLyricIndex >= 0 && _currentLyricIndex < _lrcLines.length) {
            _currentLyricText = _lrcLines[_currentLyricIndex].text
            _displayText = _currentLyricText
        } else if (trackTitle) {
            _displayText = trackTitle + " - " + trackArtist
            _currentLyricText = ""
        } else {
            _displayText = ""
            _currentLyricText = ""
        }
    }

    function fetchLyrics(title, artist) {
        if (_lyricsLoading) return
        var cacheKey = title + "||" + artist
        if (_lyricsCache[cacheKey]) {
            _lrcLines = _lyricsCache[cacheKey]
            _currentLyricIndex = -1
            updateDisplayText()
            return
        }
        _lyricsLoading = true
        lrcProcess.command = ["curl", "-G", "https://lrclib.net/api/get",
            "--data-urlencode", "track_name=" + title,
            "--data-urlencode", "artist_name=" + artist]
        lrcProcess.running = true
    }

    onIsPlayingChanged: {
        if (!isPlaying && lyricsMode) {
            exitLyricsMode()
        }
    }

    function refreshState() {
        var players = Mpris.players.values
        var playingFound = false
        var anyPlayerFound = players.length > 0
        var newTitle = ""
        var newArtist = ""
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p && p.isPlaying) {
                if (!playingFound) {
                    playingFound = true
                    newTitle = p.trackTitle || ""
                    newArtist = p.trackArtist || ""
                    isPlaying = true
                    activePlayer = p
                    trackTitle = newTitle
                    trackArtist = newArtist
                    trackArtUrl = p.trackArtUrl || ""
                    generateColors()
                }
            }
        }
        if (playingFound) {
            _hasPlayer = true
            _pauseExpired = false
            _pauseTimer.stop()
            if (newTitle) {
                var key = newTitle + "||" + newArtist
                if (_lastFetchedKey !== key) {
                    _lastFetchedKey = key
                    _lrcLines = []
                    _currentLyricIndex = -1
                    updateDisplayText()
                    fetchLyrics(newTitle, newArtist)
                }
            }
        } else if (anyPlayerFound) {
            isPlaying = false
            if (!_hasPlayer) {
                var pp = players[0]
                activePlayer = pp
                trackTitle = pp.trackTitle || ""
                trackArtist = pp.trackArtist || ""
                trackArtUrl = pp.trackArtUrl || ""
                generateColors()
            }
            _hasPlayer = true
            if (!_pauseExpired && !_pauseTimer.running) _pauseTimer.restart()
        } else {
            isPlaying = false
            activePlayer = null
            trackTitle = ""
            trackArtist = ""
            trackArtUrl = ""
            _pauseExpired = false
            _pauseTimer.stop()
        }
    }

    Component.onCompleted: refreshState()

    function generateColors() {
        if (trackArtUrl === "" || trackArtUrl === _lastArtUrl) return
        _lastArtUrl = trackArtUrl
        var url = trackArtUrl
        var cmd = "mkdir -p /tmp/waveland_art && "
        if (url.indexOf("file://") === 0) {
            cmd += "cp " + url.substring(7) + " /tmp/waveland_art/cover 2>/dev/null"
        } else {
            cmd += "curl -sLo /tmp/waveland_art/cover '" + url + "' 2>/dev/null"
        }
        cmd += " && matugen image /tmp/waveland_art/cover --prefer saturation -j hex 2>/dev/null"
        matugenProc.exec(["sh", "-c", cmd])
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: musicModule.refreshState()
    }

    Process {
        id: matugenProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim()
                if (!raw) return
                try {
                    var data = JSON.parse(raw)
                    if (data && data.colors && data.palettes) {
                        var sc = data.colors.source_color && data.colors.source_color.dark ? data.colors.source_color.dark.color : ""
                        var pal = data.palettes.primary
                        var p80 = pal && pal["80"] ? pal["80"].color : ""
                        var p60 = pal && pal["60"] ? pal["60"].color : ""
                        if (sc) musicModule._coverPrimary = sc
                        if (p80) musicModule._coverSecondary = p80
                        if (p60) musicModule._coverTertiary = p60
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        id: _pauseTimer
        interval: 300000
        onTriggered: musicModule._pauseExpired = true
    }

    Process {
        id: lrcProcess
        command: ["curl", "-G", "https://lrclib.net/api/get"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                musicModule._lyricsLoading = false
                var raw = text
                try {
                    var resp = JSON.parse(raw)
                    if (resp.syncedLyrics) {
                        var lines = musicModule.parseLrc(resp.syncedLyrics)
                        var cacheKey = musicModule._lastFetchedKey
                        var keys = Object.keys(musicModule._lyricsCache)
                        if (keys.length >= 20) {
                            delete musicModule._lyricsCache[keys[0]]
                        }
                        musicModule._lyricsCache[cacheKey] = lines
                        musicModule._lrcLines = lines
                        musicModule._currentLyricIndex = -1
                        musicModule.updateDisplayText()
                    } else if (resp.plainLyrics) {
                        musicModule._lrcLines = [{timeMs: 0, text: resp.plainLyrics}]
                        musicModule._currentLyricIndex = -1
                        musicModule.updateDisplayText()
                    } else {
                        musicModule._lrcLines = []
                        musicModule.updateDisplayText()
                    }
                } catch(e) {
                    musicModule._lrcLines = []
                    musicModule.updateDisplayText()
                }
            }
        }
    }

    Timer {
        id: lyricTimer
        interval: 200
        running: musicModule.lyricsMode && musicModule.isPlaying && musicModule._lrcLines.length > 0
        repeat: true
        onTriggered: {
            if (!musicModule.activePlayer) return
            musicModule.activePlayer.positionChanged()
            var pos = musicModule.activePlayer.position * 1000
            var idx = musicModule._lrcLines.length - 1
            for (var i = 0; i < musicModule._lrcLines.length; i++) {
                if (musicModule._lrcLines[i].timeMs > pos) {
                    idx = Math.max(0, i - 1)
                    break
                }
            }
            if (idx !== musicModule._currentLyricIndex) {
                musicModule._currentLyricIndex = idx
                musicModule.updateDisplayText()
            }
        }
    }
}
