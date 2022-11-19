-- Author: CommanderQ
--
-- Copyright 2021 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local capabilities = require "st.capabilities"
local log = require "log"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=3 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2,strict=true})
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"

local function device_added(driver, device)
  device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function update_preferences(driver, device, args)
  local preferences = preferencesMap.get_device_parameters(device)
  for id, value in pairs(device.preferences) do
    if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value and preferences and preferences[id]) then
      if preferences[id].type == 'config' then
        local new_parameter_value = preferencesMap.to_numeric_value(device.preferences[id])
        device:send(Configuration:Set({parameter_number = preferences[id].parameter_number, size = preferences[id].size, configuration_value = new_parameter_value}))
        device:send(Configuration:Get({parameter_number = preferences[id].parameter_number}))
      elseif preferences[id].type == 'assoc' then
        local group = preferences[id].group
        local maxnodes = preferences[id].maxnodes
        local addhub = preferences[id].addhub
        local nodes = splitAssocString(value,',',maxnodes,addhub)
        local hubnode = device.driver.environment_info.hub_zwave_id
        device:send(Association:Remove({grouping_identifier = group, node_ids = {}}))
        if addhub then device:send(Association:Set({grouping_identifier = group, node_ids = {hubnode}})) end --add hub to group 3 for double click reporting
        if #nodes > 0 then
          device:send(Association:Set({grouping_identifier = group, node_ids = nodes}))
        end
        device:send(Association:Get({grouping_identifier = group}))
      end
    end
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function info_changed(driver, device, event, args)
  update_preferences(driver, device, args)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  device:refresh()
  update_preferences(driver, device)
end

--- Interrogate the device's supported command classes to determine whether a
--- BASIC, SWITCH_BINARY or SWITCH_MULTILEVEL set should be issued to fulfill
--- the on/off capability command.
--- Based upon lua_libs-api_v1\st\zwave\defaults\switch.lua
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param value number st.zwave.CommandClass.SwitchBinary.value.OFF_DISABLE or st.zwave.CommandClass.SwitchBinary.value.ON_ENABLE
--- @param command table The capability command table
local function switch_set_helper(driver, device, value, command)

  if (device.preferences.alwaysOnMode == 1) then
    log.trace_with({ hub_logs = true}, "Switch has been configured with button-only switch control - ignoring switch change command")
  else
    local set
    local get
    local delay = constants.DEFAULT_GET_STATUS_DELAY
    set = SwitchBinary:Set({
      target_value = value,
      duration = 0
    })
    get = SwitchBinary:Get({})
    device:send_to_component(set, command.component)
    local query_device = function()
      device:send_to_component(get, command.component)
    end
    device.thread:call_with_delay(delay, query_device)
  end

end

--- Issue a switch-on command to the specified device.
--- Copied from lua_libs-api_v1\st\zwave\defaults\switch.lua
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command table The capability command table
function switch_on_handler(driver, device, command)
  switch_set_helper(driver, device, SwitchBinary.value.ON_ENABLE, command)
end

--- Issue a switch-off command to the specified device.
--- Copied from lua_libs-api_v1\st\zwave\defaults\switch.lua
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command table The capability command table
function switch_off_handler(driver, device, command)
  switch_set_helper(driver, device, SwitchBinary.value.OFF_DISABLE, command)
end

local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.energyMeter,
    capabilities.powerMeter,
    capabilities.colorControl,
  },
  lifecycle_handlers = {
    infoChanged = info_changed,
    doConfigure = do_configure,
    added = device_added
  },
  capability_handlers = {
    [capabilities.switch.commands.on] = switch_on_handler,
    [capabilities.switch.commands.off] = switch_off_handler
  },
  NAME = "Aeotec Smart Switch 6",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local ge_switch = ZwaveDriver("aeotec-smart-switch-6", driver_template)
ge_switch:run()