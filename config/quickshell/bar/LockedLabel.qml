import QtQuick
import "../components"
import "../theme"

Row {
    spacing: 8
    leftPadding: 8
    Icon { anchors.verticalCenter: parent.verticalCenter; name: "lock"; filled: true; size: 18; color: Theme.primary }
    StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Locked"; color: Theme.onSurfaceVariantColor }
}
