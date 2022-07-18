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
local cc = require "st.zwave.CommandClass"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local log = require "log"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=3 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.CentralScene
local CentralScene = (require "st.zwave.CommandClass.CentralScene")({version=3,strict=true})
--- @type st.zwave.CommandClass.SceneActivation
local SceneActivation = (require "st.zwave.CommandClass.SceneActivation")({ version=1 })
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"

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
local function added(driver, device)
  device:refresh()
  local configs = preferencesMap.get_buttons(device)
  if configs then
    for _, comp in pairs(device.profile.components) do
      if device:supports_capability_by_id(capabilities.button.ID, comp.id) then
        local number_of_buttons = comp.id == "main" and configs.number_of_buttons or 1
        device:emit_component_event(comp, capabilities.button.numberOfButtons({ value=number_of_buttons }))
        device:emit_component_event(comp, capabilities.button.supportedButtonValues(configs.supported_button_values))
      end
    end
  end
end

local map_key_attribute_to_capability = {
  [CentralScene.key_attributes.KEY_PRESSED_1_TIME] = capabilities.button.button.pushed,
  [CentralScene.key_attributes.KEY_RELEASED] = capabilities.button.button.held,
  [CentralScene.key_attributes.KEY_HELD_DOWN] = capabilities.button.button.down_hold,
  [CentralScene.key_attributes.KEY_PRESSED_2_TIMES] = capabilities.button.button.double,
  [CentralScene.key_attributes.KEY_PRESSED_3_TIMES] = capabilities.button.button.pushed_3x,
  [CentralScene.key_attributes.KEY_PRESSED_4_TIMES] = capabilities.button.button.pushed_4x,
  [CentralScene.key_attributes.KEY_PRESSED_5_TIMES] = capabilities.button.button.pushed_5x
}


--- Handler for scene notification command class reports
---
--- Shall emit appropriate capabilities.button event ( `pushed`, `held` etc.)
--- based on command's key_attributes
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.CentralScene.Notification
---           expected command arguments:
---           args={key_attributes="KEY_PRESSED_1_TIME",
---                 scene_number=0, sequence_number=0, slow_refresh=false}
local function central_scene_notification_handler(self, device, cmd)
  local event = map_key_attribute_to_capability[cmd.args.key_attributes]({state_change = true})
  device:emit_event_for_endpoint(cmd.args.scene_number, event)
  device:emit_event(event)
end

local function scene_activation_handler(self, device, cmd)
  local scene_id = cmd.args.scene_id
  local event = scene_id % 2 == 0 and capabilities.button.button.held or capabilities.button.button.pushed
  device:emit_event_for_endpoint((scene_id + 1) // 2, event({state_change = true}))
  device:emit_event(event({state_change = true}))
end

local function component_to_endpoint(device, component_id)
  local ep_num = component_id:match("button(%d)")
  return { ep_num and tonumber(ep_num) }
end

local function endpoint_to_component(device, ep)
  local button_comp = string.format("button%d", ep)
  if device.profile.components[button_comp] ~= nil then
    return button_comp
  else
    return "main"
  end
end

local function device_init(self, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
  device:set_update_preferences_fn(update_preferences)
end

local driver_template = {
  zwave_handlers = {
    [cc.CENTRAL_SCENE] = {
      [CentralScene.NOTIFICATION] = central_scene_notification_handler
    },
    [cc.SCENE_ACTIVATION] = {
      [SceneActivation.SET] = scene_activation_handler
    }
  },
  supported_capabilities = {
    capabilities.button,
    capabilities.battery
  },
  lifecycle_handlers = {
    init = device_init,
    added = added,
  },
  NAME = "Aeotec WallMote 7",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local ge_switch = ZwaveDriver("aeotec-wallmote-7", driver_template)
ge_switch:run()