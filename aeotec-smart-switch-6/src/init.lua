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
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=3 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"
--- @type st.zwave.CommandClass.SwitchColor
local SwitchColor = (require "st.zwave.CommandClass.SwitchColor")({ version = 3 })
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
local utils = require "st.utils"


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

--- A custom handler for setting the color.
--- The default setColor handler implementation sends along a duration of 1;
--- the Smart Switch doesn't seem to respond well to a duration value other than 0 (or unspecified).
--- This is a simple replacement implementation that removes the non-zero duration.
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_color(driver, device, command)
  local r, g, b = utils.hsl_to_rgb(command.args.color.hue, command.args.color.saturation)
  local set = SwitchColor:Set({
    color_components = {
      { color_component_id=SwitchColor.color_component_id.RED, value=r },
      { color_component_id=SwitchColor.color_component_id.GREEN, value=g },
      { color_component_id=SwitchColor.color_component_id.BLUE, value=b }
    }
  })
  device:send_to_component(set, command.component)
  local query_color = function()
    -- Use a single RGB color key to trigger our callback to emit a color
    -- control capability update.
    device:send_to_component(
      SwitchColor:Get({ color_component_id=SwitchColor.color_component_id.RED }),
      command.component
    )
  end
  device.thread:call_with_delay(constants.DEFAULT_GET_STATUS_DELAY, query_color)
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
    [capabilities.colorControl.ID] = {
      --[capabilities.colorControl.commands.setColor.NAME] = set_color
    },
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