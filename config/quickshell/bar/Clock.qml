import QtQuick
import Quickshell
import "../components"
import "../theme"

Chip {
    property bool compact: false
    SystemClock { id: clock; precision: SystemClock.Minutes }
    text: Qt.formatDateTime(clock.date, compact ? "'' hh:mm AP" : "'󰃭' ddd MMM dd '|' '' hh:mm AP")
    foreground: Theme.yellow
    onClicked: compact = !compact
}
