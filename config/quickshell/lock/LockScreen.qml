import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Wayland session lock with one surface per output. Lock.lock() engages it
// (IPC: "lock lock"); only a successful password check releases it.
Scope {
    WlSessionLock {
        id: lock
        locked: Lock.locked
        surface: Component { LockSurface {} }
    }
    // Suspend waits for this, and logind's LockedHint follows it.
    Binding { target: Lock; property: "secure"; value: lock.secure }
}
