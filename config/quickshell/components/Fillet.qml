import QtQuick
import QtQuick.Shapes
import "../theme"

// Concave corner joining a surface edge to the shape below it. The solid part
// hugs the top-right corner; set mirrored to hug the top-left instead.
Shape {
    id: root
    property color color: Theme.surfaceContainer
    property real radius: Theme.fillet
    property bool mirrored: false
    width: radius
    height: radius
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { xScale: root.mirrored ? -1 : 1; origin.x: root.radius / 2 }
    ShapePath {
        fillColor: root.color
        strokeWidth: -1
        startX: 0; startY: 0
        PathLine { x: root.radius; y: 0 }
        PathLine { x: root.radius; y: root.radius }
        PathArc { x: 0; y: 0; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
    }
}
