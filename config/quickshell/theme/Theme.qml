pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Material 3 color roles. matugen (config/matugen) writes them from the
    // wallpaper; until then the committed fallback.json (Mocha blue) applies.
    property var fallback: ({})
    property var generated: ({})
    function role(name) { return generated[name] || fallback[name]; }
    function parse(text) {
        try { return text ? JSON.parse(text) : {}; }
        catch (error) { console.warn("Invalid matugen colors:", error); return {}; }
    }

    readonly property color primary: role("primary")
    readonly property color onPrimaryColor: role("on_primary")
    readonly property color primaryContainer: role("primary_container")
    readonly property color onPrimaryContainerColor: role("on_primary_container")
    readonly property color secondary: role("secondary")
    readonly property color onSecondaryColor: role("on_secondary")
    readonly property color secondaryContainer: role("secondary_container")
    readonly property color onSecondaryContainerColor: role("on_secondary_container")
    readonly property color tertiary: role("tertiary")
    readonly property color onTertiaryColor: role("on_tertiary")
    readonly property color tertiaryContainer: role("tertiary_container")
    readonly property color onTertiaryContainerColor: role("on_tertiary_container")
    readonly property color error: role("error")
    readonly property color onErrorColor: role("on_error")
    readonly property color errorContainer: role("error_container")
    readonly property color onErrorContainerColor: role("on_error_container")
    readonly property color surface: role("surface")
    readonly property color surfaceContainerLowest: role("surface_container_lowest")
    readonly property color surfaceContainerLow: role("surface_container_low")
    readonly property color surfaceContainer: role("surface_container")
    readonly property color surfaceContainerHigh: role("surface_container_high")
    readonly property color surfaceContainerHighest: role("surface_container_highest")
    readonly property color onSurfaceColor: role("on_surface")
    readonly property color onSurfaceVariantColor: role("on_surface_variant")
    readonly property color outline: role("outline")
    readonly property color outlineVariant: role("outline_variant")
    readonly property color inverseSurface: role("inverse_surface")
    readonly property color inverseOnSurface: role("inverse_on_surface")
    readonly property color shadow: role("shadow")
    readonly property color scrim: role("scrim")

    FileView {
        id: colors
        path: Quickshell.env("HOME") + "/.local/state/matugen/quickshell.json"
        // Read synchronously at startup so the shell never flashes the fallback.
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.generated = root.parse(text())
        onLoadFailed: root.generated = ({})
    }
    FileView {
        id: fallbackColors
        path: Quickshell.shellPath("theme/fallback.json")
        blockLoading: true
        onLoaded: root.fallback = root.parse(text())
    }
    Component.onCompleted: {
        fallback = parse(fallbackColors.text());
        generated = parse(colors.text());
    }

    // Type, shape and motion.
    readonly property string font: "Roboto"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int barSize: 40
    readonly property int fillet: 10          // window rounding 8 + gaps_out 2
    readonly property int panelRadius: 16
    readonly property var emphasized: [0.2, 0, 0, 1, 1, 1]
    readonly property int durationShort: 200
    readonly property int durationMedium: 350
}
