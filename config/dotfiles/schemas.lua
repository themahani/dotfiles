-- LuaLS types and runtime validation for *.local.lua settings.
-- Lists replace their base values. *_extra lists append unique entries.

---@class (exact) DotfilesNvimConfig
---@field copilot? boolean Enable Copilot; authentication is manual.
---@field servers? string[] Complete replacement list of nvim-lspconfig/Mason server names; {} disables automatic server installation/enablement.
---@field servers_extra? string[] Additional server names, e.g. "rust_analyzer". Use lspconfig names, not Mason package names.
---@field formatters? string[] Complete replacement list of Mason formatter package names; {} disables automatic formatter installation.
---@field formatters_extra? string[] Additional Mason formatter packages, e.g. "shfmt". Configure filetype mappings in nvim.extra.lua.

---@class (exact) DotfilesMouseConfig
---@field name string Exact device name reported by hyprctl devices.
---@field sensitivity? number Mouse sensitivity between -1 and 1.

---@class (exact) DotfilesHyprConfig
---@field terminal? string Terminal command used by the launcher keybind.
---@field file_manager? string File-manager command used by the launcher keybind.
---@field menu? string Launcher command, e.g. "rofi -show drun".
---@field keyboard_layout? string XKB layout list, e.g. "us,ir".
---@field keyboard_options? string XKB options; an empty string clears them.
---@field mouse? false|DotfilesMouseConfig False disables the base device-specific configuration; a table replaces it.
---@field autostart? string[] Complete replacement list of startup shell commands; {} disables all base startup commands.
---@field autostart_extra? string[] Additional startup shell commands. Runs on desktop startup.

local M = {}

local function nonempty_string(value)
  return type(value) == "string" and value:match("%S") ~= nil
end

local function string_list(value)
  if type(value) ~= "table" then
    return false
  end
  local count = 0
  for key, item in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or not nonempty_string(item) then
      return false
    end
    count = count + 1
  end
  for index = 1, count do
    if value[index] == nil then
      return false
    end
  end
  return true
end

local function mouse(value)
  if value == false then
    return true
  end
  if type(value) ~= "table" or not nonempty_string(value.name) then
    return false
  end
  for key in pairs(value) do
    if key ~= "name" and key ~= "sensitivity" then
      return false
    end
  end
  return value.sensitivity == nil or (type(value.sensitivity) == "number"
    and value.sensitivity >= -1 and value.sensitivity <= 1)
end

local fields = {
  nvim = {
    copilot = { function(value) return type(value) == "boolean" end, "boolean" },
    servers = { string_list, "a list of server names" },
    servers_extra = { string_list, "a list of server names" },
    formatters = { string_list, "a list of formatter package names" },
    formatters_extra = { string_list, "a list of formatter package names" },
  },
  hypr = {
    terminal = { nonempty_string, "a command string" },
    file_manager = { nonempty_string, "a command string" },
    menu = { nonempty_string, "a command string" },
    keyboard_layout = { nonempty_string, "an XKB layout string" },
    keyboard_options = { function(value) return type(value) == "string" end, "an XKB options string" },
    mouse = { mouse, "false or { name = string, sensitivity = number between -1 and 1 }" },
    autostart = { string_list, "a list of shell commands" },
    autostart_extra = { string_list, "a list of shell commands" },
  },
}

---@param kind "nvim"|"hypr"
---@param value unknown
---@return boolean valid
---@return string? error
function M.validate(kind, value)
  local schema = assert(fields[kind], "Unknown settings schema: " .. tostring(kind))
  if type(value) ~= "table" then
    return false, "the file must return a settings table"
  end
  for key, item in pairs(value) do
    local field = schema[key]
    if not field then
      return false, "unknown setting: " .. tostring(key)
    end
    if not field[1](item) then
      return false, tostring(key) .. " must be " .. field[2]
    end
  end
  return true
end

local function copy(value)
  if type(value) ~= "table" then
    return value
  end
  local result = {}
  for key, item in pairs(value) do
    result[key] = copy(item)
  end
  return result
end

---@param base table
---@param custom table
---@return table
function M.merge(base, custom)
  local result = copy(base)
  -- Replace lists/tables as complete values; {} must remain an empty list.
  for key, value in pairs(custom) do
    result[key] = copy(value)
  end
  for _, key in ipairs({ "servers", "formatters", "autostart" }) do
    local extra = result[key .. "_extra"]
    if extra then
      local list = result[key] or {}
      for _, value in ipairs(extra) do
        local found = false
        for _, existing in ipairs(list) do
          if existing == value then
            found = true
            break
          end
        end
        if not found then
          list[#list + 1] = value
        end
      end
      result[key] = list
      result[key .. "_extra"] = nil
    end
  end
  return result
end

---@param kind "nvim"|"hypr"
---@param path string
---@param report fun(message: string)
---@return table? settings
function M.read(kind, path, report)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  file:close()
  local ok, value = pcall(dofile, path)
  if not ok then
    report(path .. ": " .. tostring(value))
    return nil
  end
  local valid, err = M.validate(kind, value)
  if not valid then
    report(path .. ": " .. tostring(err))
    return nil
  end
  return value
end

return M
