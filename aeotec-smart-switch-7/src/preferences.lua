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

local SWITCH = {
  PARAMETERS = {
    ledMode              = { type = 'config', parameter_number = 1, size = 1 },
    nightLightOn              = { type = 'config', parameter_number = 2, size = 4 },
    nightLightOff              = { type = 'config', parameter_number = 3, size = 4 },
    ledBlinkDuration     = { type = 'config', parameter_number = 4, size = 1 },
    ledBlinkSpeed        = { type = 'config', parameter_number = 5, size = 1 },
    alertThreshold       = { type = 'config', parameter_number = 6, size = 2 },
    alwaysOnMode         = { type = 'config', parameter_number = 7, size = 1 },
    powerRestore         = { type = 'config', parameter_number = 8, size = 1 },
    group3SceneId        = { type = 'config', parameter_number = 9, size = 1 },
    overloadThreshold    = { type = 'config', parameter_number = 10, size = 2 },
    overvoltageThreshold = { type = 'config', parameter_number = 11, size = 1 },
    voltagePeriod        = { type = 'config', parameter_number = 25, size = 2 },
    thresholdPeriod      = { type = 'config', parameter_number = 19, size = 1 },
    energyThreshold      = { type = 'config', parameter_number = 20, size = 2 },
    energyPeriod         = { type = 'config', parameter_number = 24, size = 2 },
    powerThreshold       = { type = 'config', parameter_number = 21, size = 2 },
    powerPeriod          = { type = 'config', parameter_number = 23, size = 2 },
    currentThreshold     = { type = 'config', parameter_number = 22, size = 1 },
    currentPeriod        = { type = 'config', parameter_number = 26, size = 2 },
    autoOff              = { type = 'config', parameter_number = 40, size = 4 },
    autoOn               = { type = 'config', parameter_number = 41, size = 4 },
    reportingBehavior    = { type = 'config', parameter_number = 42, size = 1 },
    assocGroup1          = { type = 'assoc', group = 1, maxnodes = 5, addhub = false },
    assocGroup2          = { type = 'assoc', group = 2, maxnodes = 5, addhub = false },
    assocGroup3          = { type = 'assoc', group = 3, maxnodes = 5, addhub = false }
  }
}


local devices = {
  AEOTEC_SMART_SWITCH_7 = {
    MATCHING_MATRIX = {
      mfrs = 0x0371,
      product_types = 0x0103,
      product_ids = 0x0017
    },
    PARAMETERS = SWITCH
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

preferences.to_numeric_value = function(new_value)
  local numeric = tonumber(new_value)
  if numeric == nil then -- in case the value is boolean
    numeric = new_value and 1 or 0
  end
  return numeric
end

return preferences
