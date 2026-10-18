-- Make the headphone jack and HDMI hotplug behave on cards whose UCM config
-- puts the headphones and the speakers in separate profiles (SOF HDA cards
-- such as skl_hda_dsp_generic).
--
-- Stock WirePlumber gets two things wrong on these cards:
--
-- * The HDMI outputs are part of both profiles, so with a monitor connected
--   neither profile ever turns unavailable. Unplugging the headphones changes
--   only the route availability, no select-profile event follows, and the
--   stored profile wins anyway once one was saved.
-- * The analog sink changes its name with the profile, so whenever the
--   configured sink is missing the default falls back to the stored history,
--   which often ranks an HDMI sink above the speakers.

cutils = require ("common-utils")
putils = require ("profile-utils")
log = Log.open_topic ("s-headphone-jack")

local function isManagedCard (device)
  return device.properties ["device.api"] == "alsa"
end

local function activeProfile (device)
  for p in device:iterate_params ("Profile") do
    return cutils.parseParam (p, "Profile")
  end
end

local function routeInProfile (route, profile)
  for _, index in ipairs (route.profiles) do
    if tonumber (index) == tonumber (profile.index) then
      return true
    end
  end
  return false
end

-- A card splits its outputs when some output route is missing from a profile
-- that a jack switch could pick.
local function splitsOutputs (routes, candidates)
  for _, route in ipairs (routes) do
    if route.direction == "Output" and route.profiles then
      for _, profile in ipairs (candidates) do
        if not routeInProfile (route, profile) then
          return true
        end
      end
    end
  end
  return false
end

SimpleEventHook {
  name = "headphone-jack/select-profile-on-route-changed",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-params-changed" },
      Constraint { "event.subject.param-id", "=", "EnumRoute" },
    },
  },
  execute = function (event)
    local device = event:get_subject ()
    if isManagedCard (device) then
      event:get_source ():call ("push-event", "select-profile", device, nil)
    end
  end
}:register ()

SimpleEventHook {
  name = "headphone-jack/find-jack-profile",
  before = { "device/find-stored-profile", "device/find-preferred-profile",
             "device/find-best-profile" },
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-profile" },
    },
  },
  execute = function (event)
    local device = event:get_subject ()
    if event:get_data ("selected-profile") or not isManagedCard (device) then
      return
    end

    -- leave "off" and "pro-audio" alone, those are deliberate choices
    local active = activeProfile (device)
    if active and (active.name == "off" or active.name == "pro-audio") then
      return
    end

    local routes = {}
    for r in device:iterate_params ("EnumRoute") do
      local route = cutils.parseParam (r, "EnumRoute")
      if route then
        table.insert (routes, route)
      end
    end

    local candidates = {}
    for p in device:iterate_params ("EnumProfile") do
      local profile = cutils.parseParam (p, "EnumProfile")
      if profile and profile.name ~= "off" and profile.name ~= "pro-audio"
          and profile.available ~= "no" then
        table.insert (candidates, profile)
      end
    end

    if #candidates < 2 or not splitsOutputs (routes, candidates) then
      return
    end

    local scores = putils.buildOutputRouteScores (routes)
    local best = nil
    for _, profile in ipairs (candidates) do
      if best == nil or putils.compareProfiles (profile, best, scores) then
        best = profile
      end
    end

    log:info (device, "following the jack to profile " .. best.name)
    event:set_data ("selected-profile", best)
  end
}:register ()

local function isHdmi (name)
  return name and name:lower ():find ("hdmi") ~= nil
end

SimpleEventHook {
  name = "headphone-jack/skip-unchosen-hdmi-sink",
  after = { "default-nodes/find-best-default-node",
            "default-nodes/find-selected-default-node",
            "default-nodes/find-stored-default-node" },
  before = "default-nodes/apply-default-node",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-default-node" },
      Constraint { "default-node.type", "=", "audio.sink" },
    },
  },
  execute = function (event)
    local selected = event:get_data ("selected-node")
    if not isHdmi (selected) then
      return
    end

    local metadata = cutils.get_default_metadata_object ()
    local configured = metadata and
        metadata:find (0, "default.configured.audio.sink")
    if configured and Json.Raw (configured):parse ().name == selected then
      return
    end

    local available = event:get_data ("available-nodes")
    available = available and available:parse () or {}

    local best, best_prio = nil, nil
    for _, props in ipairs (available) do
      local name = props ["node.name"]
      local prio = tonumber (props ["priority.session"]) or 0
      if not isHdmi (name) and (best_prio == nil or prio > best_prio) then
        best, best_prio = name, prio
      end
    end

    if best then
      log:info ("not defaulting to unchosen " .. selected .. ", using " .. best)
      event:set_data ("selected-node", best)
    end
  end
}:register ()
