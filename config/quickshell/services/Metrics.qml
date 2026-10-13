pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var data: ({cpu: 0, cores: [], memoryUsed: 0, memoryTotal: 0, memoryPercent: 0,
        diskPercent: 0, diskUsed: "", diskTotal: "", brightness: -1, keyboard: "", keyboardName: "", interfaces: {}, profileDrivers: {}})
    Process {
        id: collector
        command: ["python3", Quickshell.shellPath("scripts/metrics.py")]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.data = JSON.parse(line); }
                catch (error) { console.warn("Invalid metrics:", error); }
            }
        }
        onExited: restart.restart()
    }
    Timer { id: restart; interval: 5000; onTriggered: collector.running = true }
}
