pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player the bar shows: the one picked in the media panel while it
// exists, else whichever is playing, else the first.
Singleton {
    id: root
    // playerctld re-exports whichever player is active; skip the duplicate.
    readonly property var players: Mpris.players.values.filter(item => !item.dbusName.includes("playerctld"))
    property var selected: null
    readonly property var player: players.includes(selected) ? selected
        : players.find(item => item.isPlaying) || players[0] || null
    readonly property string track: player ? [player.trackTitle, player.trackArtist].filter(Boolean).join(" · ") || player.identity : ""

    function icon(item) {
        const name = item ? (item.desktopEntry || item.identity || item.dbusName).toLowerCase() : "";
        if (/spotify|music|mpd|rhythmbox|elisa|amberol/.test(name)) return "music_note";
        if (/firefox|chrom|brave|zen|browser/.test(name)) return "public";
        if (/mpv|vlc|video|celluloid/.test(name)) return "movie";
        if (/kdeconnect|phone/.test(name)) return "smartphone";
        return "graphic_eq";
    }
    function format(seconds) {
        seconds = Math.max(0, Math.floor(seconds || 0));
        const minutes = Math.floor(seconds / 60);
        return minutes >= 60 ? Math.floor(minutes / 60) + ":" + String(minutes % 60).padStart(2, "0") + ":" + String(seconds % 60).padStart(2, "0")
            : minutes + ":" + String(seconds % 60).padStart(2, "0");
    }

    // MPRIS does not stream positions; Quickshell extrapolates the position
    // from the last report, and re-emitting positionChanged makes bindings
    // read it again. Only tick while something shows it: the media panel (in
    // the bar or on the lock screen) or the lock screen's player.
    readonly property bool positionShown: Panels.open === "media" || Lock.locked
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.player !== null && root.player.isPlaying && root.positionShown
        onTriggered: root.player.positionChanged()
    }
}
