conky.config = {
--Conky By Jesse Avalos See me on Eye candy Linux (Google +) for more conkys.
	background = true,
	update_interval = 1,

	cpu_avg_samples = 2,
	net_avg_samples = 2,
	temperature_unit = 'celsius',

	double_buffer = true,
	no_buffers = true,
	text_buffer_size = 2048,
	alignment = 'top_left',
	gap_x = 120,
	gap_y = 35,
	minimum_width = 550, minimum_height = 550,
	maximum_width = 550,
	own_window = true,
	own_window_type = 'dock',
	own_window_transparent = true,
	own_window_argb_visual = true,
	own_window_argb_value = 0,
	own_window_hints = 'undecorated,sticky,skip_taskbar,skip_pager,below',
	border_inner_margin = 0,
	border_outer_margin = 0,


	draw_shades = false,
	draw_outline = false,
	draw_borders = false,
	draw_graph_borders = false,
	default_shade_color = '#112422',

	override_utf8_locale = true,
	use_xft = true,
	font = 'Feena Casual:size=10',
	xftalpha = 1,
	uppercase = true,

	default_color = '#D6D5D4',
--E87E3C
	own_window_colour = '#000000',
};

conky.text = [[


${goto 35}${color E87E3C}${font Feena Casual:size=100}${time %I }${font Feena Casual:size=45}${color D6D5D4}${time %A}#${color yellow}
${color D6D5D4}${goto 35}${voffset 55}${font Feena Casual:size=20}${time %d} ${font Feena Casual:size=45}${voffset -15}${time %B} ${font Feena Casual:size=20}${goto 65}${voffset 34}${time %Y}${font Feena Casual:size=100}${goto 155}${voffset -54}${color E87E3C}${time %M}${font Feena Casual:size=22}${color D6D5D4} ${time %P}




#${goto 60}${voffset -65}${font Feena Casual:size=23} ${time %A} |  #${time %B %d %Y}


]];
