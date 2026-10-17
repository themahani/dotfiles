pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var data: ({cpu: 0, cores: [], memoryUsed: 0, memoryTotal: 0, memoryPercent: 0,
        diskPercent: 0, diskUsed: "", diskTotal: "", brightness: -1, temperature: -1, airplane: false,
        capsLock: false})
    // Last minute of samples for the system panel graphs.
    property var history: ({cpu: [], memory: [], disk: [], temperature: []})
    function record(sample) {
        const keep = (list, value) => list.concat([value]).slice(-60);
        history = {
            cpu: keep(history.cpu, sample.cpu), memory: keep(history.memory, sample.memoryPercent),
            disk: keep(history.disk, sample.diskPercent), temperature: keep(history.temperature, sample.temperature)
        };
    }
    Process {
        id: collector
        command: ["python3", Quickshell.shellPath("scripts/metrics.py")]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.data = JSON.parse(line); root.record(root.data); }
                catch (error) { console.warn("Invalid metrics:", error); }
            }
        }
        onExited: restart.restart()
    }
    Timer { id: restart; interval: 5000; onTriggered: collector.running = true }
}
