pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Material 3 color roles. matugen (config/matugen) writes them from the
    // wallpaper; the fallback is the dark tonal-spot scheme of Mocha blue.
    readonly property var fallback: ({
        primary: "#a8c8ff", on_primary: "#06305f", primary_container: "#254777", on_primary_container: "#d5e3ff",
        secondary: "#bdc7dc", on_secondary: "#273141", secondary_container: "#3e4758", on_secondary_container: "#d9e3f8",
        tertiary: "#dbbce1", on_tertiary: "#3e2845", tertiary_container: "#563e5d", on_tertiary_container: "#f8d8fe",
        error: "#ffb4ab", on_error: "#690005", error_container: "#93000a", on_error_container: "#ffdad6",
        surface: "#111318", surface_dim: "#111318", surface_bright: "#37393e",
        surface_container_lowest: "#0c0e13", surface_container_low: "#191c20", surface_container: "#1d2024",
        surface_container_high: "#282a2f", surface_container_highest: "#33353a",
        on_surface: "#e1e2e9", on_surface_variant: "#c4c6cf", outline: "#8e9099", outline_variant: "#43474e",
        inverse_surface: "#e1e2e9", inverse_on_surface: "#2e3035", inverse_primary: "#3f5f90",
        shadow: "#000000", scrim: "#000000"
    })
    property var generated: ({})
    function role(name) { return generated[name] || fallback[name]; }
    function parse(text) {
        try { return text ? JSON.parse(text) : {}; }
        catch (error) { console.warn("Invalid matugen colors:", error); return {}; }
    }

    readonly property color primary: role("primary")
    readonly property color onPrimary: role("on_primary")
    readonly property color primaryContainer: role("primary_container")
    readonly property color onPrimaryContainer: role("on_primary_container")
    readonly property color secondary: role("secondary")
    readonly property color onSecondary: role("on_secondary")
    readonly property color secondaryContainer: role("secondary_container")
    readonly property color onSecondaryContainer: role("on_secondary_container")
    readonly property color tertiary: role("tertiary")
    readonly property color onTertiary: role("on_tertiary")
    readonly property color tertiaryContainer: role("tertiary_container")
    readonly property color onTertiaryContainer: role("on_tertiary_container")
    readonly property color error: role("error")
    readonly property color onError: role("on_error")
    readonly property color errorContainer: role("error_container")
    readonly property color onErrorContainer: role("on_error_container")
    readonly property color surface: role("surface")
    readonly property color surfaceContainerLowest: role("surface_container_lowest")
    readonly property color surfaceContainerLow: role("surface_container_low")
    readonly property color surfaceContainer: role("surface_container")
    readonly property color surfaceContainerHigh: role("surface_container_high")
    readonly property color surfaceContainerHighest: role("surface_container_highest")
    readonly property color onSurface: role("on_surface")
    readonly property color onSurfaceVariant: role("on_surface_variant")
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
    Component.onCompleted: generated = parse(colors.text())

    // Type, shape and motion.
    readonly property string font: "Roboto"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int barSize: 40
    readonly property int fillet: 10          // window rounding 8 + gaps_out 2
    readonly property int panelRadius: 16
    readonly property var emphasized: [0.2, 0, 0, 1, 1, 1]
    readonly property int durationShort: 200
    readonly property int durationMedium: 350

    // Mocha palette, still used by modules that predate the Material redesign.
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color overlay2: "#9399b2"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color sapphire: "#74c7ec"
    readonly property color sky: "#89dceb"
    readonly property color teal: "#94e2d5"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color maroon: "#eba0ac"
    readonly property color red: "#f38ba8"
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f5c2e7"
    readonly property color flamingo: "#f2cdcd"
    readonly property color rosewater: "#f5e0dc"
    // Preserve the existing idle-inhibitor indicator exception.
    readonly property color idleActive: "#39ff14"
    readonly property string fontFamily: "Ubuntu Nerd Font"
    readonly property int fontSize: 13
    readonly property real letterSpacing: 0.5
    readonly property int barHeight: 42
    readonly property int radius: 10
}
