import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"

Row {
    id: root
    required property var window
    spacing: 2
    height: 30
    Repeater {
        model: SystemTray.items
        delegate: Item {
            id: item
            required property var modelData
            width: 26; height: 30
            IconImage {
                anchors.centerIn: parent
                width: 24; height: 24
                source: item.modelData.icon
                // Request the best available pixmap/vector raster for this output.
                backer.sourceSize: Qt.size(
                    Math.ceil(actualSize * (root.window.screen ? root.window.screen.devicePixelRatio : 1)),
                    Math.ceil(actualSize * (root.window.screen ? root.window.screen.devicePixelRatio : 1)))
                mipmap: true
                opacity: item.modelData.status === Status.Passive ? 0.5 : 1
            }
            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.window: root.window
                anchor.rect.x: item.mapToItem(root.window.contentItem, 0, 0).x
                anchor.rect.y: root.window.height + 4
                anchor.rect.width: item.width
                anchor.rect.height: 1
            }
            Chip {
                anchors.fill: parent
                tooltip: item.modelData.tooltipTitle + "\n" + item.modelData.tooltipDescription
                onClicked: button => {
                    if (button === Qt.MiddleButton) item.modelData.secondaryActivate();
                    else if (item.modelData.hasMenu && (button === Qt.LeftButton || button === Qt.RightButton)) {
                        // Menu-bearing items may implement Activate as a no-op.
                        // Offer their options on either primary or secondary click.
                        if (menu.visible) menu.close();
                        else menu.open();
                    } else item.modelData.activate();
                }
                onScrolled: direction => item.modelData.scroll(direction * 120, false)
            }
        }
    }
}
