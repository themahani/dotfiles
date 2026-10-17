import QtQuick
import "../components"
import "../services"
import "../theme"

BarButton {
    visible: Metrics.data.keyboard !== ""
    tooltip: Metrics.data.keyboard + "\nClick to switch layout"
    onClicked: { if (Metrics.data.keyboardName) Controls.run(["hyprctl", "switchxkblayout", Metrics.data.keyboardName, "next"]); }
    StyledText {
        text: Metrics.data.keyboard.slice(0, 3).toUpperCase()
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        color: Theme.onSurfaceVariant
    }
}
