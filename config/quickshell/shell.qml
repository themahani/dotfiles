// Follow the GTK settings nwg-look writes (icon theme for tray and app icons).
//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME = gtk3
// Render every window on the GUI thread. The threaded loop gives each window
// its own render thread; this saves about 15 MB and four threads, and a
// shell's small frames (1-2 ms) still keep 60 fps on two outputs.
// Read at startup only, so a reload doesn't change it.
//@ pragma Env QSG_RENDER_LOOP = basic
import Quickshell
import "services"
import "bar"
import "lock"
import "osd"
import "session"

ShellRoot {
    // Instantiate shared services once, not once per output.
    property var notifications: Notifications
    property var controls: Controls
    property var metrics: Metrics
    property var panels: Panels
    property var bluetoothAgent: BluetoothAgent

    Variants {
        model: Quickshell.screens
        Scope {
            id: output
            required property var modelData
            Reserver { screen: output.modelData }
            Drawer { screen: output.modelData }
        }
    }
    OsdWindow {}
    SessionMenu {}
    LockScreen {}
}
