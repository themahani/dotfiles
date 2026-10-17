import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../services"
import "../theme"

// Clock and date; on the primary output also the account, password field,
// status line and player.
Item {
    id: root
    property bool primary: true
    property string userName: Quickshell.env("USER") || ""

    SystemClock { id: clock; precision: SystemClock.Minutes }
    // The account's real name, if the passwd entry has one.
    Process {
        running: true
        command: ["getent", "passwd", Quickshell.env("USER") || ""]
        stdout: SplitParser {
            onRead: line => {
                const name = (line.split(":")[4] || "").split(",")[0].trim();
                if (name) root.userName = name.split(" ")[0];
            }
        }
    }
    // Typing goes to the password field whenever no panel holds the focus.
    Connections {
        target: Panels
        function onOpenChanged() { if (Panels.open === "" && root.primary) password.focusInput(); }
    }
    Component.onCompleted: if (primary) password.focusInput()

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.17)
        spacing: 0

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
            font.pixelSize: 132
            font.weight: Font.Light
            height: 140
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 8
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            font.pixelSize: 22
            font.weight: Font.Normal
            color: Theme.onSurfaceVariantColor
        }

        Column {
            visible: root.primary
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 80
            spacing: 12
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 72; height: 72; radius: 36
                color: Theme.primaryContainer
                StyledText {
                    anchors.centerIn: parent
                    text: root.userName.charAt(0).toUpperCase()
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    color: Theme.onPrimaryContainerColor
                }
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                font.pixelSize: 18
            }
            Item { width: 1; height: 8 }
            PasswordField { id: password; anchors.horizontalCenter: parent.horizontalCenter }
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 380
                height: 28
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: Lock.failed || Metrics.data.capsLock
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: Lock.failed ? "error" : "keyboard_capslock"
                        filled: Lock.failed
                        size: 18
                        color: Lock.failed ? Theme.error : Theme.tertiary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Lock.failed ? (Lock.message || "Wrong password") : "Caps Lock is on"
                        color: Lock.failed ? Theme.error : Theme.tertiary
                    }
                }
            }
            Item { width: 1; height: 24 }
            LockMedia {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Players.player !== null
            }
        }
    }
}
