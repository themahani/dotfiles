import QtQuick
import Quickshell
import Quickshell.Widgets
import "../components"
import "../services"
import "../theme"

// A tray item's DBus menu, drawn in the panel. Submenus slide in with a back
// row instead of cascading sideways.
Item {
    id: root
    readonly property var item: Panels.trayItem
    property var stack: []              // submenu entries, innermost last
    readonly property var current: stack.length ? stack[stack.length - 1] : (item ? item.menu : null)
    readonly property var entries: opener.children ? opener.children.values : []
    function label(text) { return (text || "").replace(/_(?!_)/g, "").replace(/__/g, "_"); }

    // Rows fill the menu's width, so measure their natural widths instead.
    readonly property real widest: {
        let width = header.implicitWidth;
        for (let i = 0; i < rows.count; i++) {
            const row = rows.itemAt(i);
            if (row) width = Math.max(width, row.implicitWidth);
        }
        return width;
    }
    implicitWidth: Math.max(220, Math.min(360, widest))
    implicitHeight: list.implicitHeight + 16
    onItemChanged: stack = []

    QsMenuOpener { id: opener; menu: root.current }

    Column {
        id: list
        y: 8
        width: root.width
        Item {
            id: header
            width: parent.width
            implicitWidth: title.implicitWidth + 32
            height: root.stack.length ? 48 : 28
            StyledText {
                id: title
                visible: !root.stack.length
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.item ? (root.item.tooltipTitle || root.item.title || root.item.id).toUpperCase() : ""
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
                color: Theme.onSurfaceVariantColor
            }
            Row {
                visible: root.stack.length > 0
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                IconButton { width: 36; height: 36; icon: "arrow_back"; tooltip: "Back"; onClicked: root.stack = root.stack.slice(0, -1) }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.stack.length ? root.label(root.stack[root.stack.length - 1].text) : ""
                    font.weight: Font.DemiBold
                }
            }
        }
        Repeater {
            id: rows
            model: root.entries
            Item {
                id: entry
                required property var modelData
                width: list.width
                implicitWidth: modelData.isSeparator ? 0 : 16 + 20 + 12 + text.implicitWidth + 16 + (modelData.hasChildren ? 28 : 0)
                height: modelData.isSeparator ? 9 : 40
                opacity: modelData.enabled ? 1 : 0.38
                Rectangle {
                    visible: entry.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 1
                    color: Theme.outlineVariant
                }
                Item {
                    visible: !entry.modelData.isSeparator
                    anchors.fill: parent
                    readonly property string mark: entry.modelData.buttonType === QsMenuButtonType.CheckBox
                        ? (entry.modelData.checkState === Qt.Checked ? "check" : "")
                        : entry.modelData.buttonType === QsMenuButtonType.RadioButton
                        ? (entry.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked") : ""
                    Icon {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.mark !== ""
                        name: parent.mark
                        filled: true
                        color: Theme.primary
                    }
                    IconImage {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.mark === "" && entry.modelData.icon !== ""
                        implicitSize: 18
                        source: entry.modelData.icon
                        mipmap: true
                    }
                    StyledText {
                        id: text
                        anchors { left: parent.left; leftMargin: 48; right: chevron.left; verticalCenter: parent.verticalCenter }
                        text: root.label(entry.modelData.text)
                        font.weight: Font.Normal
                    }
                    Icon {
                        id: chevron
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        visible: entry.modelData.hasChildren
                        width: visible ? implicitWidth : 0
                        name: "chevron_right"
                    }
                    StateLayer {
                        radius: 0
                        disabled: !entry.modelData.enabled
                        onClicked: {
                            if (entry.modelData.hasChildren) { root.stack = root.stack.concat([entry.modelData]); return; }
                            entry.modelData.triggered();
                            Panels.close();
                        }
                    }
                }
            }
        }
    }
}
