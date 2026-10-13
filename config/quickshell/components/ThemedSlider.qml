import QtQuick
import QtQuick.Controls
import "../theme"

Slider {
    id: root
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth; height: 6
        radius: 3; color: Theme.surface1
        Rectangle { width: root.visualPosition * parent.width; height: parent.height; radius: 3; color: Theme.sapphire }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 16; height: 16; radius: 8
        color: root.pressed ? Theme.blue : Theme.text
        border.color: Theme.sapphire
    }
}
