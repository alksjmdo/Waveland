import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: notifServer
    visible: false

    property bool notifActive: false
    property bool notifFading: false
    property real notifOpacity: 0
    property bool notifCenterExpanded: false
    property var _notificationHistory: []
    property bool clearNotification: false

    Behavior on notifOpacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    NotificationServer {
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        onNotification: function(notification) {
            var item = {
                summary: notification.summary || "",
                body: notification.body || "",
                appName: notification.appName || "",
                appIcon: notification.appIcon || "",
                time: new Date().toLocaleString(Qt.locale("en_US"), "HH:mm")
            }
            var newList = [item]
            for (var i = 0; i < notifServer._notificationHistory.length; i++)
                newList.push(notifServer._notificationHistory[i])
            notifServer._notificationHistory = newList.slice(0, 20)
            notifServer.notifActive = true
            notifServer.refreshNotifIcon()
        }
    }

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
            notifServer.notifActive = false
            if (!notifServer.notifCenterExpanded) {
                notifServer.refreshNotifIcon()
            }
        }
    }

    onNotifOpacityChanged: {
        if (notifOpacity === 0 && notifFading) {
            notifFading = false
        }
    }
}
