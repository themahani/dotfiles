import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root
    property var values: []
    property real minimum: 0
    property real maximum: 100
    property color color: Theme.primary
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeColor: root.color
        strokeWidth: 2
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline {
            path: {
                const count = root.values.length;
                if (count < 2) return [];
                const span = Math.max(1e-6, root.maximum - root.minimum);
                return root.values.map((value, index) => Qt.point(index * root.width / (count - 1),
                    root.height - 1 - Math.max(0, Math.min(1, (value - root.minimum) / span)) * (root.height - 2)));
            }
        }
    }
}
