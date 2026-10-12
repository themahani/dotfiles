-- Base settings are shared by every profile. Local settings replace or extend them.
local config = vim.env.XDG_CONFIG_HOME
if not config or config == "" then
  config = vim.env.HOME .. "/.config"
end
local settings = config .. "/dotfiles/"
local schema = dofile(settings .. "schemas.lua")
local function report(message)
  vim.notify("Invalid dotfiles settings: " .. message, vim.log.levels.WARN)
end
local base = assert(schema.read("nvim", settings .. "nvim.lua", report), "Missing/invalid nvim.lua; run ./install apply")
local options = schema.merge(base, schema.read("nvim", settings .. "nvim.local.lua", report) or {})
return options
