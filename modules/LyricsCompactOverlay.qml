import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var musicModule
    property bool hovered: false

    property real _opacity: musicModule.lyricsMode && !musicModule.lyricsExpanded ? 1 : 0
    Behavior on _opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    opacity: _opacity
    visible: _opacity > 0.01
    implicitWidth: _opacity > 0.01 ? (lyricsNoteIcon.implicitWidth + 8 + lyricDisplayText.implicitWidth + 8 + lyricsControlsWrapper.implicitWidth) : 0

    Text {
        id: lyricsNoteIcon
        text: "󰽰"
        font.family: "JetBrainsMonoNL Nerd Font"
        font.pixelSize: 20
        color: musicModule._coverSecondary
        Behavior on color {
            ColorAnimation { duration: 500 }
        }
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: musicModule.toggleLyricsMode()
        }
    }

    Item {
        id: lyricsControlsWrapper
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: controlsContent.implicitWidth
        height: 30

        Row {
            id: controlsContent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Item {
                width: root.hovered ? prevBtn.implicitWidth : 0
                height: 30
                clip: true
                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                Text {
                    id: prevBtn
                    text: "\uF048"
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 16
                    color: musicModule._coverSecondary
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.hovered ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (musicModule.activePlayer && musicModule.activePlayer.canGoPrevious)
                                musicModule.activePlayer.previous()
                        }
                    }
                }
            }

            Item {
                width: root.hovered ? playBtn.implicitWidth : 0
                height: 30
                clip: true
                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                Text {
                    id: playBtn
                    text: musicModule.isPlaying ? "\uF04D" : "\uF04B"
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 16
                    color: musicModule._coverPrimary
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.hovered ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
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
            }

            Item {
                width: root.hovered ? nextBtn.implicitWidth : 0
                height: 30
                clip: true
                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                Text {
                    id: nextBtn
                    text: "\uF051"
                    font.family: "JetBrainsMonoNL Nerd Font"
                    font.pixelSize: 16
                    color: musicModule._coverSecondary
                    Behavior on color {
                        ColorAnimation { duration: 500 }
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.hovered ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

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

            Rectangle {
                width: 30
                height: 30
                radius: 12
                clip: true
                color: "#313244"
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: musicModule.trackArtUrl !== "" ? musicModule.trackArtUrl : ""
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: musicModule.toggleLyricsExpanded()
                }
            }
        }
    }

    Text {
        id: lyricDisplayText
        anchors.left: lyricsNoteIcon.right
        anchors.leftMargin: 8
        anchors.right: lyricsControlsWrapper.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: musicModule._displayText
        color: musicModule._coverText
        Behavior on color {
            ColorAnimation { duration: 500 }
        }
        font.pixelSize: 14
        font.family: "JetBrainsMonoNL Nerd Font"
    }
}
