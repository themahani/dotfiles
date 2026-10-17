import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Wayland session lock with one surface per output. Lock.lock() engages it
// (IPC: "lock lock"); only a successful password check releases it.
WlSessionLock {
    locked: Lock.locked
    surface: Component { LockSurface {} }
}
