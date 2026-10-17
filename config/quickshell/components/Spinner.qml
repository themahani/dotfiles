import QtQuick
import "../theme"

Icon {
    name: "progress_activity"
    RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: visible }
}
