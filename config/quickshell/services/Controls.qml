pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    property bool idleInhibited: false
    property string osdLabel: ""
    property string osdIcon: ""          // Material Symbols name
    property real osdValue: 0
    property bool osdVisible: false
    property int brightnessValue: Metrics.brightness
    property int pendingBrightness: -1
    property int appliedBrightness: -1

    PwObjectTracker { objects: [root.sink, root.source].filter(node => node !== null) }
    Timer { id: hideOsd; interval: 1500; onTriggered: root.osdVisible = false }

    function showOsd(label, icon, value) {
        osdLabel = label; osdIcon = icon; osdValue = value;
        osdVisible = true;
        hideOsd.restart();
    }
    function run(arguments) { Quickshell.execDetached(arguments); }
    function hyprScript(name, argument) {
        const home = Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config";
        run(argument ? [home + "/hypr/scripts/" + name, argument] : [home + "/hypr/scripts/" + name]);
    }
    // Delay so the click and settling mouse don't immediately re-enable DPMS
    // (mouse_move_enables_dpms/key_press_enables_dpms wake the outputs).
    // Idle timers keep running, so hypridle still locks/suspends unless inhibited.
    function screenOff() {
        run(["sh", "-c", "sleep 1 && hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'"]);
    }
    function setAirplane(enabled) { run(["rfkill", enabled ? "block" : "unblock", "all"]); }
    function btop() { run(["kitty", "-e", "btop"]); }
    function volume(action, microphone) {
        const node = microphone ? source : sink;
        if (!node || !node.audio) return;
        if (action === "toggle") node.audio.muted = !node.audio.muted;
        else if (node.audio.muted) node.audio.muted = false;
        else node.audio.volume = Math.max(0, Math.min(microphone ? 1 : 1.5,
            node.audio.volume + (action === "inc" ? 0.05 : -0.05)));
        showOsd(microphone ? "Microphone" : "Volume", microphone ? (node.audio.muted ? "mic_off" : "mic") : (node.audio.muted ? "volume_off" : "volume_up"),
            node.audio.muted ? 0 : Math.round(node.audio.volume * 100));
        if (!microphone && !node.audio.muted) hyprScript("Sounds.sh", "--volume");
    }
    function setVolume(value) {
        if (sink && sink.audio) { sink.audio.volume = value / 100; sink.audio.muted = false; }
        showOsd("Volume", "volume_up", value);
    }
    function brightness(action) {
        const current = brightnessValue;
        if (current < 0) return;
        setBrightness(Math.max(5, Math.min(100, current + (action === "inc" ? 10 : -10))));
    }
    function setBrightness(value) {
        brightnessValue = Math.max(5, Math.min(100, Math.round(value)));
        pendingBrightness = brightnessValue;
        applyBrightness();
    }
    function applyBrightness() {
        if (brightnessProcess.running || pendingBrightness < 0) return;
        appliedBrightness = pendingBrightness;
        pendingBrightness = -1;
        brightnessProcess.command = ["brightnessctl", "set", appliedBrightness + "%"];
        brightnessProcess.running = true;
    }
    Connections {
        target: Metrics
        function onBrightnessChanged() {
            if (!brightnessProcess.running && root.pendingBrightness < 0)
                root.brightnessValue = Metrics.brightness;
        }
    }
    Process {
        id: brightnessProcess
        onExited: (code, status) => {
            if (code === 0) root.showOsd("Brightness", "brightness_6", root.appliedBrightness);
            else {
                console.warn("brightnessctl failed with exit code", code);
                root.brightnessValue = Metrics.brightness;
            }
            root.applyBrightness();
        }
    }
    IpcHandler {
        target: "controls"
        function volume(action: string): void { root.volume(action, false); }
        function microphone(action: string): void { root.volume(action, true); }
        function brightness(action: string): void { root.brightness(action); }
        function screenOff(): void { root.screenOff(); }
        function toggleIdleInhibit(): void { root.idleInhibited = !root.idleInhibited; }
        function status(): string {
            return JSON.stringify({osdVisible: root.osdVisible, label: root.osdLabel, value: root.osdValue});
        }
    }
}
