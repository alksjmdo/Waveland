import QtQuick

Item {
    id: ctl
    visible: false

    property bool active: false
    property bool contentVisible: false
    property bool pctVisible: false

    property real showDelay: 600
    property real hideDelay: 250
    property real autoHideDelay: 3000
    property bool hasAutoHide: true
    property bool trackHoverSource: true
    property bool setPctWithContent: false

    property bool _ready: true
    property bool _shownByHover: false

    onContentVisibleChanged: {
        if (contentVisible && setPctWithContent) pctVisible = true
    }

    function show() {
        if (!active) {
            contentVisible = false
            active = true
            showTimer.restart()
        }
        if (hasAutoHide) autoHideTimer.restart()
    }

    function showFromEvent() {
        _shownByHover = false
        show()
    }

    function hide() {
        pctVisible = false
        contentVisible = false
        hideActiveTimer.restart()
    }

    function onPillHovered(hovered) {
        if (!trackHoverSource) {
            if (hovered) show()
            else hide()
            return
        }
        if (hovered) {
            _shownByHover = true
            show()
            if (contentVisible) pctVisible = true
        } else if (_shownByHover) {
            _shownByHover = false
            hide()
        }
    }

    Timer {
        id: showTimer
        interval: ctl.showDelay
        onTriggered: {
            ctl.contentVisible = true
            if (ctl._shownByHover && !ctl.setPctWithContent) ctl.pctVisible = true
        }
    }

    Timer {
        id: hideActiveTimer
        interval: ctl.hideDelay
        onTriggered: ctl.active = false
    }

    Timer {
        id: autoHideTimer
        interval: ctl.autoHideDelay
        running: ctl.active && ctl.hasAutoHide
        onTriggered: {
            if (ctl._shownByHover) {
                autoHideTimer.restart()
            } else {
                ctl.contentVisible = false
                hideActiveTimer.restart()
            }
        }
    }
}
