import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../panels"
import "../services"
import "../theme"

// The bar and the single panel surface that grows out of it, filling its
// host: the output-wide Drawer window, or a lock surface while locked.
Item {
    id: root
    required property var screen
    readonly property alias barItem: bar
    readonly property alias panelItem: panelArea

    readonly property string screenName: screen ? screen.name : ""
    readonly property bool active: Panels.open !== "" && Panels.screenName === screenName
    readonly property bool focusedOutput: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === screenName
    readonly property bool showPopups: !active && focusedOutput && Notifications.popups.length > 0
    readonly property string mode: active ? Panels.open : showPopups ? "popup" : ""
    readonly property var panels: ({ clock: clockPanel, popup: popupPanel, system: systemPanel, media: mediaPanel, tray: trayPanel })

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
    Behavior on panelX { enabled: root.sliding; NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    Behavior on panelWidth { enabled: root.sliding; NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    Behavior on panelHeight { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    onPanelHeightChanged: if (panelHeight === 0 && mode === "") shownMode = ""

    // Clicks outside the bar and panel close it.
    MouseArea {
        anchors.fill: parent
        enabled: root.active
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
            x: root.panelX
            y: Theme.barSize
            width: root.panelWidth
            height: root.panelHeight
            color: Theme.surfaceContainer
            bottomLeftRadius: Math.min(Theme.panelRadius, height)
            bottomRightRadius: Math.min(Theme.panelRadius, height)
        }
        Item {
            x: root.panelX - Theme.fillet
            y: Theme.barSize
            width: Theme.fillet
            height: Math.min(Theme.fillet, root.panelHeight)
            visible: root.panelX > 0.5
            clip: true
            Fillet {}
        }
        Item {
            x: root.panelX + root.panelWidth
            y: Theme.barSize
            width: Theme.fillet
            height: Math.min(Theme.fillet, root.panelHeight)
            visible: root.panelX + root.panelWidth < root.width - 0.5
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
            TrayIcons { id: tray; screen: root.screen; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                visible: tray.width > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 16
                color: Theme.outlineVariant
            }
            Item { width: 4; height: 1; visible: tray.width > 0 }
            WindowTitle {
                screen: root.screen
                anchors.verticalCenter: parent.verticalCenter
                maximumWidth: Math.min(300, workspaces.x - left.x - tray.width - 40)
            }
        }
        Workspaces {
            id: workspaces
            screen: root.screen
            anchors { right: clock.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        }
        ClockButton {
            id: clock
            screen: root.screen
            x: Math.round((parent.width - width) / 2)
            anchors.verticalCenter: parent.verticalCenter
        }
        MediaChip {
            id: media
            screen: root.screen
            anchors { left: clock.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
            maximumWidth: Math.max(0, Math.min(260, right.x - x - 16))
        }
        Row {
            id: right
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2
            StatsButton {}
            LayoutButton {}
            StatusButton { screen: root.screen }
        }
    }

    FocusScope {
        id: panelArea
        x: root.panelX
        y: Theme.barSize
        width: root.panelWidth
        height: root.panelHeight
        clip: true
        focus: root.active
        Keys.onEscapePressed: Panels.close()
        Keys.onPressed: event => {
            // Backspace or Delete clears notifications while their panel is open.
            if (root.mode === "clock" && (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete)) {
                Notifications.clear();
                event.accepted = true;
            }
        }
        onFocusChanged: if (focus) forceActiveFocus()
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // swallow background clicks
        HoverHandler { onHoveredChanged: Notifications.paused = hovered && root.mode === "popup" }
        Loader {
            id: content
            sourceComponent: root.panels[root.shownMode] || null
            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 0
            onLoaded: fade.restart()
            NumberAnimation { id: fade; target: content.item; property: "opacity"; from: 0; to: 1; duration: Theme.durationShort }
        }
    }

    Component { id: clockPanel; ClockPanel {} }
    Component { id: popupPanel; Popups {} }
    Component { id: systemPanel; SystemPanel {} }
    Component { id: mediaPanel; MediaPanel {} }
    Component { id: trayPanel; TrayMenu {} }
}
