import QtQuick
import QtQuick.Shapes
import "../theme"

// Material 3 expressive progress: the played part waves while playing.
// Drag or click to seek; seeking is reported on release.
Item {
    id: root
    property real value: 0              // 0..1
    property bool playing: false
    property bool seekable: true
    property color color: Theme.primary
    property real phase: 0
    readonly property real shown: drag.pressed ? drag.fraction : Math.max(0, Math.min(1, value))
    property real amplitude: playing && !drag.pressed ? 3 : 0
    signal seek(real fraction)
    implicitHeight: 28
    Behavior on amplitude { NumberAnimation { duration: Theme.durationMedium } }
    NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 2000; loops: Animation.Infinite; running: root.playing && root.visible }

    readonly property real split: 2 + (width - 4) * shown
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.color
            strokeWidth: 4
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: {
                    const points = [], end = Math.max(2, root.split - 6), middle = root.height / 2;
                    for (let x = 2; x <= end; x += 2)
                        points.push(Qt.point(x, middle + root.amplitude * Math.sin(x / 6.4 - root.phase)));
                    if (points.length < 2) points.push(Qt.point(2, middle), Qt.point(2.1, middle));
                    return points;
                }
            }
        }
        ShapePath {
            strokeColor: Qt.alpha(root.color, 0.3)
            strokeWidth: 4
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: Math.min(root.width - 2, root.split + 6); startY: root.height / 2
            PathLine { x: root.width - 2; y: root.height / 2 }
        }
    }
    Rectangle {
        x: root.split - 2
        anchors.verticalCenter: parent.verticalCenter
        width: 4; height: 22; radius: 2
        color: root.color
    }
    MouseArea {
        id: drag
        property real fraction: 0
        anchors.fill: parent
        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        function update(x) { fraction = Math.max(0, Math.min(1, (x - 2) / (width - 4))); }
        onPressed: event => update(event.x)
        onPositionChanged: event => { if (pressed) update(event.x); }
        onReleased: root.seek(fraction)
    }
    Accessible.role: Accessible.Slider
    Accessible.name: "Seek"
}
