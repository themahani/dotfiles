import QtQuick
import "../components"
import "../services"
import "../theme"

BarButton {
    visible: Keyboard.layout !== ""
    tooltip: Keyboard.layout + "\nClick to switch layout"
    onClicked: { if (Keyboard.name) Controls.run(["hyprctl", "switchxkblayout", Keyboard.name, "next"]); }
    StyledText {
        text: Keyboard.layout.slice(0, 3).toUpperCase()
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        color: Theme.onSurfaceVariantColor
    }
}
