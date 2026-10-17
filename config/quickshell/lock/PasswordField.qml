import QtQuick
import "../components"
import "../services"
import "../theme"

// Pill password field: checks on Enter, spins while PAM works, shakes and
// turns red on a wrong password.
Rectangle {
    id: root
    function focusInput() { input.forceActiveFocus(); }
    implicitWidth: 380
    implicitHeight: 56
    radius: 28
    color: Theme.surfaceContainerHigh
    border.width: Lock.failed || Lock.checking ? 2 : 1
    border.color: Lock.failed ? Theme.error : Lock.checking ? Theme.primary : Theme.outlineVariant

    Icon {
        id: lockIcon
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        name: "lock"
        filled: true
        color: Lock.failed ? Theme.error : Theme.onSurfaceVariantColor
    }
    TextInput {
        id: input
        anchors { left: lockIcon.right; leftMargin: 12; right: trailing.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        echoMode: TextInput.Password
        passwordCharacter: "•"
        enabled: !Lock.checking
        color: Theme.onSurfaceColor
        font.family: Theme.font
        font.pixelSize: 18
        font.letterSpacing: 2
        clip: true
        focus: true
        text: Lock.password
        onTextEdited: { Lock.password = text; Lock.failed = false; }
        onAccepted: Lock.submit()
        Keys.onPressed: event => { Lock.activity(); event.accepted = false; }
        Keys.onEscapePressed: Lock.password = ""
        Accessible.name: "Password"
    }
    StyledText {
        anchors.fill: input
        visible: input.text === ""
        text: "Password"
        color: Theme.onSurfaceVariantColor
        font.weight: Font.Normal
        font.pixelSize: 16
    }
    Item {
        id: trailing
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        width: 40; height: 40
        Spinner { anchors.centerIn: parent; visible: Lock.checking; color: Theme.primary }
        IconButton {
            anchors.fill: parent
            visible: !Lock.checking
            color: Theme.primary
            contentColor: Theme.onPrimaryColor
            icon: "arrow_forward"
            tooltip: "Unlock"
            disabled: Lock.password === ""
            onClicked: Lock.submit()
        }
    }

    // Shake on every failed attempt.
    transform: Translate { id: shift }
    Connections {
        target: Lock
        function onFailuresChanged() { if (Lock.failures > 0) shake.restart(); }
    }
    SequentialAnimation {
        id: shake
        loops: 1
        NumberAnimation { target: shift; property: "x"; to: -8; duration: 50 }
        NumberAnimation { target: shift; property: "x"; to: 8; duration: 80 }
        NumberAnimation { target: shift; property: "x"; to: -6; duration: 70 }
        NumberAnimation { target: shift; property: "x"; to: 4; duration: 60 }
        NumberAnimation { target: shift; property: "x"; to: 0; duration: 50 }
    }
}
