pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Singleton {
    id: root
    property bool dnd: false
    property var popupIds: []
    property var deadlines: ({})
    property bool paused: false         // hovering popups keeps them on screen
    property var times: ({})            // arrival time by id; the protocol has none
    readonly property var history: server.trackedNotifications.values.filter(item => !item.transient)
    readonly property var popups: server.trackedNotifications.values.filter(item => popupIds.includes(item.id))
    readonly property int count: history.length
    readonly property int historyLimit: 100
    // Discord plays its own message sounds, through "Chromium" streams, so
    // hiding its popups doesn't silence it. Its calls use a separate
    // "WEBRTC VoiceEngine" stream that stays audible.
    readonly property var appSounds: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioOutStream && node.name === "Chromium")

    function hidePopup(id) {
        popupIds = popupIds.filter(value => value !== id);
        delete deadlines[id];
    }
    function clear() {
        history.slice().forEach(item => item.dismiss());
        if (Panels.open === "clock") Panels.close();
    }
    function since(item) {
        const minutes = Math.floor((Date.now() - (times[item.id] || Date.now())) / 60000);
        return minutes < 1 ? "now" : minutes < 60 ? minutes + "m" : minutes < 1440 ? Math.floor(minutes / 60) + "h" : Math.floor(minutes / 1440) + "d";
    }
    // Runs the default action, then raises the sender's window, or launches
    // the app when it has none. The action alone shows nothing for an app
    // closed to the tray, like Discord. Returns false when nothing happened.
    function activate(item) {
        const action = item.actions.find(action => action.identifier === "default");
        const entry = DesktopEntries.heuristicLookup(item.desktopEntry || item.appName);
        if (action) action.invoke();
        if (!entry) return action !== undefined;
        const appIds = [entry.id, entry.startupClass].filter(id => id).map(id => id.toLowerCase());
        const window = ToplevelManager.toplevels.values.find(toplevel => appIds.includes(toplevel.appId.toLowerCase()));
        if (window) window.activate();
        else entry.execute();
        return true;
    }
    function receive(item) {
        item.tracked = true;
        const id = item.id;
        times = Object.assign({}, times, {[id]: Date.now()});
        item.closed.connect(() => {
            root.hidePopup(id);
            const rest = Object.assign({}, root.times);
            delete rest[id];
            root.times = rest;
        });
        // Keep the newest notifications; dismiss the oldest past the limit. The
        // new one isn't in the tracked list yet.
        const older = server.trackedNotifications.values.filter(other => !other.transient && other.id !== id);
        older.slice(0, Math.max(0, older.length - (historyLimit - 1))).forEach(other => other.dismiss());
        const hints = item.hints;
        const synchronous = hints["x-canonical-private-synchronous"];
        if (synchronous) {
            server.trackedNotifications.values.filter(other => other.id !== item.id
                && other.hints["x-canonical-private-synchronous"] === synchronous).forEach(other => other.dismiss());
        }
        // Only critical notifications pop up during Do not disturb. Apps can't
        // opt out of it with a hint, or draw the volume OSD: the shell shows
        // that itself, from the volume and brightness IPC.
        if (item.lastGeneration || (dnd && item.urgency !== NotificationUrgency.Critical)) {
            if (item.transient) item.expire();
            return;
        }
        // Every popup hides, even one sent with "never expire" (0); the
        // notification stays in history. expireTimeout is documented in
        // seconds, but Quickshell 0.3.2 passes the protocol's milliseconds.
        popupIds = popupIds.filter(id => id !== item.id).concat([item.id]);
        const timeout = item.expireTimeout > 0 ? item.expireTimeout
            : item.urgency === NotificationUrgency.Critical ? 12000
            : item.urgency === NotificationUrgency.Low ? 3000 : 6000;
        deadlines[item.id] = Date.now() + timeout;
    }
    // Both load on first use; start them now so the first click finds the app.
    Component.onCompleted: { DesktopEntries.applications; ToplevelManager.toplevels; }
    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        persistenceSupported: true
        onNotification: item => root.receive(item)
    }
    PwObjectTracker { objects: root.appSounds }
    Variants {
        model: root.appSounds
        Binding {
            required property PwNode modelData
            target: modelData?.audio ?? null
            property: "muted"
            value: true
            when: root.dnd && !!modelData?.ready && modelData.properties["application.process.binary"] === "Discord"
        }
    }
    Timer {
        interval: 250; running: root.popupIds.length > 0; repeat: true
        onTriggered: {
            const now = Date.now();
            if (root.paused) {
                Object.keys(root.deadlines).forEach(id => root.deadlines[id] += interval);
                return;
            }
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
        function toggle(): void { Panels.toggle("clock", null); }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clear(); }
        function status(): string {
            return JSON.stringify({count: root.count, popups: root.popups.length, dnd: root.dnd, centerOpen: Panels.open === "clock"});
        }
    }
}
