-- GNOME-style dynamic workspaces, one strip per monitor. Workspaces are ordered
-- by ID and addressed by position. Hyprland already destroys an empty workspace
-- once it is left, so the only slot to add is a trailing empty workspace after
-- the last one with windows. Each function returns a closure, usable both in
-- hl.bind and as `hyprctl dispatch 'dynamic_workspaces.focus(1, "DP-1")'`.
local M = {}

local function strip(monitor)
	local list = {}
	for _, workspace in ipairs(hl.get_workspaces()) do
		if not workspace.special and workspace.id > 0 and workspace.monitor and workspace.monitor.name == monitor.name then
			table.insert(list, workspace)
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

-- The smallest ID after this strip that no monitor uses, so a new workspace
-- sorts last here without taking another monitor's ID.
local function new_id(list)
	local used = {}
	for _, workspace in ipairs(hl.get_workspaces()) do
		used[workspace.id] = true
	end
	local id = #list > 0 and list[#list].id + 1 or 1
	while used[id] do
		id = id + 1
	end
	return id
end

-- The workspace ID at a position, or nil. One past the end is the trailing
-- empty workspace, which only exists while the last workspace has windows.
local function target(list, index)
	if list[index] then
		return list[index].id
	end
	if index == #list + 1 and (#list == 0 or list[#list].windows > 0) then
		return new_id(list)
	end
end

local function position(list, workspace)
	for index, item in ipairs(list) do
		if item.id == workspace.id then
			return index
		end
	end
end

local function focus_where(name, pick)
	return function()
		local monitor = name and hl.get_monitor(name) or hl.get_active_monitor()
		if not monitor or not monitor.active_workspace then
			return
		end
		local list = strip(monitor)
		local current = position(list, monitor.active_workspace)
		local id = current and target(list, pick(current))
		if not id then
			return
		end
		if not monitor.focused then
			hl.dispatch(hl.dsp.focus({ monitor = monitor.name }))
		end
		hl.dispatch(hl.dsp.focus({ workspace = tostring(id) }))
	end
end

local function move_where(pick)
	return function()
		local window = hl.get_active_window()
		if not window or not window.workspace or not window.monitor then
			return
		end
		local list = strip(window.monitor)
		local current = position(list, window.workspace)
		if not current then
			return
		end
		local index = pick(current)
		-- Moving the last workspace's only window into the trailing slot would just renumber it.
		if index == current or (index == #list + 1 and current == #list and list[current].windows == 1) then
			return
		end
		local id = target(list, index)
		if id then
			hl.dispatch(hl.dsp.window.move({ workspace = tostring(id), follow = true }))
		end
	end
end

function M.focus(offset, monitor)
	return focus_where(monitor, function(current)
		return current + offset
	end)
end

function M.focus_index(index, monitor)
	return focus_where(monitor, function()
		return index
	end)
end

function M.move_window(offset)
	return move_where(function(current)
		return current + offset
	end)
end

function M.move_window_index(index)
	return move_where(function()
		return index
	end)
end

return M
