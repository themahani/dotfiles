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
    property bool locked: false         // the lock screen's variant: no tray, title, workspaces or system panel
    readonly property alias barItem: bar
    readonly property alias panelItem: panelArea

    readonly property string screenName: screen ? screen.name : ""
    // Panels belong to whichever variant matches the lock state, so the
    // Drawer underneath a lock never opens (or grabs focus) while locked.
    readonly property bool active: Panels.open !== "" && Panels.screenName === screenName && Lock.locked === locked
    readonly property bool focusedOutput: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === screenName
    readonly property bool showPopups: !locked && !Lock.locked && !active && focusedOutput && Notifications.popups.length > 0
    readonly property string mode: active ? Panels.open : showPopups ? "popup" : ""
    readonly property var panels: locked ? ({ media: mediaPanel, controls: lockControls })
        : ({ clock: clockPanel, popup: popupPanel, system: systemPanel, media: mediaPanel, tray: trayPanel })

    // Content stays loaded while the surface closes; geometry slides only
    // between two open panels, never when opening from the bar.
    property string shownMode: ""
    property string previousMode: ""
    readonly property bool sliding: mode !== "" && previousMode !== ""
    onModeChanged: {
        if (mode !== "" && panels[mode]) shownMode = mode;
        Qt.callLater(() => previousMode = mode);
    }

    readonly property real anchorCenter: shownMode === "media" ? media.x + media.width / 2 : bar.center.x + bar.center.width / 2
    readonly property real targetWidth: content.item ? Math.ceil(content.item.implicitWidth) : 0
    readonly property real targetX: {
        if (shownMode === "system" || shownMode === "controls") return width - targetWidth;
        if (shownMode === "tray") return 0;
        const x = anchorCenter - targetWidth / 2;
        return Math.round(x < 24 ? 0 : x + targetWidth > width - 24 ? width - targetWidth : x);
    }
    property real panelX: targetX
    property real panelWidth: targetWidth
    // The drawn edges, on whole pixels: on a fractional edge the panel and the
    // curve beside it both antialias the same pixel column and let what's
    // underneath show through. Rounded per frame, so slides stay seamless.
    readonly property int edgeLeft: Math.round(panelX)
    readonly property int edgeRight: Math.round(panelX + panelWidth)
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
            x: root.edgeLeft
            y: Theme.barSize
            width: root.edgeRight - root.edgeLeft
            height: root.panelHeight
            color: Theme.surfaceContainer
            bottomLeftRadius: Math.min(Theme.panelRadius, height)
            bottomRightRadius: Math.min(Theme.panelRadius, height)
        }
        Item {
            x: root.edgeLeft - Theme.fillet
            y: Theme.barSize
            width: Theme.fillet
            height: Math.min(Theme.fillet, root.panelHeight)
            visible: root.edgeLeft > 0
            clip: true
            Fillet {}
        }
        Item {
            x: root.edgeRight
            y: Theme.barSize
            width: Theme.fillet
            height: Math.min(Theme.fillet, root.panelHeight)
            visible: root.edgeRight < root.width
            clip: true
            Fillet { mirrored: true }
        }
        // The panel's rounded corners antialias its straight sides too, which
        // leaves its outermost column slightly see-through. Where a curve
        // joins it, an unantialiased strip over both columns hides that.
        Rectangle {
            x: root.edgeLeft - 1
            y: Theme.barSize
            width: 2
            height: Math.min(Theme.fillet, root.panelHeight)
            visible: root.edgeLeft > 0
            antialiasing: false
            color: Theme.surfaceContainer
        }
        Rectangle {
            x: root.edgeRight - 1
            y: Theme.barSize
            width: 2
            height: Math.min(Theme.fillet, root.panelHeight)
            visible: root.edgeRight < root.width
            antialiasing: false
            color: Theme.surfaceContainer
        }
    }

    Item {
        id: bar
        width: parent.width
        height: Theme.barSize
        MouseArea { anchors.fill: parent }   // the bar's background is not "outside"

        LockedLabel { visible: root.locked; x: 8; anchors.verticalCenter: parent.verticalCenter }
        Row {
            id: left
            visible: !root.locked
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
            visible: !root.locked
            screen: root.screen
            anchors { right: clock.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        }
        ClockButton {
            id: clock
            visible: !root.locked
            screen: root.screen
            x: Math.round((parent.width - width) / 2)
            anchors.verticalCenter: parent.verticalCenter
        }
        NotificationSummary {
            id: summary
            visible: root.locked
            x: Math.round((parent.width - width) / 2)
            anchors.verticalCenter: parent.verticalCenter
        }
        readonly property Item center: root.locked ? summary : clock
        MediaChip {
            id: media
            screen: root.screen
            x: bar.center.x + bar.center.width + 8
            anchors.verticalCenter: parent.verticalCenter
            maximumWidth: Math.max(0, Math.min(260, right.x - x - 16))
        }
        Row {
            id: right
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2
            StatsButton { visible: !root.locked }
            LayoutButton {}
            StatusButton { screen: root.screen; panel: root.locked ? "controls" : "system" }
        }
    }

    FocusScope {
        id: panelArea
        x: root.edgeLeft
        y: Theme.barSize
        width: root.edgeRight - root.edgeLeft
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
    Component { id: lockControls; LockControls {} }
}
