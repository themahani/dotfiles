import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"
import "../panels"
import "../services"
import "../theme"

// One output's bar and the single panel surface that grows out of it.
// The window spans the output so panels, popups and outside clicks share it;
// its input mask covers only the bar (and popups) while nothing is open.
PanelWindow {
    id: window
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: active ? null : barInput

    readonly property string screenName: screen ? screen.name : ""
    readonly property bool active: Panels.open !== "" && Panels.screenName === screenName
    readonly property bool focusedOutput: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === screenName
    readonly property bool showPopups: !active && focusedOutput && Notifications.popups.length > 0
    readonly property string mode: active ? Panels.open : showPopups ? "popup" : ""
    readonly property var panels: ({ clock: clockPanel, popup: popupPanel })

    // Content stays loaded while the surface closes; geometry slides only
    // between two open panels, never when opening from the bar.
    property string shownMode: ""
    property string previousMode: ""
    readonly property bool sliding: mode !== "" && previousMode !== ""
    onModeChanged: {
        if (mode !== "" && panels[mode]) shownMode = mode;
        Qt.callLater(() => previousMode = mode);
    }

    readonly property real anchorCenter: shownMode === "media" ? media.x + media.width / 2 : clock.x + clock.width / 2
    readonly property real targetWidth: content.item ? content.item.implicitWidth : 0
    readonly property real targetX: {
        if (shownMode === "system") return width - targetWidth;
        if (shownMode === "tray") return 0;
        const x = anchorCenter - targetWidth / 2;
        return x < 24 ? 0 : x + targetWidth > width - 24 ? width - targetWidth : x;
    }
    property real panelX: targetX
    property real panelWidth: targetWidth
    property real panelHeight: mode !== "" && content.item ? content.item.implicitHeight : 0
    Behavior on panelX { enabled: window.sliding; NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    Behavior on panelWidth { enabled: window.sliding; NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    Behavior on panelHeight { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    onPanelHeightChanged: if (panelHeight === 0 && mode === "") shownMode = ""

    IdleInhibitor { window: window; enabled: Controls.idleInhibited }
    HyprlandFocusGrab { windows: [window]; active: window.active; onCleared: Panels.close() }

    Region { id: barInput; item: bar; Region { item: panelArea } }

    // Clicks outside the bar and panel close it.
    MouseArea {
        anchors.fill: parent
        enabled: window.active
        onClicked: Panels.close()
    }

    // Bar, end curves, panel and joints form one shape with one shadow.
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha(Theme.shadow, 0.45)
            shadowBlur: 0.6
            shadowVerticalOffset: 2
            blurMax: 24
        }
        Rectangle { width: parent.width; height: Theme.barSize; color: Theme.surfaceContainer }
        Fillet { y: Theme.barSize; mirrored: true }
        Fillet { x: parent.width - Theme.fillet; y: Theme.barSize }
        Rectangle {
            x: window.panelX
            y: Theme.barSize
            width: window.panelWidth
            height: window.panelHeight
            color: Theme.surfaceContainer
            bottomLeftRadius: Math.min(Theme.panelRadius, height)
            bottomRightRadius: Math.min(Theme.panelRadius, height)
        }
        Item {
            x: window.panelX - Theme.fillet
            y: Theme.barSize
            width: Theme.fillet
            height: Math.min(Theme.fillet, window.panelHeight)
            visible: window.panelX > 0.5
            clip: true
            Fillet {}
        }
        Item {
            x: window.panelX + window.panelWidth
            y: Theme.barSize
            width: Theme.fillet
            height: Math.min(Theme.fillet, window.panelHeight)
            visible: window.panelX + window.panelWidth < window.width - 0.5
            clip: true
            Fillet { mirrored: true }
        }
    }

    Item {
        id: bar
        width: parent.width
        height: Theme.barSize
        MouseArea { anchors.fill: parent }   // the bar's background is not "outside"

        Row {
            id: left
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            TrayIcons { id: tray; window: window; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                visible: tray.width > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 16
                color: Theme.outlineVariant
            }
            Item { width: 4; height: 1; visible: tray.width > 0 }
            WindowTitle {
                screen: window.screen
                anchors.verticalCenter: parent.verticalCenter
                maximumWidth: Math.min(300, workspaces.x - left.x - tray.width - 40)
            }
        }
        Workspaces {
            id: workspaces
            screen: window.screen
            anchors { right: clock.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        }
        ClockButton {
            id: clock
            screen: window.screen
            x: Math.round((parent.width - width) / 2)
            anchors.verticalCenter: parent.verticalCenter
        }
        MediaChip {
            id: media
            screen: window.screen
            anchors { left: clock.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
            maximumWidth: Math.max(0, Math.min(260, right.x - x - 16))
        }
        Row {
            id: right
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2
            StatsButton {}
            LayoutButton {}
            StatusButton { screen: window.screen }
        }
    }

    FocusScope {
        id: panelArea
        x: window.panelX
        y: Theme.barSize
        width: window.panelWidth
        height: window.panelHeight
        clip: true
        focus: window.active
        Keys.onEscapePressed: Panels.close()
        onFocusChanged: if (focus) forceActiveFocus()
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // swallow background clicks
        HoverHandler { onHoveredChanged: Notifications.paused = hovered && window.mode === "popup" }
        Loader {
            id: content
            sourceComponent: window.panels[window.shownMode] || null
            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 0
            onLoaded: fade.restart()
            NumberAnimation { id: fade; target: content.item; property: "opacity"; from: 0; to: 1; duration: Theme.durationShort }
        }
    }

    Component { id: clockPanel; ClockPanel {} }
    Component { id: popupPanel; Popups {} }
}
