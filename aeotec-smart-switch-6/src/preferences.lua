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
    overloadProtection      = { type = 'config', parameter_number = 3, size = 1 },
    powerRestore            = { type = 'config', parameter_number = 20, size = 1 },
    assoc1Notification      = { type = 'config', parameter_number = 80, size = 1 },
    ledMode                 = { type = 'config', parameter_number = 81, size = 1 },
    powerReportingThreshold = { type = 'config', parameter_number = 90, size = 1 },
    minimumPowerWatts       = { type = 'config', parameter_number = 91, size = 2 },
    minimumPowerPercent     = { type = 'config', parameter_number = 92, size = 1 },
    assocGroup1             = { type = 'assoc', group = 1, maxnodes = 5, addhub = false },
    assocGroup2             = { type = 'assoc', group = 2, maxnodes = 5, addhub = false },
  }
}


local devices = {
  AEOTEC_SMART_SWITCH_6 = {
    MATCHING_MATRIX = {
      mfrs = { 0x0086, 0x016A },
      product_types = { 0x0103, 0x0003, 0x0203, 0x016A },
      product_ids = 0x0060
    },
    PARAMETERS = SWITCH.PARAMETERS
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
