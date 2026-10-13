pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool centerOpen: false
    property bool dnd: false
    property var popupIds: []
    property var deadlines: ({})
    readonly property var history: server.trackedNotifications.values.filter(item => !item.transient)
    readonly property var popups: server.trackedNotifications.values.filter(item => popupIds.includes(item.id))
    readonly property int count: history.length

    function hidePopup(id) {
        popupIds = popupIds.filter(value => value !== id);
        delete deadlines[id];
    }
    function clear() {
        history.slice().forEach(item => item.dismiss());
        centerOpen = false;
    }
    function receive(item) {
        item.tracked = true;
        item.closed.connect(() => root.hidePopup(item.id));
        const hints = item.hints;
        const synchronous = hints["x-canonical-private-synchronous"];
        if (synchronous) {
            server.trackedNotifications.values.filter(other => other.id !== item.id
                && other.hints["x-canonical-private-synchronous"] === synchronous).forEach(other => other.dismiss());
        }
        // Compatibility with progress notifications emitted by other desktop tools.
        if (synchronous && hints.value !== undefined) {
            Controls.showOsd(item.summary, item.appIcon || "󰕾", Number(hints.value));
            item.dismiss();
            return;
        }
        if (item.lastGeneration || (dnd && !hints.SWAYNC_BYPASS_DND)) {
            if (item.transient) item.expire();
            return;
        }
        popupIds = popupIds.filter(id => id !== item.id).concat([item.id]);
        const timeout = item.urgency === NotificationUrgency.Critical ? 0
            : item.expireTimeout >= 0 ? item.expireTimeout
            : item.urgency === NotificationUrgency.Low ? 3 : 6;
        if (timeout > 0) deadlines[item.id] = Date.now() + timeout * 1000;
    }
    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        persistenceSupported: true
        onNotification: item => root.receive(item)
    }
    Timer {
        interval: 250; running: root.popupIds.length > 0; repeat: true
        onTriggered: {
            const now = Date.now();
            root.popups.slice().forEach(item => {
                if (root.deadlines[item.id] && root.deadlines[item.id] <= now) {
                    root.hidePopup(item.id);
                    if (item.transient) item.expire();
                }
            });
        }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { root.centerOpen = !root.centerOpen; }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clear(); }
        function status(): string {
            return JSON.stringify({count: root.count, popups: root.popups.length, dnd: root.dnd, centerOpen: root.centerOpen});
        }
    }
}
