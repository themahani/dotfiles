require("./monitors.lua")
require("./workspaces.lua")

local terminal = "kitty"
local fileManager = "nautilus"
local menu = "wofi --show drun"

hl.on("hyprland.start", function()
	hl.exec_cmd("hyprpaper & waybar & hypridle")
	hl.exec_cmd("systemctl start --user hyprpolkitagent.service")
	hl.exec_cmd("swaync")
	hl.exec_cmd("nm-applet --appindicator")
	hl.exec_cmd("Telegram")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1.0 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 2,
		border_size = 2,

		col = {
			active_border = {
				colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
				angle = 45,
			},
			inactive_border = "rgba(595959aa)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "master",
	},
	decoration = {
		rounding = 8,
		rounding_power = 2,
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(a1a1a1ee)",
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},
	animations = {
		enabled = true,
	},
	dwindle = {
		preserve_split = true,
	},
	master = {
		mfact = 0.7,
		new_status = "inherit",
		new_on_top = true,
		new_on_active = "none",
		orientation = "left",
	},
	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 0.9,
		focus_fit_method = 1,
		follow_focus = true,
		follow_min_visible = 0.1,
		wrap_focus = true,
		wrap_swapcol = true,
		direction = "right",
	},
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = 1,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
		enable_swallow = false,
		swallow_regex = "(foot|kitty|alacritty|Alacritty)",
		allow_session_lock_restore = true,
		session_lock_xray = true,
		initial_workspace_tracking = false,
		focus_on_activate = true,
	},
	xwayland = {
		enabled = true,
		force_zero_scaling = true,
	},
	ecosystem = {
		no_donation_nag = true,
	},
	input = {
		kb_layout = "us,ir",
		kb_options = "grp:win_space_toggle",
		numlock_by_default = true,
		repeat_rate = 40,
		repeat_delay = 200, -- ms
		follow_mouse = 1,
		sensitivity = 0.5,
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			clickfinger_behavior = true,
			scroll_factor = 0.5,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

local mainMod = "SUPER"
hl.bind(mainMod .. "+ return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. "+ Q", hl.dsp.window.close())
hl.bind(mainMod .. "+ M", hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. "+ E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. "+ V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. "+ F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. "+ R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. "+ P", hl.dsp.window.pseudo({ action = "toggle" }))
local hyprshotOptions = "-z -oPictures/Screenshots"
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region " .. hyprshotOptions))
hl.bind(mainMod .. "+ SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m window -m active " .. hyprshotOptions))
hl.bind(mainMod .. "+ ALT + PRINT", hl.dsp.exec_cmd("hyprshot -m output -m active " .. hyprshotOptions))
hl.bind(mainMod .. "+ N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. "+ SHIFT + D", hl.dsp.exec_cmd("swaync-client --toggle-dnd"))
hl.bind(mainMod .. "+ W", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/rofi-hyprpaper.sh"))
hl.bind(mainMod .. "+ X", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. "+ escape", hl.dsp.exec_cmd("hyprlock"))

-- Navigation
hl.bind(mainMod .. "+ H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. "+ left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. "+ L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. "+ right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. "+ k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. "+ up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. "+ J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. "+ down", hl.dsp.focus({ direction = "d" }))

-- Nav for scrolling layout
hl.bind(mainMod .. "+ period", function()
	if hl.get_config("general.layout") == "scrolling" then
		hl.dsp.layout("move +col")
	end
end)
hl.bind(mainMod .. "+ comma", function()
	if hl.get_config("general.layout") == "scrolling" then
		hl.dsp.layout("move -col")
	end
end)
hl.bind(mainMod .. "+ S", function()
	if hl.get_config("general.layout") == "scrolling" then
		hl.dsp.layout("consume_or_expel next")
	end
end)

-- Move windows
hl.bind(mainMod .. "+ SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. "+ SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. "+ SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. "+ SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. "+ ALT + L", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. "+ ALT + H", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("ALT + TAB", function()
	hl.dsp.window.cycle_next()
	hl.dsp.window.bring_to_top()
end)

hl.bind(mainMod .. "+ bracketleft", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. "+ bracketright", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. "+ SHIFT + bracketright", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. "+ SHIFT + bracketleft", hl.dsp.window.move({ workspace = "r-1" }))

-- resize and drag with mouse
hl.bind(mainMod .. "+ mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. "+ mouse:273", hl.dsp.window.resize(), { mouse = true })

-- multimedia keys
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --inc"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --dec"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle-mic"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --inc"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --dec"),
	{ locked = true, repeating = true }
)
-- requiring playerctl
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- layer rules
hl.layer_rule({ match = { namespace = "wofi" }, no_anim = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.5 })

--- fix xwayland issues
hl.window_rule({ match = { class = "^$" }, no_focus = true })
hl.window_rule({ match = { title = "^$" }, no_focus = true })

hl.window_rule({ match = { class = "^(.*)$" }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { title = "^(.*)$" }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })
