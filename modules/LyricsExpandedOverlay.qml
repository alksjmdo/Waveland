import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var musicModule

    property real _opacity: musicModule.lyricsExpanded ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    opacity: _opacity
    visible: _opacity > 0.01

    property real _lyricOpacity: 1
    Behavior on _lyricOpacity {
        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
    }

    property real _lyricY: 0
    Behavior on _lyricY {
        NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }

    property bool _lyricAnimating: false
    property string _oldPrevLine: ""
    property string _oldCurrLine: ""
    property string _oldNextLine: ""

    Connections {
        target: musicModule
        function on_CurrentLyricIndexChanged() {
            if (!musicModule.lyricsExpanded) return
            _oldPrevLine = prevLine.text
            _oldCurrLine = currentLine.text
            _oldNextLine = nextLine.text
            _lyricAnimating = true
            _lyricOpacity = 0
            _lyricY = -40
            lyricSlideTimer.restart()
        }
    }

    Timer {
        id: lyricSlideTimer
        interval: 180
        onTriggered: {
            _lyricY = 40
            lyricShowTimer.restart()
        }
    }

    Timer {
        id: lyricShowTimer
        interval: 30
        onTriggered: {
            _lyricY = 0
            _lyricOpacity = 1
            _lyricAnimating = false
        }
    }

    Row {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            width: 340
            height: 340
            clip: true
            radius: 20
            color: musicModule._coverTertiary
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color {
                ColorAnimation { duration: 500 }
            }

            IconImage {
                anchors.centerIn: parent
                width: 272
                height: 272
                source: musicModule.trackArtUrl !== "" ? musicModule.trackArtUrl : ""
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: musicModule.toggleLyricsExpanded()
            }
        }

        Item {
            width: parent.width - 340
            height: parent.height

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.right: parent.right
                anchors.rightMargin: 28
                anchors.top: parent.top
                anchors.topMargin: 24

                Text {
                    id: expandedTitle
                    text: musicModule.trackTitle || ""
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 20
                    font.bold: true
                    color: musicModule._coverText
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: musicModule.trackArtist || ""
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 14
                    color: musicModule._coverSecondary
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }
                    width: parent.width
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.right: parent.right
                anchors.rightMargin: 28
                anchors.top: parent.top
                anchors.topMargin: 80
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 74
                radius: 12
                color: "#313244"

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: prevLine
                        opacity: root._lyricOpacity
                        transform: Translate { y: root._lyricY }
                        text: root._lyricAnimating ? root._oldPrevLine : (musicModule._currentLyricIndex > 0 && musicModule._currentLyricIndex <= musicModule._lrcLines.length
                            ? musicModule._lrcLines[musicModule._currentLyricIndex - 1].text : "")
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 14
                        color: musicModule._coverSecondary
                        Behavior on color {
                            ColorAnimation { duration: 500 }
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: text !== ""
                    }

                    Text {
                        id: currentLine
                        opacity: root._lyricOpacity
                        transform: Translate { y: root._lyricY }
                        text: root._lyricAnimating ? root._oldCurrLine : (musicModule._currentLyricIndex >= 0 && musicModule._currentLyricIndex < musicModule._lrcLines.length
                            ? musicModule._lrcLines[musicModule._currentLyricIndex].text : musicModule.trackTitle || "")
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 16
                        font.bold: true
                        color: musicModule._coverText
                        Behavior on color {
                            ColorAnimation { duration: 500 }
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        id: nextLine
                        opacity: root._lyricOpacity
                        transform: Translate { y: root._lyricY }
                        text: root._lyricAnimating ? root._oldNextLine : (musicModule._currentLyricIndex >= 0 && musicModule._currentLyricIndex + 1 < musicModule._lrcLines.length
                            ? musicModule._lrcLines[musicModule._currentLyricIndex + 1].text : "")
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 14
                        color: musicModule._coverSecondary
                        Behavior on color {
                            ColorAnimation { duration: 500 }
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: text !== ""
                    }
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.leftMargin: 340
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                cursorShape: Qt.PointingHandCursor
                onClicked: musicModule.toggleLyricsExpanded()
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                spacing: 14

                Text {
                    text: "\uF048"
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 16
                    color: musicModule._coverSecondary
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (musicModule.activePlayer && musicModule.activePlayer.canGoPrevious)
                                musicModule.activePlayer.previous()
                        }
                    }
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: musicModule._coverTertiary
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }

                    Text {
                        text: musicModule.isPlaying ? "\uF04D" : "\uF04B"
                        font.family: "JetBrainsMonoNL Nerd Font"
                        font.pixelSize: 16
                        color: musicModule._coverPrimary
                        Behavior on color {
                            ColorAnimation { duration: 500 }
                        }
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (musicModule.activePlayer && musicModule.activePlayer.canTogglePlaying)
                                musicModule.activePlayer.togglePlaying()
                        }
                    }
                }

                Text {
                    text: "\uF051"
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 16
                    color: musicModule._coverSecondary
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (musicModule.activePlayer && musicModule.activePlayer.canGoNext)
                                musicModule.activePlayer.next()
                        }
                    }
                }
            }
        }
    }
}
