pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System readings from scripts/metrics.py, one property per value. A new
// sample only notifies the properties whose value changed, so bindings on
// steady values (memory, disk, brightness) don't re-run every second.
Singleton {
    id: root
    property int cpu: 0
    // The bar's figure: the mean of the last three samples, updated every
    // third sample, so the bar redraws every 3 seconds rather than every second.
    property int cpuAverage: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    property int memoryPercent: 0
    property int diskPercent: 0
    property int brightness: -1
    property int temperature: -1
    property bool airplane: false
    property bool capsLock: false
    // Last minute of samples for the system panel graphs.
    property var history: ({cpu: [], memory: [], disk: [], temperature: []})
    property int lastSample: -1

    function apply(sample) {
        for (const key of ["cpu", "memoryUsed", "memoryTotal", "memoryPercent", "diskPercent",
                           "brightness", "temperature", "airplane", "capsLock"]) {
            if (key in sample) root[key] = sample[key];
        }
        // Brightness and airplane mode also arrive between samples; those
        // updates repeat the sample number and add nothing to the history.
        if (sample.sample === lastSample) return;
        lastSample = sample.sample;
        const keep = (list, value) => list.concat([value]).slice(-60);
        history = {
            cpu: keep(history.cpu, cpu), memory: keep(history.memory, memoryPercent),
            disk: keep(history.disk, diskPercent), temperature: keep(history.temperature, temperature)
        };
        if (sample.sample % 3 === 0) {
            const recent = history.cpu.slice(-3);
            cpuAverage = Math.round(recent.reduce((sum, value) => sum + value, 0) / recent.length);
        }
    }
    Process {
        id: collector
        command: ["python3", Quickshell.shellPath("scripts/metrics.py")]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.apply(JSON.parse(line)); }
                catch (error) { console.warn("Invalid metrics:", error); }
            }
        }
        onExited: restart.restart()
    }
    Timer { id: restart; interval: 5000; onTriggered: collector.running = true }
}
