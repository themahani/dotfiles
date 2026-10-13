import QtQuick
import Quickshell.Services.Mpris
import "../components"
import "../services"
import "../theme"

Chip {
    readonly property var player: Mpris.players.values.find(item => item.isPlaying) || Mpris.players.values[0] || null
    readonly property string track: player ? [player.trackArtist, player.trackTitle].filter(Boolean).join(" — ") || player.identity : ""
    readonly property var icons: ({chromium: "", firefox: "", kdeconnect: "", mopidy: "", mpv: "󰐹", spotify: "", vlc: "󰕼"})
    visible: player !== null
    foreground: Theme.lavender
    italic: player !== null && !player.isPlaying
    text: {
        if (!player) return "";
        const name = Object.keys(icons).find(key => player.dbusName.toLowerCase().includes(key));
        return (player.isPlaying ? icons[name] || "" : "󰐎") + " " + (track.length > 30 ? track.slice(0, 29) + "…" : track);
    }
    tooltip: track + "\nLeft: previous · Middle: play/pause · Right: next"
    onClicked: button => {
        if (!player) return;
        if (button === Qt.LeftButton && player.canGoPrevious) player.previous();
        if (button === Qt.MiddleButton && player.canTogglePlaying) player.togglePlaying();
        if (button === Qt.RightButton && player.canGoNext) player.next();
    }
    onScrolled: direction => Controls.volume(direction > 0 ? "inc" : "dec", false)
}
