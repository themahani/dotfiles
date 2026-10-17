import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"
import "../services"
import "../theme"

Row {
    id: root
    required property var screen
    spacing: 0
    Repeater {
        model: SystemTray.items
        Rectangle {
            id: item
            required property var modelData
            readonly property bool open: Panels.isOpen("tray", root.screen) && Panels.trayItem === modelData
            width: 32; height: 32; radius: 16
            color: open ? Theme.surfaceContainerHighest : "transparent"
            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: item.modelData.icon
                // Request the best available pixmap/vector raster for this output.
                backer.sourceSize: Qt.size(
                    Math.ceil(actualSize * (root.screen ? root.screen.devicePixelRatio : 1)),
                    Math.ceil(actualSize * (root.screen ? root.screen.devicePixelRatio : 1)))
                mipmap: true
                opacity: item.modelData.status === Status.Passive ? 0.5 : 1
            }
            StateLayer {
                id: layer
                onClicked: event => {
                    if (event.button === Qt.MiddleButton) item.modelData.secondaryActivate();
                    else if (item.modelData.hasMenu && (event.button === Qt.RightButton || item.modelData.onlyMenu || event.button === Qt.LeftButton)) {
                        // Menu-bearing items may implement Activate as a no-op, so either click opens the menu.
                        if (item.open) Panels.close();
                        else { Panels.trayItem = item.modelData; Panels.screenName = root.screen.name; Panels.open = "tray"; }
                    } else item.modelData.activate();
                }
                onScrolled: direction => item.modelData.scroll(direction * 120, false)
            }
            Tooltip {
                target: item
                text: item.modelData.tooltipTitle || item.modelData.title || item.modelData.id
                shown: layer.containsMouse && !item.open
            }
        }
    }
}
