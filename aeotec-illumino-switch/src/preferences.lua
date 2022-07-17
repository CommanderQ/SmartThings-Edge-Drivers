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

local DIMMER = {
  PARAMETERS = {
    powerRestore        = { type = 'config', parameter_number = 20, size = 1 },
    offTimer            = { type = 'config', parameter_number = 40, size = 4 },
    onTimer             = { type = 'config', parameter_number = 41, size = 4 },
    instantStatusReport = { type = 'config', parameter_number = 80, size = 1 },
    assnControlSettings = { type = 'config', parameter_number = 82, size = 1 },
    ledIndicator        = { type = 'config', parameter_number = 83, size = 1 },
    ledBrightness       = { type = 'config', parameter_number = 86, size = 1 },
    ledColor            = { type = 'config', parameter_number = 84, size = 1 },
    ledSceneColor       = { type = 'config', parameter_number = 85, size = 1 },
    singleTapBehavior   = { type = 'config', parameter_number = 110, size = 1 },
    doubleTapBehavior   = { type = 'config', parameter_number = 111, size = 1 },
    externalSwitchScene = { type = 'config', parameter_number = 119, size = 1 },
    externalSwitchType  = { type = 'config', parameter_number = 120, size = 1 },
    outputControl       = { type = 'config', parameter_number = 121, size = 1 },
    buttonBehavior      = { type = 'config', parameter_number = 122, size = 1 },
    reportBehavior      = { type = 'config', parameter_number = 123, size = 1 },
    tapRampRate         = { type = 'config', parameter_number = 125, size = 1 },
    pressRampRate       = { type = 'config', parameter_number = 126, size = 1 },
    minimumDimLevel     = { type = 'config', parameter_number = 131, size = 1 },
    maximumDimLevel     = { type = 'config', parameter_number = 132, size = 1 },
    customDimLevel      = { type = 'config', parameter_number = 133, size = 1 },
    assocGroup1         = { type = 'assoc', group = 1, maxnodes = 5, addhub = false },
    assocGroup2         = { type = 'assoc', group = 2, maxnodes = 5, addhub = false },
    assocGroup3         = { type = 'assoc', group = 3, maxnodes = 5, addhub = false },
    assocGroup4         = { type = 'assoc', group = 4, maxnodes = 5, addhub = false },
    assocGroup5         = { type = 'assoc', group = 5, maxnodes = 5, addhub = false },
    assocGroup6         = { type = 'assoc', group = 6, maxnodes = 5, addhub = false },
    assocGroup7         = { type = 'assoc', group = 7, maxnodes = 5, addhub = false },
    assocGroup8         = { type = 'assoc', group = 8, maxnodes = 5, addhub = false },
    assocGroup9         = { type = 'assoc', group = 9, maxnodes = 5, addhub = false },
  },
  BUTTONS = {
    count = 1,
    values = { 'up', 'down', 'pushed', 'up_hold', 'down_hold', 'held', 'up_2x', 'down_2x', 'pushed_2x' },
  },
}

local devices = {
  AEOTEC_ILLUMINO_DIMMER = {
    MATCHING_MATRIX = {
      mfrs = { 0x0371 },
      product_types = { 0x0103 },
      product_ids = { 0x0025 },
    },
    PARAMETERS = DIMMER.PARAMETERS,
    BUTTONS = DIMMER.BUTTONS,
  }
}
local preferences = {}

preferences.get_device_parameters = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.PARAMETERS
    end
  end
  return nil
end

preferences.get_buttons = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.BUTTONS
    end
  end
  return nil
end

preferences.to_numeric_value = function(new_value)
  local numeric = tonumber(new_value)
  if numeric == nil then -- in case the value is boolean
    numeric = new_value and 1 or 0
  end
  return numeric
end

return preferences
