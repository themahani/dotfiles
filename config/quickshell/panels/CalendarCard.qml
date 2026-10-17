import QtQuick
import Quickshell
import "../components"
import "../theme"

// This week as a strip; expands into a month grid with navigation.
Rectangle {
    id: root
    property bool expanded: false
    property int offset: 0              // months from today
    onExpandedChanged: offset = 0
    readonly property var letters: ["S", "M", "T", "W", "T", "F", "S"]
    readonly property date today: new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate())
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    function sameDay(a, b) { return a.getTime() === b.getTime(); }
    function days(start, count) {
        const result = [];
        for (let i = 0; i < count; i++) result.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
        return result;
    }

    implicitHeight: expanded ? 288 : 72
    radius: 20
    color: Theme.surfaceContainerHigh
    clip: true
    SystemClock { id: clock; precision: SystemClock.Hours }

    Row {
        visible: !root.expanded
        anchors.fill: parent
        anchors.margins: 8
        Repeater {
            model: root.days(new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate() - root.today.getDay()), 7)
            Column {
                required property date modelData
                required property int index
                width: (root.width - 16) / 7
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.letters[index]
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.onSurfaceVariantColor
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property bool isToday: root.sameDay(modelData, root.today)
                    width: 32; height: 32; radius: 16
                    color: isToday ? Theme.primary : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.getDate()
                        font.weight: parent.isToday ? Font.Bold : Font.Medium
                        color: parent.isToday ? Theme.onPrimaryColor : Theme.onSurfaceColor
                    }
                }
            }
        }
    }

    Column {
        visible: root.expanded
        anchors { fill: parent; leftMargin: 12; rightMargin: 12; topMargin: 8; bottomMargin: 8 }
        Item {
            width: parent.width
            height: 40
            StyledText {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: Qt.formatDate(root.month, "MMMM yyyy")
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                IconButton { width: 36; height: 36; icon: "chevron_left"; tooltip: "Previous month"; onClicked: root.offset-- }
                IconButton { width: 36; height: 36; icon: "chevron_right"; tooltip: "Next month"; onClicked: root.offset++ }
            }
        }
        Row {
            Repeater {
                model: root.letters
                StyledText {
                    required property string modelData
                    width: (root.width - 24) / 7
                    height: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.onSurfaceVariantColor
                }
            }
        }
        Grid {
            columns: 7
            Repeater {
                model: root.days(new Date(root.month.getFullYear(), root.month.getMonth(), 1 - root.month.getDay()), 42)
                Item {
                    required property date modelData
                    readonly property bool isToday: root.sameDay(modelData, root.today)
                    width: (root.width - 24) / 7
                    height: 34
                    Rectangle {
                        anchors.centerIn: parent
                        width: 30; height: 30; radius: 15
                        color: parent.isToday ? Theme.primary : "transparent"
                    }
                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.getDate()
                        font.pixelSize: 13
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                        color: parent.isToday ? Theme.onPrimaryColor : Theme.onSurfaceColor
                        opacity: parent.isToday || modelData.getMonth() === root.month.getMonth() ? 1 : 0.45
                    }
                }
            }
        }
    }
}
