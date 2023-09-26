COMMANDS =          {}
COMMANDS.START =        { 
                        id = 'Start', 
                        params = {} 
                        }
--------------------------
--------------------------
function ACTIVATE_TACAN(TACtype, AA, callsign, modeChannel, channel, sys, UnitID, freq)
    return  { 
            id = 'ActivateBeacon', 
            params = { 
                type = TACtype,
                AA = AA,
                callsign = callsign, 
                modeChannel = modeChannel,
                channel = channel,
                system = sys, 
                unitId = UnitID,
                bearing = true,
                frequency = freq
                }
            }
end
--------------------------
--------------------------
function PrepUnitFrequencyChange(unitId, frequency, modulationID)
    return {
            id = "SetFrequencyForUnit",
            params = {
                modulation = modulationID, --AM == 0, FM == 1
                unitId = unitId, --Obtained by Unit.getByName(<unitname>):getID()
                power = 10,
                frequency = frequency * 1000000, --Freq 305000000
                }
            }
end
--------------------------
--------------------------
function NewMission()
    return { 
    id = 'Mission', 
    params = {
      airborne = false,
      route = { 
        points = {},
        }
    }
    }
end
--------------------------
--------------------------
function NewWayPoint(vec2, alt, speed)
    return {
    ["alt"] = alt,
    ["action"] = "Fly Over Point",
    ["alt_type"] = "BARO",
    ["speed"] = speed,
    ["task"] = 
    {
        ["id"] = "ComboTask",
        ["params"] = 
        {
            ["tasks"] = 
            {
            }, -- end of ["tasks"]
        }, -- end of ["params"]
    }, -- end of ["task"]
    ["type"] = "Turning Point",
    ["ETA"] = 0,
    ["ETA_locked"] = true,
    ["y"] = vec2.y,
    ["x"] = vec2.x,
    ["formation_template"] = "",
    ["speed_locked"] = true,
    } -- end of BLANK_WAYPOINT
end
--------------------------
--------------------------
function New_ORBIT_TASKS(pattern, alt, speed, orbitpos, orbitpos2)
    local tmptbl =  {
        [1] = 
        {
            ["id"] = "WrappedAction",
            ["params"] = {
                ["action"] = {
                    ["id"] = "Script",
                    ["params"] = {
                        ["command"] = ""
                    }
                }
            } -- end of ["params"]
        }, -- end of [1]
        [2] = 
        {
            ["number"] = 1,
            ["auto"] = false,
            ["id"] = "Orbit",
            ["enabled"] = true,
            ["params"] = 
            {
                ["altitude"] = alt,
                ["pattern"] = pattern,
                ["point"] = {x = orbitpos.x, y = orbitpos.y},
                ["speed"] = speed,
                ["speedEdited"] = false,
            }, -- end of ["params"]
        }, -- end of [2]
    } -- end of ORBIT_ARRIVAL_TASKS
    if(pattern == "Race-Track") then
        if(type(orbitpos2) ~= 'nil') then
            tmptbl[2].params.point2 = {x = orbitpos2.x , y = orbitpos2.y}
        end
    end
    return tmptbl
end
--------------------------
--------------------------
function New_FAC_TASKS(laserCode, frequency, modulation, callnameID, SetInvisible, SetImmortal)
    local frequencyHZ = frequency * 1000000
    return { --Designed for First Waypoint
        [1] = 
        {
            ["number"] = 1,
            ["auto"] = true,
            ["id"] = "FAC",
            ["enabled"] = true,
            ["params"] = {}, -- end of ["params"]
        }, -- end of [2]
        [2] = 
        {
            ["number"] = 2,
            ["auto"] = true,
            ["id"] = "FAC_EngageGroup",
            ["enabled"] = true,
            ["params"] = 
            {
                ["priority"] = 0,
                ["designation"] = "Laser",
                ["visible"] = true,
                ["modulation"] = modulation,
                ["callname"] = callnameID,
                ["datalink"] = true,
                ["laserCode"] = laserCode,
                ["weaponType"] = 0,
                ["frequency"] = frequencyHZ,
            }, -- end of ["params"]
        }, -- end of [2]
        [3] = 
        {
            ["number"] = 3,
            ["auto"] = true,
            ["id"] = "WrappedAction",
            ["enabled"] = true,
            ["params"] = 
            {
                ["action"] = 
                {
                    ["id"] = "EPLRS",
                    ["params"] = 
                    {
                        ["value"] = true,
                        ["groupId"] = 0,
                    }, -- end of ["params"]
                }, -- end of ["action"]
            }, -- end of ["params"]
        }, -- end of [3]
        [4] = 
        {
            ["number"] = 4,
            ["auto"] = true,
            ["id"] = "WrappedAction",
            ["enabled"] = true,
            ["params"] = 
            {
                ["action"] = 
                {
                    ["id"] = "Option",
                    ["params"] = 
                    {
                        ["value"] = 0,
                        ["name"] = 1,
                    }, -- end of ["params"]
                }, -- end of ["action"]
            }, -- end of ["params"]
        }, -- end of [4]
        [5] = 
        {
            ["number"] = 5,
            ["auto"] = true,
            ["id"] = "WrappedAction",
            ["enabled"] = true,
            ["params"] = 
            {
                ["action"] = 
                {
                    ["id"] = "SetInvisible",
                    ["params"] = 
                    {
                        ["value"] = SetInvisible,
                    }, -- end of ["params"]
                }, -- end of ["action"]
            }, -- end of ["params"]
        }, -- end of [5]
        [6] = 
        {
            ["number"] = 6,
            ["auto"] = true,
            ["id"] = "WrappedAction",
            ["enabled"] = true,
            ["params"] = 
            {
                ["action"] = 
                {
                    ["id"] = "SetImmortal",
                    ["params"] = 
                    {
                        ["value"] = SetImmortal,
                    }, -- end of ["params"]
                }, -- end of ["action"]
            }, -- end of ["params"]
        }, -- end of [6]
    } -- end of ["tasks"]
