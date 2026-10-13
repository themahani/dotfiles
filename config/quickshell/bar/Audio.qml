import QtQuick
import "../components"
import "../services"
import "../theme"

Chip {
    property bool microphone: false
    readonly property var node: microphone ? Controls.source : Controls.sink
    readonly property bool muted: node && node.audio ? node.audio.muted : true
    readonly property int volume: node && node.audio ? Math.round(node.audio.volume * 100) : 0
    readonly property bool bluetooth: node && node.name.includes("bluez")
    readonly property string deviceIcon: {
        if (!node) return "󰖁";
        const description = (node.description + " " + (node.properties["device.form-factor"] || "")).toLowerCase();
        if (/headphone|headset|hands-free/.test(description)) return "";
        if (/phone|portable/.test(description)) return "";
        if (/car/.test(description)) return "";
        return ["", "", "󰕾", ""][Math.min(3, Math.floor(volume / 25))];
    }
    foreground: muted ? Theme.red : bluetooth ? Theme.pink : Theme.sapphire
    text: muted ? (microphone ? "" : "󰖁") : (microphone ? "" : deviceIcon + (bluetooth ? " 󰂰" : "")) + " " + volume + "%"
    tooltip: (node ? node.description : "No audio device") + " | " + volume + "%"
    onClicked: button => {
        if (button === Qt.RightButton) Controls.run(["pavucontrol", "-t", microphone ? "4" : "3"]);
        else Controls.volume("toggle", microphone);
    }
    onScrolled: direction => Controls.volume(direction > 0 ? "inc" : "dec", microphone)
}
