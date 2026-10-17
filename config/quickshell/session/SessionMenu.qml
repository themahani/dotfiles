import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"
import "../services"
import "../theme"

// Full-screen session menu on the focused output, in place of wlogout. Each
// action's letter runs it, arrows or Tab move between them, Enter runs the
// highlighted one, and Escape or a click outside closes the menu.
PanelWindow {
    id: window
    visible: Session.open
    screen: Quickshell.screens.find(output => output.name === Session.screenName) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // A click on another output closes the menu.
    HyprlandFocusGrab { windows: [window]; active: Session.open; onCleared: Session.close() }

    property int current: 0
    onVisibleChanged: if (visible) { current = 0; keys.forceActiveFocus(); }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: window.visible ? 0.8 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
    }
    MouseArea { anchors.fill: parent; onClicked: Session.close() }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            const actions = Session.actions;
            if (event.key === Qt.Key_Escape) Session.close();
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) window.current = (window.current + 1) % actions.length;
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) window.current = (window.current + actions.length - 1) % actions.length;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) Session.run(actions[window.current].id);
            else {
                const action = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier) ? null
                    : actions.find(entry => entry.key === event.text);
                if (!action) return;
                Session.run(action.id);
            }
            event.accepted = true;
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 16
        // Six across on a 1920px output, shrinking to fit narrower ones.
        readonly property real size: Math.min(200, (window.width - 96 - spacing * (Session.actions.length - 1)) / Session.actions.length)
        opacity: window.visible ? 1 : 0
        scale: window.visible ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
        Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        Repeater {
            model: Session.actions
            Rectangle {
                id: action
                required property var modelData
                required property int index
                readonly property bool highlighted: window.current === index
                readonly property color content: highlighted ? Theme.onPrimaryContainerColor : Theme.onSurfaceColor
                width: row.size
                height: row.size
                radius: 32
                color: highlighted ? Theme.primaryContainer : Theme.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: Theme.durationShort } }
                Accessible.role: Accessible.Button
                Accessible.name: modelData.label

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: action.modelData.icon
                        filled: action.highlighted
                        // The highlighted icon grows, as wlogout's did.
                        size: Math.round(row.size * (action.highlighted ? 0.34 : 0.28))
                        Behavior on size { NumberAnimation { duration: Theme.durationShort; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                        color: action.content
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.label
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: action.content
                    }
                }
                // The action's key, as wlogout's keybind.
                Rectangle {
                    anchors { top: parent.top; right: parent.right; margins: 14 }
                    width: 26; height: 26; radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: action.highlighted ? action.content : Theme.outlineVariant
                    StyledText {
                        anchors.centerIn: parent
                        text: action.modelData.key.toUpperCase()
                        font.pixelSize: 13
                        color: action.highlighted ? action.content : Theme.onSurfaceVariantColor
                    }
                }
                StateLayer {
                    color: action.content
                    onContainsMouseChanged: if (containsMouse) window.current = action.index
                    onClicked: Session.run(action.modelData.id)
                }
            }
        }
    }
}
