import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Reserves the bar's height; the drawer window itself ignores exclusive zones
// because it spans the whole output.
PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barSize
    exclusiveZone: Theme.barSize
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "quickshell-bar-zone"
    WlrLayershell.layer: WlrLayer.Bottom
}
