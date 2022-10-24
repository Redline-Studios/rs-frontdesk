Config = {}
Config.Debug = false -- True / False for Debug System
Config.Dispatch = "ps-dispatch" -- Default / ps-dispatch / cd-dispatch
Config.Jobs = {"police"} -- PD Job Name

Config.Locations = {
    ["police"] = {
        [1] = { name = "MRPD-FrontDesk", coords = vector3(442.44, -979.91, 30.69), length = 0.8, width = 0.6, heading = 335, minZ = 30.49, maxZ = 31.29
        },
    }
}

