import QtQuick
import "../components"
import "../services"
import "../theme"

BarButton {
    // The 3-second CPU average, so the bar doesn't redraw every second.
    tooltip: "CPU " + Metrics.cpuAverage + "% · RAM " + Metrics.memoryUsed.toFixed(1) + " / "
        + Metrics.memoryTotal.toFixed(1) + " GB\nClick to open btop"
    spacing: 12
    onClicked: Controls.btop()
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Icon { name: "memory"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        StyledText { text: Metrics.cpuAverage + "%"; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Icon { name: "memory_alt"; size: 18; color: Theme.tertiary; anchors.verticalCenter: parent.verticalCenter }
        StyledText { text: Metrics.memoryUsed.toFixed(1) + "G"; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
}
