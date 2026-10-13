//@ pragma UseQApplication
//@ pragma RespectSystemStyle
//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME = qt6ct
import Quickshell
import "services"
import "bar"
import "notifications"
import "osd"

ShellRoot {
    // Instantiate shared services once, not once per output.
    property var notifications: Notifications
    property var controls: Controls
    property var metrics: Metrics

    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }
    NotificationWindows {}
    OsdWindow {}
}
