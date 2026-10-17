import QtQuick
import "../components"
import "../services"
import "../theme"

// Status icons; the whole group opens the system panel and scrolls volume.
BarButton {
    id: root
    required property var screen
    readonly property var sink: Controls.sink
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted

    open: Panels.isOpen("system", screen)
    tooltip: "System"
    spacing: 10
    padding: 12
    onClicked: Panels.toggle("system", screen)
    onScrolled: direction => Controls.volume(direction > 0 ? "inc" : "dec", false)

    Icon { visible: Controls.idleInhibited; name: "coffee"; filled: true; size: 18; color: Theme.primary }
    Icon { name: Network.icon; filled: true; size: 18 }
    Icon { name: Network.bluetoothIcon; size: 18 }
    Icon {
        size: 18
        filled: true
        name: root.muted || root.volume === 0 ? "volume_off" : root.volume < 40 ? "volume_down" : "volume_up"
    }
    Row {
        id: battery
        visible: Power.hasBattery
        spacing: 2
        Icon { name: Power.icon; filled: true; size: 18; color: Power.low ? Theme.error : Theme.onSurfaceColor }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Power.level + "%"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Power.low ? Theme.error : Theme.onSurfaceColor
        }
        SequentialAnimation on opacity {
            running: Power.low
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 1500 }
            NumberAnimation { to: 1; duration: 1500 }
            onRunningChanged: if (!running) battery.opacity = 1
        }
    }
}