end
--------------------------
--------------------------
function New_TANKER_TASKS(SetInvisible, SetImmortal)
    return {
            [1] = 
                {
                    ["enabled"] = true,
                    ["auto"] = false,
                    ["id"] = "Tanker",
                    ["number"] = 1,
                    ["params"] = 
                    {
                    }, -- end of ["params"]
                }, -- end of [1]
            [2] = 
                {
                    ["number"] = 5,
                    ["auto"] = true,
                    ["id"] = "WrappedAction",
                    ["enabled"] = true,
                    ["params"] = 
                    {
                        ["action"] = 
                        {
                            ["id"] = "SetInvisible",
                            ["params"] = 
                            {
                                ["value"] = SetInvisible,
                            }, -- end of ["params"]
                        }, -- end of ["action"]
                    }, -- end of ["params"]
                }, -- end of [2]
            [3] = 
                {
                    ["number"] = 6,
                    ["auto"] = true,
                    ["id"] = "WrappedAction",
                    ["enabled"] = true,
                    ["params"] = 
                    {
                        ["action"] = 
                        {
                            ["id"] = "SetImmortal",
                            ["params"] = 
                            {
                                ["value"] = SetImmortal,
                            }, -- end of ["params"]
                        }, -- end of ["action"]
                    }, -- end of ["params"]
                }, -- end of [3]
            } -- end of ["tasks"]
end
--------------------------
--------------------------
function New_AWACS_TASKS(SetInvisible, SetImmortal)
    return {
            [1] = 
                {
                    ["enabled"] = true,
                    ["auto"] = false,
                    ["id"] = "AWACS",
                    ["number"] = 1,
                    ["params"] = 
                    {
                    }, -- end of ["params"]
                }, -- end of [1]
            [2] = 
                {
                    ["number"] = 2,
                    ["auto"] = true,
                    ["id"] = "WrappedAction",
                    ["enabled"] = true,
                    ["params"] = 
                    {
                        ["action"] = 
                        {
                            ["id"] = "SetInvisible",
                            ["params"] = 
                            {
                                ["value"] = SetInvisible,
                            }, -- end of ["params"]
                        }, -- end of ["action"]
                    }, -- end of ["params"]
                }, -- end of [2]
            [3] = 
                {
                    ["number"] = 3,
                    ["auto"] = true,
                    ["id"] = "WrappedAction",
                    ["enabled"] = true,
                    ["params"] = 
                    {
                        ["action"] = 
                        {
                            ["id"] = "SetImmortal",
                            ["params"] = 
                            {
                                ["value"] = SetImmortal,
                            }, -- end of ["params"]
                        }, -- end of ["action"]
                    }, -- end of ["params"]
                }, -- end of [3]
            [4] = 
                {
                    ["number"] = 4,
                    ["auto"] = true,
                    ["id"] = "WrappedAction",
                    ["enabled"] = true,
                    ["params"] = 
                    {
                        ["action"] = 
                        {
                            ["id"] = "EPLRS",
                            ["params"] = 
                            {
                                ["value"] = true,
                                ["groupId"] = -1,
                            }, -- end of ["params"]
                        }, -- end of ["action"]
                    }, -- end of ["params"]
                },  -- end of [4]
            } -- end of ["tasks"]
end