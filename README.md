# SmartThings Edge Drivers
A small set of SmartThings Edge device drivers for Aeotec z-wave devices that provide advanced configuration options not present in the stock SmartThings Edge drivers. These drivers control the full range of preferences described in the [technical specifications](./docs/device%20specifications/) for each device, exposing control for behaviors and features such as switch behavior, indicator brightness & color, and setting group associations.

# Devices
* [Aeotec Illumino Dimmer](https://aeotec.com/products/aeotec-dimmer-switch/) (ZWA037-A)
* [Aeotec Illumino Switch](https://aeotec.com/products/aeotec-wall-switch/) (ZWA038-A)

# Usage
Simply use the [channel invitation](https://bestow-regional.api.smartthings.com/invite/RBlE09xRBN2E) to enroll in the channel and use the desired drivers. These drivers are not officially provided by either Aeotec or SmartThings and are provided as-is with no warranty or guarantee of functionality.

# Development
Creating and testing the drivers from source code is easy: follow the [Edge driver tutorial](https://community.smartthings.com/t/tutorial-creating-drivers-for-z-wave-devices-with-smartthings-edge/229503). Contributions and suggestions are quite welcome!

## Credits
Much of the driver code is a minor alteration of [SmartThings Edge drivers](https://github.com/SmartThingsCommunity/SmartThingsEdgeDrivers) with enhancements inspired by [philh30's SmartThings Edge drivers for GE devices](https://github.com/philh30/ST-Edge-Drivers).