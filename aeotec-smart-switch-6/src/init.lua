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
local constants = require "st.zwave.constants"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=3 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"
local Basic = (require "st.zwave.CommandClass.Basic")({ version=2 })
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version=2 })

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

-- The Smart Switch 6 supports both the basic switch and the multi-level commands.
-- However, the switch itself is only controlled by the on/off command
-- while the multi-level commands control the indicator light.
-- As of the April 10, 2023 update, the SmartThings default handler will prefer the multi-level
-- control when turning the device on or off, so we need to use a specific handler for on / off commands.
local function on_off_factory(onOff)
  return function(driver, device, cmd)
    device:send(Basic:Set({value=onOff}))
    device.thread:call_with_delay(constants.DEFAULT_GET_STATUS_DELAY, function() device:send(SwitchBinary:Get({})) end)
  end
end

local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.energyMeter,
    capabilities.powerMeter,
    capabilities.colorControl,
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_off_factory(SwitchBinary.value.ON_ENABLE),
      [capabilities.switch.commands.off.NAME] = on_off_factory(SwitchBinary.value.OFF_DISABLE)
    }
  },
  lifecycle_handlers = {
    infoChanged = info_changed,
    doConfigure = do_configure,
    added = device_added
  },
  NAME = "Aeotec Smart Switch 6",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local ge_switch = ZwaveDriver("aeotec-smart-switch-6", driver_template)
ge_switch:run()