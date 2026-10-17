import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"

// One output's bar window. It spans the output so panels, popups and outside
// clicks share one surface; its input mask covers only the bar (and popups)
// while nothing is open.
PanelWindow {
    id: window
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: surface.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: surface.active ? null : barInput

    IdleInhibitor { window: window; enabled: Controls.idleInhibited }
    HyprlandFocusGrab { windows: [window]; active: surface.active; onCleared: Panels.close() }
    Region { id: barInput; item: surface.barItem; Region { item: surface.panelItem } }

    BarSurface { id: surface; anchors.fill: parent; screen: window.screen }
}
