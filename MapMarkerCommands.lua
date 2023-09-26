EXTERNAL_LUA = (lfs.writedir().."\\Missions\\OzDM-MMC\\")
assert(loadfile(EXTERNAL_LUA .. "MISSION_TASK_TEMPLATES.lua"))()
JSON = assert(loadfile(EXTERNAL_LUA .. "json.lua"))()
--[[
    Name    : MapMarkerCommands.lua
    Author  : OzDeaDMeaT
    Date    : 16/08/2023
    Version : 0.2o]]
    scriptVer = '0.2o'
--[[
    This script is designed as a quick way to add the ability to order tankers, AWACS and Drones around the airspace quickly and easily with little to no LUA experience.
    Current Functionality:
        - Customizable Command Prefix (Do not use a `-` or a `:` )

        - CoOrd Command (!coord)            : Prints the MGRS and Lat Long for a point on the map. All coord commands will display altitude in both meters and ft.
            -- Example> !coord:all              : (Returns all CoOrd types)
            -- Example> !coord:grid             : (Returns MGRS Grid)
            -- Example> !coord:mgrs             : (Returns MGRS)
            -- Example> !coord:LL               : (Returns both types of LL) 
            -- Example> !coord:DM               : (Returns LLDM)
            -- Example> !coord:DMS              : (Returns LLDMS)

        - Smoke Command (!smoke)                : Drops smoke at the marker location
            -- Example> !smoke:red              
            -- Example> !smoke:white
            -- Example> !smoke:blue
            -- Example> !smoke:orange
            -- Example> !smoke:green

        - Flare Command (!flare)                : Drops a flare at the marker location
            -- Example> !flare:red
            -- Example> !flare:white
            -- Example> !flare:green
            -- Example> !flare:orange
        
        - Illum Command (!illum)                : Drops a illum flare at the marker location
            -- Example> !illum:5000
        
        - Clean Command (!clean)                : Removes wrecks (units) and craters from an area around the marker location (Argument value is the radius in meters)
            -- Example> !clean:1000             : Cleans a location with an area of 1000m radius

        - ISR Command (!isr)                    : Draws an orbit box and orders the Drone to orbit at a marker location
            -- Example> !isr:Pontiac11          [press "ENTER" after the aircraft name to go to next line]
                        -a20000 -s250 -rt 180-5 [This example will select Pontiac11 and order them to move to the new location and change altitude to 20000ft and 250knts with a race track orbit to the south with a leg length of 5km]
            -- Example> !isr:Chevy11            [press "ENTER" after the aircraft name to go to next line]
                        -a15000 -s130           [This example will select Chevy11 and order them to move to the new location and change altitude to 15000ft and 130knts with a circular orbit]
            -- Example> !isr:Uzi11              [This example will select Uzi11 and order them to move to the new location and use a circular orbit, altitude and speed settings
            -- Example> !isr:Colt11             [press "ENTER" after the aircraft name to go to next line]
                        -a15000 -s130 -dm       [This example will select Colt11 and order them to change altitude and speed settings without moving to a new location

        - TANKER Command (!tanker)              : Same options as isr

        - AWACS Command (!awacs)                : Same options as isr

        - Mark Command (!mark)                  : Marks an object on the F10 map. (Scenery Objects, not trees or bushes etc. Only buildings, lights etc)
            -- Example> !mark                   
            
        - Explode Command (!smite)             : Causes an explosion at the marker location
            -- Example> !smite:250
]]
Terrain      = require('terrain') --REQUIRED FOR function:MarkTerrainObject 

-------------------SCRIPT SETTINGS HERE
OzDM = {
    COMMAND_PREFIX  = '!'       ,   -- Command Prefix, all commands must have this symbol at the start to be registered as command requests
    MarkID          =  666666   ,   -- For Terrain Marking
    DEBUG           = true		,	-- SET to false to reduce logging
    SHOW_ORBIT      = true      ,   -- Will mark approximate orbit with a map marker
    SHOW_ORBIT_NAME = true      ,   -- Will not display if SHOW_ORBIT is not enabled. Will mark orbit marker with the callsign of the commanded unit    
    ENABLE_COORD    = true      ,   -- Enables the COORD command
    ENABLE_SMOKE    = true      ,   -- Enables the smoke command
    ENABLE_FLARE    = true      ,   -- Enables the flare command
    ENABLE_ILLUM    = true      ,   -- Enables the illum command
    ENABLE_CLEAN    = true      ,   -- Enables the clean command
    ENABLE_ISR      = true      ,   -- Enables the ISR command
    ENABLE_AWACS    = true      ,   -- Enables the AWACS command
    ENABLE_TANKER   = true      ,   -- Enables the TANKER command
    ENABLE_MARK     = true      ,   -- Enables the MARK command
    ENABLE_EXPLOSION= true      ,   -- Enables the explosion command
    ILLUM_LIMIT     = 1000000   ,   -- Maximum brightness level of an illumination flare
    EXPLOSION_LIMIT = 9000      ,   -- Maximum value for explosions command, and value higher will default to this number
    CLEAN_LIMIT     = 5000      ,   -- Maximum value for clean command, and value higher will default to this number
    DEFAULT_SMOKE   = "white"   ,   -- Default colour of smoke if no colour is requested
    DEFAULT_FLARE   = "white"   ,   -- Default colour of flare if no colour is requested
    DEFAULT_ISR     = false     ,   -- Default UAV if no ISR asset is given (SET TO FALSE if you don't want an ISR Default) NOTE: Any incorrect spelling of unit will mean this Default unit will be retasked. Recommend using this setting only when you have a single UAV unit in mission
    EH = {}                         -- Table place holder for all Event Handlers
    }

-------------------AIR SUPPORT TABLE
Air_Support_Table = {}
ISR_SETTINGS = {    --All entries are knots and ft
    minspeed = 75,      
    maxspeed = 240,
    minalt   = 5000,
    maxalt   = 14000
    }
TNK_SETTINGS = {    --All entries are knots and ft
    minspeed = 210,
    maxspeed = 400,
    minalt   = 15000,
    maxalt   = 24000
    }
AWC_SETTINGS = {    --All entries are knots and ft
    minspeed = 210,
    maxspeed = 400,
    minalt   = 25000,
    maxalt   = 30000
    }
-------------------
Uzi11 = {
    id = 200000,
    NameID = 210000,
    FontSize = 25,
    LaserCode = 1666,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 333.5,
    TACAN = {
            CALLSIGN = "",
            MODECHANNEL = nil,
            CHANNEL = nil,
            AA = false,
            },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a}
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 3048,          -- 3048m (Approx:10,000ft)
        speed = 75,          -- 75mps (Approx:145kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2 (ALWAYS CURRENT AIRCRAFT LOCATION)
            x = 0,
            y = 0
            },
        WP02 = {    --vec2 (ORBIT START)
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Chevy11 = {
    id = 220000,
    NameID = 230000,
    FontSize = 25,
    LaserCode = 1555,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 369,
    TACAN = {
        CALLSIGN = "",
        MODECHANNEL = nil,
        CHANNEL = nil,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a}
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 3048,          -- 3048m (Approx:10,000ft)
        speed = 75,          -- 75mps (Approx:145kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Pontiac11 = {
    id = 240000,
    NameID = 250000,
    FontSize = 25,
    LaserCode = 1788,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 333.5,
    TACAN = {
        CALLSIGN = "",
        MODECHANNEL = nil,
        CHANNEL = nil,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 3048,          -- 3048m (Approx:10,000ft)
        speed = 75,          -- 75mps (Approx:145kt)
        speed_transit = 130, -- 130mps (Approx:245kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Colt11 = {
    id = 260000,
    NameID = 270000,
    FontSize = 25,
    LaserCode = 1588,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 305.5,
    TACAN = {
        CALLSIGN = "",
        MODECHANNEL = nil,
        CHANNEL = nil,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 3048,          -- 3048m (Approx:10,000ft)
        speed = 75,          -- 75mps (Approx:145kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Colt21 = {
    id = 280000,
    NameID = 290000,
    FontSize = 25,
    LaserCode = 1438,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 303.65,
    TACAN = {
        CALLSIGN = "",
        MODECHANNEL = nil,
        CHANNEL = nil,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 3048,          -- 3048m (Approx:10,000ft)
        speed = 75,          -- 75mps (Approx:145kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Texaco11 = {
    id = 300000,
    NameID = 310000,
    FontSize = 25,
    LaserCode = nil,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 325,
    TACAN = {
        CALLSIGN = "TEX",
        MODECHANNEL = "X",
        CHANNEL = 65,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 6705.6,          -- 3048m (Approx:20,000ft)
        speed = 165,          -- 165mps (Approx:320kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Texaco21 = {
    id = 320000,
    NameID = 330000,
    FontSize = 25,
    LaserCode = nil,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 326,
    TACAN = {
        CALLSIGN = "TEX",
        MODECHANNEL = "X",
        CHANNEL = 66,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 6705.6,          -- 3048m (Approx:20,000ft)
        speed = 165,          -- 165mps (Approx:320kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Arco11 = {
    id = 340000,
    NameID = 350000,
    FontSize = 25,
    LaserCode = nil,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 327,
    TACAN = {
        CALLSIGN = "ARC",
        MODECHANNEL = "X",
        CHANNEL = 75,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 5486.4,          -- 3048m (Approx:20,000ft)
        speed = 165,          -- 165mps (Approx:320kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Shell11 = {
    id = 350000,
    NameID = 360000,
    FontSize = 25,
    LaserCode = nil,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 328,
    TACAN = {
        CALLSIGN = "SHL",
        MODECHANNEL = "X",
        CHANNEL = 70,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 6096,          -- 6096m (Approx:20,000ft)
        speed = 165,          -- 165mps (Approx:320kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
Darkstar11 = {
    id = 370000,
    NameID = 380000,
    FontSize = 25,
    LaserCode = nil,
    FreqMode = 0, --AM == 0, FM == 1
    Freq = 345.5,
    TACAN = {
        CALLSIGN = "DKS",
        MODECHANNEL = "X",
        CHANNEL = 72,
        AA = false,
        },
    FUEL = 525, --2,440 MQ-9 : 525L MQ-1
    Invisible = true,
    Immortal = true,
    Ready4Tasking = false,
    LineColourArray = {0.1, 0.1, 0.1, 1}, -- Line {r, g, b, a} 
    FillColourArray = {0.1, 0.1, 0.1, 0.15}, -- Fill {r, g, b, a} 
    LineType = 5, -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
    LastOrder = {
        alt = 8382,          -- 3048m (Approx:20,000ft)
        speed = 165,          -- 165mps (Approx:320kt)
        RT = false,
        RT_Bearing = 0,
        RT_Distance = 0,
        WP01 = {    --vec2
            x = 0,
            y = 0
            },
        WP02 = {    --vec2
            x = 0,
            y = 0
            },
        WP03 = {    --vec2 (RT ORBIT WP)
            x = 0,
            y = 0
            }
        }
    }
-------------------
Air_Support_Table.Uzi11 = Uzi11
Air_Support_Table.Chevy11 = Chevy11
Air_Support_Table.Pontiac11 = Pontiac11
Air_Support_Table.Colt11 = Colt11
Air_Support_Table.Colt21 = Colt21
Air_Support_Table.Texaco11 = Texaco11
Air_Support_Table.Texaco21 = Texaco21
Air_Support_Table.Arco11 = Arco11
Air_Support_Table.Shell11 = Shell11
Air_Support_Table.Darkstar11 = Darkstar11
--Functions-------------------------------------------------------------------------------------------------------------------------
--Feet to Meters Converter
function ft2m(value) -- Feet to Meters
    return value / 3.2808
end
-------------------
--Meters to Feet Converter
function m2ft(value) -- Feet to Meters
    return value / 0.3048000097536
end
-------------------
--Nautical Miles to Meters Converter
function nm2m(value) -- Nautical Miles to Meters
    return value * 1852
end
-------------------
--Meters to Nautical Miles Converter
function m2nm(value) -- Nautical Miles to Meters
    return value * 0.00053995682073434123939
end
-------------------
--Knots to Meters Per Second Converter
function kt2mps(value) -- Knots to Meters / Second
    return value * 0.514444
end
-------------------
--Meters Per Second to Knots Converter
function mps2kt(value)
    return value * 1.94384
end
-------------------
function StringSplit(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in string.gmatch(str,regex) do
      table.insert(result, each)
    end
    return result
end
-------------------
function IsInteger(n)
    return n==math.floor(n)
end
-------------------
function StringPad(str, len, char)
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end
-------------------
function math.round(num, numDecimalPlaces)--[[
Borrowed from http://lua-users.org/wiki/SimpleRound]]
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end
-------------------
function TACANToFrequency(TACANChannel, TACANMode)
    if type(TACANChannel) ~= "number" then
      return nil -- error in arguments
    end
    if TACANMode ~= "X" and TACANMode ~= "Y" then
      return nil -- error in arguments
    end
  
  -- This code is largely based on ED's code, in DCS World\Scripts\World\Radio\BeaconTypes.lua, line 137.
  -- I have no idea what it does but it seems to work
    local A = 1151 -- 'X', channel >= 64
    local B = 64   -- channel >= 64
  
    if TACANChannel < 64 then
      B = 1
    end
  
    if TACANMode == 'Y' then
      A = 1025
      if TACANChannel < 64 then
        A = 1088
      end
    else -- 'X'
      if TACANChannel < 64 then
        A = 962
      end
    end
    return (A + TACANChannel - B) * 1000000
end
-------------------
function IsUnit(UnitName)--[[
This function returns true or false if a unit exists or not
Author       : OzDeaDMeaT
Creation Date: 5-AUG-2023
Usage        : IsUnit(string)
Return       : bool]]
    local RTN = false
    if(type(UnitName) == 'string') then
        local UnitVAR  = Unit.getByName(UnitName)
        if(type(UnitVAR) == 'table') then
            if(UnitVAR:isActive()) then 
                RTN = true
            else
                if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! IsUnit : UnitName is NOT active in the simulation") end     
            end
        else
            if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! IsUnit : UnitName is NOT a table value, it is a " .. type(UnitVAR) .. " variable") end     
        end
    else 
        if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! IsUnit : UnitName was passed to function and was NOT a string value") end      
    end
    return RTN
end
-------------------
function IsGroup(AircraftGroupName)--[[
This function returns true or false if a group exists or not
Author       : OzDeaDMeaT
Creation Date: 5-AUG-2023
Usage        : IsGroup(string)
Return       : bool]]
    local RTN = false
    if(type(AircraftGroupName) == 'string') then
        local GroupVar  = Group.getByName(AircraftGroupName)
        if(type(GroupVar) == 'table') then
            RTN = true
        end
    else 
        if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! IsGroup : AircraftGroupName was passed to function and was not a string value") end      
    end
    return RTN
end
-------------------
function GetCallsignID(UnitName)--[[
This function returns the Callsign ID numberfor the specific aircraft callsign
Author       : OzDeaDMeaT
Creation Date: 6-AUG-2023
Usage        : GetCallsignID(string)
Example      : GetCallsignID("Uzi11")
Return       : number]]
    local Proceed = false
    if(IsUnit(UnitName) == true) then
        Proceed = true
    end
    if (Proceed == true) then
        local CallsignString = Unit.getByName(UnitName):getCallsign()
        local CALLSIGN = {
                Enfield = 1,
                Springfield = 2,
                Uzi = 3,
                Colt = 4,
                Dodge = 5,
                Ford = 6,
                Chevy = 7,
                Pontiac = 8,
                Hawg = 9,
                Boar = 10,
                Pig = 11,
                Tusk = 12,
                Overlord = 1,
                Magic = 2,
                Wizard = 3,
                Focus = 4,
                Darkstar = 5,
                Texaco = 1,
                Arco = 2,
                Shell = 3,
                Axeman = 1,
                Darknight = 2,
                Warrior = 3,
                Pointer = 4,
                Eyeball = 5,
                Moonbeam = 6,
                Whiplash = 7,
                Finger = 8,
                Pinpoint = 9,
                Ferret = 10,
                Shaba = 11,
                Playboy = 12,
                Hammer = 13,
                Jaguar = 14,
                Deathstar = 15,
                Anvil = 16,
                Firefly = 17,
                Mantis = 18,
                Badger = 19,
                London = 1,
                Dallas = 2,
                Paris = 3,
                Moscow = 4,
                Berlin = 5,
                Rome = 6,
                Madrid = 7,
                Warsaw = 8,
                Dublin = 9,
                Perth = 10,
                Viper = 9,
                Venom = 10,
                Lobo = 11,
                Cowboy = 12,
                Python = 13,
                Rattler = 14,
                Panther = 15,
                Wolf = 16,
                Weasel = 17,
                Wild = 18,
                Ninja = 19,
                Jedi = 20,
                Hornet = 9,
                Squid = 10,
                Ragin = 11,
                Roman = 12,
                Sting = 13,
                Jury = 14,
                Jokey = 15,
                Ram = 16,
                Hawk = 17,
                Devil = 18,
                Check = 19,
                Snake = 20,
                Dude = 9,
                Thud = 10,
                Gunny = 11,
                Trek = 12,
                Sniper = 13,
                Sled = 14,
                Best = 15,
                Jazz = 16,
                Rage = 17,
                Tahoe = 18,
                Bone = 9,
                Dark = 10,
                Vader = 11,
                Buff = 9,
                Dump = 10,
                Kenworth = 11,
                Heavy = 9,
                Trash = 10,
                Cargo = 11,
                Ascot = 12,
            }
        regex = string.match(CallsignString,'%a+')
        CallsignCheck = CALLSIGN[regex]
        if(type(CallsignCheck) == 'number') then 
            return CallsignCheck
        end
    end
end
-------------------
function file_exists(path)
    -- Return true if file exists and is readable.
        local file = io.open(path, "rb")
        if file then file:close() end
        return file ~= nil
    end
-------------------
function readall(filename)
-- Read an entire file.
-- Use "a" in Lua 5.3; "*a" in Lua 5.1 and 5.2    
    local fh = assert(io.open(filename, "rb"))
    local contents = assert(fh:read(_VERSION <= "Lua 5.2" and "*a" or "a"))
    fh:close()
    return contents
end
-------------------
function write(filename, contents)
-- Write a string to a file.
    local fh = assert(io.open(filename, "wb"))
    fh:write(contents)
    fh:flush()
    fh:close()
end
-------------------
if(file_exists(EXTERNAL_LUA .. "MAP_OBJECT_TABLE.json")) then
    MOT = JSON:decode(readall(EXTERNAL_LUA .. "MAP_OBJECT_TABLE.json"))
else
    MOT = {}
end
-------------------
function CheckLaserCode(LaserCode)--[[
This function checks if a LaserCode that is supplied as a number is a valid laser code.
Author       : OzDeaDMeaT
Creation Date: 6-AUG-2023
Usage        : CheckLaserCode(number)
Example      : CheckLaserCode(1788)
Return       : true or false]]
    local RTN           = false
    local minLaserCode  = 1111
    local maxLaserCode  = 2688
    local StringCheck   = nil
    local LaserCodeSTR  = tostring(LaserCode)
    if(type(LaserCode) == 'number') then
        if(LaserCode >= minLaserCode and LaserCode <=2688) then
            StringCheck = string.match(LaserCodeSTR,'[1-2][1-8][1-8][1-8]')
            if(type(StringCheck) ~= 'nil') then 
                RTN = true
                if(OzDM.DEBUG == true) then env.info("CheckLaserCode : " .. StringCheck .. " is a valid Laser Code") end
            else
                if(OzDM.DEBUG == true) then env.info("CheckLaserCode : " .. LaserCodeSTR .. " is NOT valid Laser Code") end
            end    
        else
            if(OzDM.DEBUG == true) then env.info("CheckLaserCode : " .. LaserCodeSTR .. " is NOT valid Laser Code") end
        end
    else
        if(OzDM.DEBUG == true) then env.info("CheckLaserCode : The lasercode was not supplied as a number") end
    end
    return RTN
end
-------------------
function SetUnitTACAN(UnitName  , callsign  , modeChannel   , channel   , AA    )--[[
This function sets a units returns true or false if a group exists or not
Author       : OzDeaDMeaT
Creation Date: 29-JUL-2023
Usage        : SetUnitBEACON(string, number, number)
Example      : SetUnitBEACON("Arco11","ARC",  "Y", 64 , false)  Use False for AA as it seems buggy
Return       : nothing]]
    --lifted from MOOSE and ED
    local RunCommand    = false --If All checks are correct, proceed to run the command
    local sys
    local BEACON = {}
    BEACON.System={
        TACAN             = 3,
        TACAN_TANKER_X    = 4,
        TACAN_TANKER_Y    = 5,
        TACAN_AA_MODE_X   = 13,
        TACAN_AA_MODE_Y   = 14
      }
    BEACON.Type={
        TACAN                     = 4
      }

    if(IsUnit(UnitName) == true) then 
        if(OzDM.DEBUG == true) then env.info("SetUnitTACAN : " .. UnitName .. " exists!") end
        if(type(callsign) == 'string' and type(modeChannel) == 'string' and type(channel) == 'number' and type(AA) == 'boolean') then
            RunCommand = true
        else
            if(OzDM.DEBUG == true and type(callsign) ~= 'string') then env.info("SetUnitTACAN : callsign variable not a string, currently variable is a " .. type(callsign)) end
            if(OzDM.DEBUG == true and type(modeChannel) ~= 'string') then env.info("SetUnitTACAN : modeChannel variable not a string, currently variable is a " .. type(modeChannel)) end
            if(OzDM.DEBUG == true and type(channel) ~= 'number') then env.info("SetUnitTACAN : freq variable not a number, currently variable is a " .. type(channel)) end
            if(OzDM.DEBUG == true and type(AA) ~= 'boolean') then env.info("SetUnitTACAN : AA variable not a bool, currently variable is a " .. type(AA)) end
        end
    else
        if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! SetUnitTACAN : UnitName was passed to function and was not a valid value") end      
    end
    if(RunCommand == true) then
        if(OzDM.DEBUG == true) then env.info("SetUnitTACAN : All Argument Variables checked and OK, proceeding to run command") end      
        if AA then
            sys = 5 --NOTE: 5 is how you cat the correct tanker behaviour! --BEACON.System.TACAN_TANKER
                -- Check if "Y" mode is selected for aircraft.
            if modeChannel:lower()=="x" then
                --self:E({"WARNING: The POSITIONABLE you want to attach the AA Tacan Beacon is an aircraft: Mode should Y!", self.Positionable})
                sys = BEACON.System.TACAN_AA_MODE_X
            else
                sys = BEACON.System.TACAN_AA_MODE_Y 
            end
        else
            if modeChannel:lower()=="x" then
                --self:E({"WARNING: The POSITIONABLE you want to attach the AA Tacan Beacon is an aircraft: Mode should Y!", self.Positionable})
                sys = BEACON.System.TACAN_TANKER_X
            else
                sys = BEACON.System.TACAN_TANKER_Y 
            end
        end
        local UnitVAR = Unit.getByName(UnitName)
        local Cntrl = UnitVAR:getController()
        local BEACONON = ACTIVATE_TACAN(BEACON.Type.TACAN, AA, callsign, modeChannel, channel, sys, UnitVAR:getID(), TACANToFrequency(channel, modeChannel))
        Cntrl:setCommand(BEACONON)
    end
end
-------------------
function SetUnitRadioFrequency(UnitName, Frequency, Modulation)--[[
This function sets a units returns true or false if a group exists or not
Author       : OzDeaDMeaT
Creation Date: 29-JUL-2023
Usage        : SetUnitRadioFrequency(string, number, number)
Example      : SetUnitRadioFrequency("Uzi11", 305, 0)  Modulation = 0 for AM, 1 for FM
SetUnitRadioFrequency("Arco11", 315, 0)
Return       : nothing]]
    local RunCommand    = false --If All checks are correct, proceed to run the command
    --local Mod = Modulation
    if(IsUnit(UnitName) == true) then 
        if(type(Frequency) == 'number') then
            RunCommand = true
            if(type(Modulation) == 'number') then
                if(Modulation < 0 or Modulation > 1) then --DEFAULTING TO AM if incorrect number set (Modulation = 0 for AM, 1 for FM)
                    Modulation = 0
                end
            else
                Modulation = 0 --use AM as Default
                if(OzDM.DEBUG == true) then env.info("SetUnitRadioFrequency : Modulation Default 'AM' being used as no value was passed") end      
            end
        else
            if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! SetUnitRadioFrequency : Frequency was passed to function and was not a number value") end      
        end
    else
        if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! SetUnitRadioFrequency : UnitName was passed to function and was not a valid value") end      
    end
    if(RunCommand == true) then
        if(OzDM.DEBUG == true) then env.info("SetUnitRadioFrequency : All Argument Variables checked and OK, proceeding to run command") end      
        local UnitVAR = Unit.getByName(UnitName)
        local SF = PrepUnitFrequencyChange(UnitVAR:getID(), Frequency, Modulation)
        local Cntrl = UnitVAR:getController()
        Cntrl:setCommand(SF)
        --local FrequencyHz = Frequency * 1000000
        --SF.params.unitId = UnitVAR:getID()
        --SF.params.frequency = FrequencyHz
        --SF.params.modulation = Modulation
    end
end
---------------
function MapObjectTable(MapObject) --!mot
--  Author       : OzDeaDMeaT
--  Creation Date: 20-SEP-2023
--  Usage        : MapObjectTable(EventData) --Designed to be used with Map Marker Remove EventHandler
--  Returns      : Will drop building information from map object to a file
    local MOT_NewEntry = #MOT + 1
    MOT[MOT_NewEntry] = MapObject
    local converted = JSON:encode_pretty(MOT)
    write(EXTERNAL_LUA .. "MAP_OBJECT_TABLE.json", converted)
end
---------------
function MarkTerrainObject(EventData,MOT) --MOT is bool on whether map item is recorded to MAP_OBJECT_TABLE.json
--Author       : OzDeaDMeaT
--Creation Date: 2-AUG-2023
--Usage        : MarkTerrainObject(vec3)
--Returns      : nothing
--Marks objects on the F10 map in the Mission Scripting Environment
    local vec3 = EventData.pos
    env.info("Marking position: {x = " .. vec3.x .. " , y = " .. vec3.y .. " , z = " .. vec3.z)
    objects = Terrain.getObjectsAtMapPoint(vec3.x, vec3.z)
    if(type(objects) ~= "nil") then
        local a_object = objects[1]
        local radius = a_object.radius
        local sinRot = math.sin(-a_object.rotation) 
        local cosRot = math.cos(-a_object.rotation) 
        local dx = a_object.sizeOBB[1] / 2
        local dy = a_object.sizeOBB[2] / 2
        local PolyPoints = {
            [1] = {x = -dx*cosRot-(-dy*sinRot), y= 0, z = -dx*sinRot+(-dy*cosRot)},
            [2] = {x = dx*cosRot-(-dy*sinRot), y= 0, z = dx*sinRot+(-dy*cosRot)},
            [3] = {x = dx*cosRot-(dy*sinRot), y= 0, z = dx*sinRot+(dy*cosRot)},
            [4] = {x = -dx*cosRot-(dy*sinRot), y= 0, z = -dx*sinRot+(dy*cosRot)}
        }
        local GlobalPoints = {
            [1] = {x = (a_object.center[1] + PolyPoints[1].x), y = 0, z = (a_object.center[2] + PolyPoints[1].z)},
            [2] = {x = (a_object.center[1] + PolyPoints[2].x), y = 0, z = (a_object.center[2] + PolyPoints[2].z)},
            [3] = {x = (a_object.center[1] + PolyPoints[3].x), y = 0, z = (a_object.center[2] + PolyPoints[3].z)},
            [4] = {x = (a_object.center[1] + PolyPoints[4].x), y = 0, z = (a_object.center[2] + PolyPoints[4].z)}
        }
        local LineColourArray = {0, 0, 0, 1} -- Line {r, g, b, a} 
        local FillColourArray = {0.75, 0.1, 0.1, 0.25} -- Fill {r, g, b, a}
        local LineType = 1 -- 0  No Line    1  Solid    2  Dashed    3  Dotted    4  Dot Dash    5  Long Dash    6  Two Dash
        OzDM.MarkID = OzDM.MarkID + 1
        trigger.action.markupToAll(7, -1 , OzDM.MarkID , GlobalPoints[1] , GlobalPoints[2] , GlobalPoints[3] , GlobalPoints[4] , LineColourArray , FillColourArray , LineType , true, tostring(a_object.model))
        if(MOT) then
            a_object.GlobalPoints = GlobalPoints
            MapObjectTable(a_object)
        end
    else
        trigger.action.outText(
            "No object found under marker!",
            3,
            false)
    end
end
-------------------
function GetFreeMarkerID(StartHere)--[[
Author       : OzDeaDMeaT
Creation Date: 2-AUG-2023
Usage        : GetFreeMarkerID()
Returns      : number [Will return a that has not been allocated in the MarkerPanels table]]
    if(type(StartHere) == nil) then StartHere = 2000000 end
    local MarkerCheck = -1
    StartHere = StartHere + 1
    local AllMarkers = world.getMarkPanels()
    if(#AllMarkers == 0) then MarkerCheck = StartHere end
    for k,v in ipairs(AllMarkers) do
        if (AllMarkers[k].idx == StartHere) then 
            StartHere = StartHere + 1
        else
            MarkerCheck = StartHere --return index in table the number was found (should be greater than 0)
            break
        end
    end
    return MarkerCheck
end
-------------------
function formatGRID(vec3)--[[
Author       : OzDeaDMeaT
Creation Date: 29-JUL-2023
Usage        : formatGRID(vec3)
Purpose      : Formats an MGRS GRID Table into a user readable string]]
    local LLTBL = {}
    LLTBL.lat, LLTBL.lon, LLTBL.alt = coord.LOtoLL(vec3)
    local MRGSTBL = coord.LLtoMGRS(LLTBL.lat, LLTBL.lon)
    local Digraph = MRGSTBL.MGRSDigraph
    local Easting = MRGSTBL.Easting / 10000
    local Northing = MRGSTBL.Northing / 10000
    local EastingString = string.sub(tostring(Easting),1,1)
    local NorthingString = string.sub(tostring(Northing),1,1)
    local GRID = tostring(Digraph .. EastingString .. NorthingString)
    return GRID
end
-------------------
function formatMGRS(vec3)--[[
Author       : OzDeaDMeaT
Creation Date: 29-JUL-2023
Usage        : formatMGRS(vec3)
Purpose      : Formats an MGRS Table into a user readable string]]
    local LLTBL = {}
    LLTBL.lat, LLTBL.lon, LLTBL.alt = coord.LOtoLL(vec3)
    local MRGSTBL = coord.LLtoMGRS(LLTBL.lat, LLTBL.lon)
    local UTMZone = MRGSTBL.UTMZone
    local Digraph = MRGSTBL.MGRSDigraph
    local Easting = MRGSTBL.Easting
    local Northing = MRGSTBL.Northing
    local EastingString = tostring(Easting)
    local NorthingString = tostring(Northing)
    local MGRS = tostring(UTMZone .. " " .. Digraph .. " " .. StringPad(EastingString, 5, "0") .. " " .. StringPad(NorthingString, 5, "0"))
    return MGRS
end
-------------------
function formatLL(vec3,acc,DMS)--[[
Author       : OzDeaDMeaT
Creation Date: 29-JUL-2023
Usage        : formatLL(vec3, number, bool)
Example:     : formatLL(vec3, 2, true)
Return:      : string - e.g. ""
Purpose      : Formats an LL Table into a user readable string
Code borrowed from Mist https://github.com/mrSkortch/MissionScriptingTools]]
    local lat, lon, alt = coord.LOtoLL(vec3)
    local latHemi, lonHemi
    if lat > 0 then
        latHemi = 'N'
    else
        latHemi = 'S'
    end

    if lon > 0 then
        lonHemi = 'E'
    else
        lonHemi = 'W'
    end

    lat = math.abs(lat)
    lon = math.abs(lon)

    local latDeg = math.floor(lat)
    local latMin = (lat - latDeg)*60

    local lonDeg = math.floor(lon)
    local lonMin = (lon - lonDeg)*60

    if DMS then	-- degrees, minutes, and seconds.
        local oldLatMin = latMin
        latMin = math.floor(latMin)
        local latSec = math.round((oldLatMin - latMin)*60, acc)

        local oldLonMin = lonMin
        lonMin = math.floor(lonMin)
        local lonSec = math.round((oldLonMin - lonMin)*60, acc)

        if latSec == 60 then
            latSec = 0
            latMin = latMin + 1
        end

        if lonSec == 60 then
            lonSec = 0
            lonMin = lonMin + 1
        end

        local secFrmtStr -- create the formatting string for the seconds place
        if acc <= 0 then	-- no decimal place.
            secFrmtStr = '%02d'
        else
            local width = 3 + acc	-- 01.310 - that's a width of 6, for example.
            secFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
        end
        return string.format(latHemi .. " " .. '%02d', latDeg) .. '° ' .. string.format('%02d', latMin) .. '\' ' .. string.format(secFrmtStr, latSec) .. '"' .. '  '
        .. lonHemi .. " " .. string.format('%02d', lonDeg) .. '° ' .. string.format('%02d', lonMin) .. '\' ' .. string.format(secFrmtStr, lonSec) .. '"'
    else	-- degrees, decimal minutes.
        latMin = math.round(latMin, acc)
        lonMin = math.round(lonMin, acc)

        if latMin == 60 then
            latMin = 0
            latDeg = latDeg + 1
        end

        if lonMin == 60 then
            lonMin = 0
            lonDeg = lonDeg + 1
        end

        local minFrmtStr -- create the formatting string for the minutes place
        if acc <= 0 then	-- no decimal place.
            minFrmtStr = '%02d'
        else
            local width = 3 + acc	-- 01.310 - that's a width of 6, for example.
            minFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
        end

        return string.format(latHemi .. ' ' .. '%02d', latDeg) .. '° ' .. string.format(minFrmtStr, latMin) .. '\'' ..  '  '
        .. lonHemi .. ' ' .. string.format('%02d', lonDeg) .. '° ' .. string.format(minFrmtStr, lonMin) .. '\''

    end
end
-------------------
function FindMarker(markid)--[[
Author       : OzDeaDMeaT
Creation Date: 29-JUL-2023
Usage        : FindMarker(number)
Returns      : number 
Example rtn  : 200]]
    local AllMarkers = world.getMarkPanels()
    local MarkerCheck = -1
    for k,v in ipairs(AllMarkers) do
        if (AllMarkers[k].idx == markid) then 
            MarkerCheck = k --return index in table the number was found (should be greater than 0)
            break
        end
    end
    return MarkerCheck
end
-------------------
function LoadUCID(File)--[[
Author       : OzDeaDMeaT
Creation Date: 03-AUG-2023
Usage        : RegisterUCID(EventData) [Expected data from Marker Remove Event Handler]
Returns      : Loads all UCID's into memory]]
end
-------------------
function RegisterUCID(EventData)--[[
Author       : OzDeaDMeaT
Creation Date: 03-AUG-2023
Usage        : RegisterUCID(EventData) [Expected data from Marker Remove Event Handler]
Returns      : writes UCID and Username to file]]
end
-------------------
function AirCommandParser(EventData)--[[
Author       : OzDeaDMeaT
Creation Date: 03-AUG-2023
Usage        : ParseCommand(EventData) [Expected data from Marker Remove Event Handler]
Returns      : AirCommandDatagram]]
    local ED        = EventData
    local id        = EventData.id
    local idx       = EventData.idx
    local time      = EventData.time
    local initiator = EventData.initiator
    local coalition = EventData.coalition
    local groupId   = EventData.groupId
    local text      = EventData.text
    local pos       = EventData.pos


end
-------------------
function CreateSmoke(coord,color)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : CreateSmoke(vec3, string)]]
    if color == nil then 
        trigSmoke = trigger.smokeColor.White
    else 
        local colour = string.lower(color)
        env.info(string.format("Colour   : %s", tostring(colour)))

        if colour == "green" then trigSmoke = trigger.smokeColor.Green 
            elseif colour == "red" then trigSmoke = trigger.smokeColor.Red
            elseif colour == "white" then trigSmoke = trigger.smokeColor.White 
            elseif colour == "orange" then trigSmoke = trigger.smokeColor.Orange
            elseif colour == "blue" then trigSmoke = trigger.smokeColor.Blue 
            elseif true then trigSmoke = trigger.smokeColor.White 
        end
    end
    local newsmoke = trigger.action.smoke( coord, trigSmoke)
end
-------------------
function CreateFlare(coord,color)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : CreateFlare(vec3, string)]]
    if color == nil then 
        trigSmoke = trigger.flareColor.White
    else 
        local colour = string.lower(color)
        env.info(string.format("Colour   : %s", tostring(colour)))

        if colour == "green" then trigSmoke = trigger.flareColor.Green 
            elseif colour == "red" then trigSmoke = trigger.flareColor.Red
            elseif colour == "white" then trigSmoke = trigger.flareColor.White 
            elseif colour == "yellow" then trigSmoke = trigger.flareColor.Yellow
            elseif true then trigSmoke = trigger.flareColor.White 
        end
    end
    local newsignalFlare = trigger.action.signalFlare( coord, trigSmoke,0)
end
-------------------
function CreateIllum(coord, brightness)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : CreateIllum(vec3, number)]]
    coord.y = 1250
    trigger.action.illuminationBomb(coord,brightness)
end
-------------------
function CreateExplosion(coord, blast)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : CreateExplosion(vec3, number)]]
    trigger.action.explosion(coord,blast)
end
-------------------
function clean(coord, radius)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : clean(vec3, number)]]
    local sphereVolume = {
        id = world.VolumeType.SPHERE,
        params = {point = coord,radius = radius}
    } 
    local tidyCount = world.removeJunk(sphereVolume)
    return tidyCount
end
------------------- 
function MakeOrbitMark(AircraftName)
--Author       : OzDeaDMeaT
--Creation Date: 29-JUL-2023
--Usage        : MakeOrbitMark(Colt11)
    local AST = Air_Support_Table[AircraftName] --ASSUMED GOOD AS THE CHECK IS DONE IN NewISRMission (All data is pulled from this variable)
    local AirSupportUnit = Unit.getByName(AircraftName)
    local Callsign = Unit.getByName(AircraftName):getCallsign()
    local id = AST.id
    local Nameid = AST.NameID
    local vec3 = {x = AST.LastOrder.WP02.x, z = AST.LastOrder.WP02.y, y = 0}
    if(OzDM.SHOW_ORBIT == true) then
        if(AST.LastOrder.RT == true) then 
            if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: Drawing a RaceTrack Orbit!!") end
            DrawRT(AircraftName, vec3, AST.LastOrder.RT_Bearing, AST.LastOrder.RT_Distance)
        else
            if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: Drawing a Circle Orbit!!") end
            if(type(id) == "number") then
                local UAV = AirSupportUnit:hasAttribute("UAVs")
                local AWACS = AirSupportUnit:hasAttribute("AWACS")
                local TANKER = AirSupportUnit:hasAttribute("Tankers")
                local Radius
                if (UAV == true) then 
                    Radius = 1450
                elseif (AWACS == true) then
                    Radius = 3200
                elseif (TANKER == true) then
                    Radius = 3200
                end
                if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: Generating Circular Orbit Marker!!") end
                if(FindMarker(AST.id) >= 1) then 
                    if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: OLD Orbit MarkerID " .. tostring(AST.id) .. " REMOVED!!") end
                    trigger.action.removeMark(AST.id)
                end
                newMarkerID = GetFreeMarkerID(AST.id)
                if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: NEW Orbit MarkerID " .. tostring(newMarkerID) .. " CREATED!!") end
                trigger.action.circleToAll( -1,                 -- -1 == ALL, 0 == Neutral, 1 == Red, 2 == Blue
                                                newMarkerID,        -- Draw ID (must be unique)
                                                vec3,               -- Center of Circle (vec3)
                                                Radius,             -- Radius
                                                AST.LineColourArray,-- Line {r, g, b, a} 
                                                AST.FillColourArray,-- Fill {r, g, b, a} 
                                                AST.LineType,       -- Line Type
                                                false)              -- Read Only
                AST.id = newMarkerID
            end
        end
        if(OzDM.SHOW_ORBIT_NAME == true) then
            if(type(Nameid) == "number") then
                if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: Name MarkerID " .. tostring(Nameid)) end
                local NameidCheck = FindMarker(Nameid)
                if(NameidCheck < 0) then --Marker doesnt exist, create it
                    if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: Name MarkerID " .. tostring(Nameid) .. " doesn't exist, creating now!!") end
                    trigger.action.textToAll(   -1,                 -- -1 == ALL, 0 == Neutral, 1 == Red, 2 == Blue
                                                Nameid,             -- Draw ID (must be unique)
                                                vec3,               -- Center of Circle (vec3)
                                                AST.LineColourArray,-- Line {r, g, b, a} 
                                                {0,0,0,0},          -- Fill {r, g, b, a} 
                                                AST.FontSize,       -- Font Size
                                                true,               -- Read Only
                                                Callsign)           -- Text    
                else --Marker exist, move it
                    if(OzDM.DEBUG == true) then env.info("MakeOrbitMark: Name MarkerID " .. tostring(Nameid) .. " exists, MOVING now!!") end
                    trigger.action.setMarkupPositionStart(Nameid, vec3)
                end
            end
        end 
    end
end
-------------------
function DrawRT(AircraftName, vec3, bearing, distance) -- , LineColour, FillColour, LineType)
    if(OzDM.DEBUG == true) then env.info("DrawRT: STARTED!!") end
    local AirSupportUnit = Unit.getByName(AircraftName)
    local AST = Air_Support_Table[AircraftName] --ASSUMED GOOD AS THE CHECK IS DONE IN NewISRMission (All data is pulled from this variable)
    local id = AST.id
    local UAV = AirSupportUnit:hasAttribute("UAVs")
    local AWACS = AirSupportUnit:hasAttribute("AWACS")
    local TANKER = AirSupportUnit:hasAttribute("Tankers")
    local EndCapRadius
    local MESSAGE
    if (UAV == true) then 
        EndCapRadius = 1400
    elseif (AWACS == true) then
        EndCapRadius = 6550
    elseif (TANKER == true) then
        EndCapRadius = 6550
    end
    local MarkPoint01 = vec3                                         --  1st Orbit WP    (Mark Line 01)
    local WP01_RADIUS = RelativePosition(vec3, bearing - 90 , EndCapRadius)           -- WP01_RADIUS
    local MarkPoint02 = RelativePosition(vec3, bearing, distance)    --  2nd Orbit WP    (Mark Line 02)
    local WP02_RADIUS = RelativePosition(MarkPoint02, bearing - 90 , EndCapRadius)    -- WP02_RADIUS
    local MarkPoint03 = RelativePosition(WP02_RADIUS, bearing + 80 , EndCapRadius)    -- (Mark Line 03)
    local MarkPoint04 = RelativePosition(WP02_RADIUS, bearing + 70 , EndCapRadius)    -- (Mark Line 04)
    local MarkPoint05 = RelativePosition(WP02_RADIUS, bearing + 60 , EndCapRadius)    -- (Mark Line 05)
    local MarkPoint06 = RelativePosition(WP02_RADIUS, bearing + 50 , EndCapRadius)    -- (Mark Line 06)
    local MarkPoint07 = RelativePosition(WP02_RADIUS, bearing + 40 , EndCapRadius)    -- (Mark Line 07)
    local MarkPoint08 = RelativePosition(WP02_RADIUS, bearing + 30 , EndCapRadius)    -- (Mark Line 08)
    local MarkPoint09 = RelativePosition(WP02_RADIUS, bearing + 20 , EndCapRadius)    -- (Mark Line 09)
    local MarkPoint10 = RelativePosition(WP02_RADIUS, bearing + 10 , EndCapRadius)    -- (Mark Line 10)
    local MarkPoint11 = RelativePosition(WP02_RADIUS, bearing      , EndCapRadius)    -- (Mark Line 11)
    local MarkPoint12 = RelativePosition(WP02_RADIUS, bearing - 10 , EndCapRadius)    -- (Mark Line 12)
    local MarkPoint13 = RelativePosition(WP02_RADIUS, bearing - 20 , EndCapRadius)    -- (Mark Line 13)
    local MarkPoint14 = RelativePosition(WP02_RADIUS, bearing - 30 , EndCapRadius)    -- (Mark Line 14)
    local MarkPoint15 = RelativePosition(WP02_RADIUS, bearing - 40 , EndCapRadius)    -- (Mark Line 15)
    local MarkPoint16 = RelativePosition(WP02_RADIUS, bearing - 50 , EndCapRadius)    -- (Mark Line 16)
    local MarkPoint17 = RelativePosition(WP02_RADIUS, bearing - 60 , EndCapRadius)    -- (Mark Line 17)
    local MarkPoint18 = RelativePosition(WP02_RADIUS, bearing - 70 , EndCapRadius)    -- (Mark Line 18)
    local MarkPoint19 = RelativePosition(WP02_RADIUS, bearing - 80 , EndCapRadius)    -- (Mark Line 19)
    local MarkPoint20 = RelativePosition(WP02_RADIUS, bearing - 90 , EndCapRadius)    -- (Mark Line 20)
    --START SECOND SEMICIRCLE
    local MarkPoint21 = RelativePosition(WP01_RADIUS, bearing - 90 , EndCapRadius)     -- (Mark Line 21)
    local MarkPoint22 = RelativePosition(WP01_RADIUS, bearing - 100 , EndCapRadius)    -- (Mark Line 22)
    local MarkPoint23 = RelativePosition(WP01_RADIUS, bearing - 110 , EndCapRadius)    -- (Mark Line 23)
    local MarkPoint24 = RelativePosition(WP01_RADIUS, bearing - 120 , EndCapRadius)    -- (Mark Line 24)
    local MarkPoint25 = RelativePosition(WP01_RADIUS, bearing - 130 , EndCapRadius)    -- (Mark Line 25)
    local MarkPoint26 = RelativePosition(WP01_RADIUS, bearing - 140 , EndCapRadius)    -- (Mark Line 26)
    local MarkPoint27 = RelativePosition(WP01_RADIUS, bearing - 150 , EndCapRadius)    -- (Mark Line 27)
    local MarkPoint28 = RelativePosition(WP01_RADIUS, bearing - 160 , EndCapRadius)    -- (Mark Line 28)
    local MarkPoint29 = RelativePosition(WP01_RADIUS, bearing - 170 , EndCapRadius)    -- (Mark Line 29)
    local MarkPoint30 = RelativePosition(WP01_RADIUS, bearing - 180 , EndCapRadius)    -- (Mark Line 30)
    local MarkPoint31 = RelativePosition(WP01_RADIUS, bearing - 190 , EndCapRadius)    -- (Mark Line 31)
    local MarkPoint32 = RelativePosition(WP01_RADIUS, bearing - 200 , EndCapRadius)    -- (Mark Line 32)
    local MarkPoint33 = RelativePosition(WP01_RADIUS, bearing - 210 , EndCapRadius)    -- (Mark Line 33)
    local MarkPoint34 = RelativePosition(WP01_RADIUS, bearing - 220 , EndCapRadius)    -- (Mark Line 34)
    local MarkPoint35 = RelativePosition(WP01_RADIUS, bearing - 230 , EndCapRadius)    -- (Mark Line 35)
    local MarkPoint36 = RelativePosition(WP01_RADIUS, bearing - 240 , EndCapRadius)    -- (Mark Line 36)
    local MarkPoint37 = RelativePosition(WP01_RADIUS, bearing - 250 , EndCapRadius)    -- (Mark Line 37)
    local MarkPoint38 = RelativePosition(WP01_RADIUS, bearing - 260 , EndCapRadius)    -- (Mark Line 38)
    local MarkPoint39 = RelativePosition(WP01_RADIUS, bearing - 270 , EndCapRadius)    -- (Mark Line 39)

    local MrkPnts = {
        [1]  = MarkPoint01,
        [2]  = MarkPoint02,
        [3]  = MarkPoint03,
        [4]  = MarkPoint04,
        [5]  = MarkPoint05,
        [6]  = MarkPoint06,
        [7]  = MarkPoint07,
        [8]  = MarkPoint08,
        [9]  = MarkPoint09,
        [10] = MarkPoint10,
        [11] = MarkPoint11,
        [12] = MarkPoint12,
        [13] = MarkPoint13,
        [14] = MarkPoint14,
        [15] = MarkPoint15,
        [16] = MarkPoint16,
        [17] = MarkPoint17,
        [18] = MarkPoint18,
        [19] = MarkPoint19,
        [20] = MarkPoint20,
        [21] = MarkPoint21,
        [22] = MarkPoint22,
        [23] = MarkPoint23,
        [24] = MarkPoint24,
        [25] = MarkPoint25,
        [26] = MarkPoint26,
        [27] = MarkPoint27,
        [28] = MarkPoint28,
        [29] = MarkPoint29,
        [30] = MarkPoint30,
        [31] = MarkPoint31,
        [32] = MarkPoint32,
        [33] = MarkPoint33,
        [34] = MarkPoint34,
        [35] = MarkPoint35,
        [36] = MarkPoint36,
        [37] = MarkPoint37,
        [38] = MarkPoint38,
        [39] = MarkPoint39}

    
    if(type(AST.id) == 'number') then
        if(FindMarker(AST.id) >= 1) then 
            if(OzDM.DEBUG == true) then env.info("DrawRT: OLD Orbit MarkerID " .. tostring(AST.id) .. " REMOVED!!") end
            trigger.action.removeMark(AST.id)
        end
    else
        env.info("No Mark Number Found in Table!!")
    end
    newMarkerID = GetFreeMarkerID(AST.id)
    if(OzDM.DEBUG == true) then env.info("DrawRT: NEW Orbit MarkerID " .. tostring(newMarkerID) .. " CREATED!!") end
    trigger.action.markupToAll( 7,                  -- Draw Type
                                -1,                 -- Coalition -1 == ALL, 0 == Neutral, 1 == Red, 2 == Blue
                                newMarkerID,        -- Draw ID (must be unique)
                                MrkPnts[1],         -- Point01 (vec3)
                                MrkPnts[2],         -- Point02 (vec3)
                                MrkPnts[3],         -- Point03 (vec3)
                                MrkPnts[4],         -- Point04 (vec3)
                                MrkPnts[5],         -- Point05 (vec3)
                                MrkPnts[6],         -- Point06 (vec3)
                                MrkPnts[7],         -- Point07 (vec3)
                                MrkPnts[8],         -- Point08 (vec3)
                                MrkPnts[9],         -- Point09 (vec3)
                                MrkPnts[10],        -- Point10 (vec3)
                                MrkPnts[11],        -- Point11 (vec3)
                                MrkPnts[12],        -- Point12 (vec3)
                                MrkPnts[13],        -- Point13 (vec3)
                                MrkPnts[14],        -- Point14 (vec3)
                                MrkPnts[15],        -- Point15 (vec3)
                                MrkPnts[16],        -- Point16 (vec3)
                                MrkPnts[17],        -- Point17 (vec3)
                                MrkPnts[18],        -- Point18 (vec3)
                                MrkPnts[19],        -- Point19 (vec3)
                                MrkPnts[20],        -- Point20 (vec3)
                                MrkPnts[21],        -- Point21 (vec3)
                                MrkPnts[22],        -- Point22 (vec3)
                                MrkPnts[23],        -- Point23 (vec3)
                                MrkPnts[24],        -- Point24 (vec3)
                                MrkPnts[25],        -- Point35 (vec3)
                                MrkPnts[26],        -- Point26 (vec3)
                                MrkPnts[27],        -- Point27 (vec3)
                                MrkPnts[28],        -- Point28 (vec3)
                                MrkPnts[29],        -- Point29 (vec3)
                                MrkPnts[30],        -- Point30 (vec3)
                                MrkPnts[30],        -- Point30 (vec3)
                                MrkPnts[31],        -- Point31 (vec3)
                                MrkPnts[32],        -- Point32 (vec3)
                                MrkPnts[33],        -- Point33 (vec3)
                                MrkPnts[34],        -- Point34 (vec3)
                                MrkPnts[35],        -- Point35 (vec3)
                                MrkPnts[36],        -- Point36 (vec3)
                                MrkPnts[37],        -- Point37 (vec3)
                                MrkPnts[38],        -- Point38 (vec3)
                                MrkPnts[39],        -- Point39 (vec3)
                                --LineColour, 
                                --FillColour, 
                                --LineType,
                                AST.LineColourArray,-- Line {r, g, b, a} 
                                AST.FillColourArray,-- Fill {r, g, b, a} 
                                AST.LineType,       -- Line Type
                                false,               -- Read Only
                                "")
        AST.id = newMarkerID
        env.info("Mark Saved to Table " .. tostring(newMarkerID) .. " !!")
end
--MARKER INTERACTION FUNCTIONS------------------------------------------------------------------------------------------------------
-------------------
function MarkerCoOrd(EventData)--[[
Author       : OzDeaDMeaT
Creation Date: 29-JUL-2023
Usage        : !coord:<option>
Example      : !coord:all (Returns all CoOrd types)
Example      : !coord:grid (Returns MGRS Grid)
Example      : !coord:mgrs (Returns MGRS)
Example      : !coord:LL (Returns both types of LL) 
Example      : !coord:DM (Returns LLDM)
Example      : !coord:DMS (Returns LLDMS)
Returns      : Message]]
    local initiator = EventData.initiator
    local coalition = EventData.coalition
    local text      = EventData.text
    local outputString = ""
    local pos = EventData.pos
    local StringTBL = StringSplit(text,':')
    local Switch = StringTBL[#StringTBL]
    local SwitchLower = Switch:lower()
    if(string.match(SwitchLower,'%a+') == 'coord') then 
        SwitchLower = 'all'
    end
    local Progress = false
    local MGRS = formatMGRS(pos)
    local GRID = formatGRID(pos)
    local LLDM = formatLL(pos,4,false)
    local LLDMS = formatLL(pos,2,true)

    if ((SwitchLower == 'grid') or (SwitchLower == 'all')) then    
        Progress = true
        outputString = outputString .. "GRID : " .. GRID
        if (SwitchLower == 'all') then 
            outputString = outputString .. "\n"
        end
    end

    if ((SwitchLower == 'mgrs') or (SwitchLower == 'all')) then    
        Progress = true
        outputString = outputString .. "MGRS : " .. MGRS
        if (SwitchLower == 'all') then 
            outputString = outputString .. "\n"
        end
    end

    if ((SwitchLower == 'll') or (SwitchLower == 'all')) then    
        Progress = true
        outputString = outputString .. "LLDM : " .. LLDM .. "\n"
        outputString = outputString .. "LLDMS: " .. LLDMS
    end

    if (SwitchLower == 'dm') then
        Progress = true
        outputString = outputString .. "LLDM : " .. LLDM
    end

    if (SwitchLower == 'dms') then
        Progress = true
        outputString = outputString .. "LLDMS: " .. LLDMS
    end
    if (Progress == true) then 
        local altMeters = land.getHeight({x=pos.x, y=pos.z})
        local altFeet   = m2ft(altMeters)
        outputString = outputString .. "\nALT: " .. math.floor(altMeters) .. "m / " .. math.floor(altFeet) .. "ft"
        if(IsUnit(initiator) == true) then
            trigger.action.outTextForUnit(initiator:getID(), outputString, 90, false)
        else
            trigger.action.outTextForCoalition(coalition, outputString, 30, false)
        end
    end
end
-------------------
function MarkerSmoke(coord,markerTXT)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : !smoke:<colour>
Example      : !smoke:white
Example      : !smoke
(If not colour value is given, the OzDM.DEFAULT_SMOKE value will be used)]]
    local StringTBL = StringSplit(markerTXT,':')
    local SmokeColour = StringTBL[#StringTBL]
    local SmokeChar = string.sub(SmokeColour,1,1)
    if (type(OzDM.DEFAULT_SMOKE) == 'nil') then
        OzDM.DEFAULT_SMOKE = "white"
        env.info(string.format("OzDM.DEFAULT_SMOKE VALUE NOT FOUND SETTING TO : %s", tostring(OzDM.DEFAULT_SMOKE)))
    end
    if     SmokeChar == 'g' then CreateSmoke(coord,"green")
    elseif SmokeChar == 'r' then CreateSmoke(coord,"red")
    elseif SmokeChar == 'w' then CreateSmoke(coord,"white")
    elseif SmokeChar == 'o' then CreateSmoke(coord,"orange")
    elseif SmokeChar == 'b' then CreateSmoke(coord,"blue")
    elseif true             then CreateSmoke(coord,OzDM.DEFAULT_SMOKE)
    end
end
-------------------
function MarkerFlare(coord,markerTXT)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : !flare:<colour>
Example      : !flare:white
Example      : !flare
(If not colour value is given, the OzDM.DEFAULT_FLARE value will be used)]]
        local StringTBL = StringSplit(markerTXT,':')
        local FlareColour = StringTBL[#StringTBL]
        local FlareChar = string.sub(FlareColour,1,1)
        if (type(OzDM.DEFAULT_FLARE) == 'nil') then
            OzDM.DEFAULT_FLARE = "white"
            env.info(string.format("OzDM.DEFAULT_FLARE VALUE NOT FOUND SETTING TO : %s", tostring(OzDM.DEFAULT_FLARE)))
        end
        if     FlareChar == 'g' then CreateFlare(coord,"green")
        elseif FlareChar == 'r' then CreateFlare(coord,"red")
        elseif FlareChar == 'w' then CreateFlare(coord,"white")
        elseif FlareChar == 'y' then CreateFlare(coord,"orange")
        elseif true             then CreateFlare(coord,OzDM.DEFAULT_FLARE)
        end
end
-------------------
function MarkerIllum(coord,markerTXT)--[[
Author       : OzDeaDMeaT
Creation Date: 26-JUL-2023
Usage        : !illum:<value>
Example      : !illum:50000
Example      : !illum
(Cant exceed your OzDM.ILLUM_LIMIT value)]]
        local StringTBL = StringSplit(markerTXT,':')
        local IllumPower = tonumber(StringTBL[#StringTBL])
        if (type(OzDM.ILLUM_LIMIT) == 'nil') then
            OzDM.ILLUM_LIMIT = 1000000
            env.info(string.format("OzDM.ILLUM_LIMIT VALUE NOT FOUND SETTING TO : %s", tostring(OzDM.ILLUM_LIMIT)))
        end
        env.info(string.format("IllumPower VarType: %s", type(IllumPower)))
        env.info(string.format("OzDM.ILLUM_LIMIT VarType: %s", type(OzDM.ILLUM_LIMIT)))
        --env.info(string.format("MarkerIllum: CHECKING %s", tostring(IllumPower)))
        if (type(IllumPower) == 'number') then 
            if (IllumPower > OzDM.ILLUM_LIMIT) then 
                env.info(string.format("Explosion value of %s is too high, cant be over a value of %s, limiting value back down to %s",tostring(IllumPower), tostring(OzDM.ILLUM_LIMIT), tostring(OzDM.ILLUM_LIMIT)))
                IllumPower = OzDM.ILLUM_LIMIT
            end
            CreateIllum(coord,IllumPower)
        else 
            env.info(string.format("MarkerIllum: %s is NOT a number",tostring(IllumPower)))
            IllumPower = OzDM.ILLUM_LIMIT
            CreateIllum(coord,IllumPower)
        end
end
-------------------
function MarkerClean(coord,markerTXT)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : !clean:<radius>
Example      : !clean:5000
(Cant exceed your OzDM.CLEAN_LIMIT value)]]
    local StringTBL = StringSplit(markerTXT,':')
    local CleanRadius = tonumber(StringTBL[#StringTBL])
    if (type(OzDM.CLEAN_LIMIT) == 'nil') then
        OzDM.CLEAN_LIMIT = 9000
        env.info(string.format("OzDM.CLEAN_LIMIT VALUE NOT FOUND SETTING TO : %s", tostring(OzDM.CLEAN_LIMIT)))
    end
    if (type(CleanRadius) == 'number') then 
        if (CleanRadius > OzDM.CLEAN_LIMIT) then 
            env.info(string.format("CleanRadius value of %s is too high, cant be over a value of %s, limiting value back down to %s",tostring(CleanRadius), tostring(OzDM.CLEAN_LIMIT), tostring(OzDM.CLEAN_LIMIT)))
            CleanRadius = OzDM.CLEAN_LIMIT
        end
        clean(coord,CleanRadius)
    else 
        env.info(string.format("CleanRadius: %s is NOT a number",tostring(CleanRadius)))
    end
end
-------------------
function MarkerNewISRTask(coord,markerTXT)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : !isr:<groupname>
Example      : !isr:Uzi11]]
    local StringTBL = StringSplit(markerTXT,':')
    local AircraftName = StringTBL[#StringTBL]
    local ISRGroup = Group.getByName(AircraftName)
    local GroupGood = false
    if(ISRGroup == nil) then
        if(OzDM.DEFAULT_ISR ~= false) then 
            AircraftName = OzDM.DEFAULT_ISR
            ISRGroup = Group.getByName(AircraftName)
            if(ISRGroup == nil) then
                if(OzDM.DEBUG == true) then env.info("MarkerNewISRTask: DEFAULT_ISR does not exist in mission, nothing moved") end
            else
                GroupGood = true
            end
        else
            if(OzDM.DEBUG == true) then env.info("MarkerNewISRTask: " .. AircraftName .. " does not exist in mission and DEFAULT_ISR is not enabled") end
        end
    else
        GroupGood = true
    end

    if(GroupGood == true) then
        if(ISRGroup:isExist() == true) then
            local MyUnit = Group.getByName(AircraftName):getUnit(1)
            if(MyUnit:hasAttribute("UAVs") == true) then
                NewISRMission(AircraftName,coord)
            else
                if(OzDM.DEBUG == true) then env.info("MarkerNewISRTask: Unit " .. tostring(AircraftName) .. " is not a UAV, ignoring request!!!") end
                trigger.action.outTextForCoalition(
                    Group.getByName(AircraftName):getCoalition(),
                    tostring(Group.getByName(AircraftName):getUnit(1):getCallsign()) .. ' unable to comply, I am not a UAV.',
                    10,
                    false)
            end
        else
                if(OzDM.DEBUG == true) then env.info("MarkerNewISRTask: Group " .. tostring(AircraftName) .. " DOES NOT exist or has not yet spawned!!") end
        end
    end
end
-------------------
function MarkerExplosion(coord,markerTXT)--[[
Author       : OzDeaDMeaT
Creation Date: 9-JUL-2023
Usage        : Used with EventHandler(MarkerRemoved
(Cant exceed your OzDM.EXPLOSION_LIMIT value)]]
    local StringTBL = StringSplit(markerTXT,':')
    local ExplosionBlastPower = tonumber(StringTBL[#StringTBL])
    if (type(OzDM.EXPLOSION_LIMIT) == 'nil') then
        OzDM.EXPLOSION_LIMIT = 9000
        env.info(string.format("OzDM.EXPLOSION_LIMIT VALUE NOT FOUND SETTING TO : %s", tostring(OzDM.EXPLOSION_LIMIT)))
    end
    env.info(string.format("ExplosionBlastPower VarType: %s", type(ExplosionBlastPower)))
    env.info(string.format("OzDM.EXPLOSION_LIMIT VarType: %s", type(OzDM.EXPLOSION_LIMIT)))
    --env.info(string.format("MarkerExplode: CHECKING %s", tostring(ExplosionBlastPower)))
    if (type(ExplosionBlastPower) == 'number') then 
        if (ExplosionBlastPower > OzDM.EXPLOSION_LIMIT) then 
            env.info(string.format("Explosion value of %s is too high, cant be over a value of %s, limiting value back down to %s",tostring(ExplosionBlastPower), tostring(OzDM.EXPLOSION_LIMIT), tostring(OzDM.EXPLOSION_LIMIT)))
            ExplosionBlastPower = OzDM.EXPLOSION_LIMIT
        end
        CreateExplosion(coord,ExplosionBlastPower)
    else 
        env.info(string.format("MarkerExplode: %s is NOT a number",tostring(ExplosionBlastPower)))    
    end
end
-------------------
function RelativePosition(vec3, bearing, distance)
    local point2 = {}
    point2.z = (math.sin(math.rad(bearing)) * distance) + vec3.z
    point2.x = (math.cos(math.rad(bearing)) * distance) + vec3.x
    point2.y = 0
    return point2
end
-------------------
function MarkerAirSupportTasking(EventData)--[[
Author       : OzDeaDMeaT
Creation Date: 6-AUG-2023
Usage        : Used with EventHandler(MarkerRemoved)]]
    SPEED_INCREMENT     = 100
    SPEED_INCREMENT_NEG = SPEED_INCREMENT * -1
    ALT_INCREMENT       = 5000
    ALT_INCREMENT_NEG   = (ALT_INCREMENT * -1)
    local text          = EventData.text
    local pos           = EventData.pos
    local StringTBL     = StringSplit(text,':')
    local Command       = StringTBL[1]
    local AllArgs       = StringTBL[2]
    local SplitArgs     = StringSplit(AllArgs,'\n')
    local Aircraft      = SplitArgs[1]
    local FlightArgs    = SplitArgs[2]
    local SettingsArgs  = SplitArgs[3]
    local CommandMove   = true
    local isr           = false
    local awacs         = false
    local a2a           = false
    local ChngSpeed     = false
    local ChngAlt       = false
    local SpeedStr       
    local SpeedNum       
    local AltStr         
    local AltNum        
    local AST = Air_Support_Table[Aircraft]
    if(OzDM.DEBUG == true) then env.info("----------------------------------") end
    if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: STARTED!!") end
    if(AST ~= nil) then
        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Air_Support_Table loaded data for = " .. Aircraft) end
        if (FlightArgs ~= nil) then
            if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Flight Arg(s) found!!! = " .. FlightArgs) end 
            if (string.find(FlightArgs:lower(),'-s')) then
                if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Speed Arg found!!") end
                local SpeedStr = string.match(FlightArgs,'\-s%-?%d+')
                if SpeedStr ~= nil then 
                    SpeedNum = tonumber(string.match(SpeedStr,'%-?%d+'))
                    if (SpeedNum <= SPEED_INCREMENT) and (SpeedNum >= SPEED_INCREMENT_NEG) then 
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Speed number is classified as DELTA # = " .. tostring(SpeedNum)) end
                        Air_Support_Table[Aircraft].LastOrder.speed = Air_Support_Table[Aircraft].LastOrder.speed + kt2mps(SpeedNum)
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: " .. Aircraft .. " speed set to " .. tostring(Air_Support_Table[Aircraft].LastOrder.speed)) end
                        --SWITCH TO DELTA SPEED
                    else
                        if (SpeedNum < 0) then 
                            SpeedNum = SpeedNum * -1
                            -- Absolute SPEED value can not be less than 0
                        end
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Speed number is classified as Absolute # = " .. tostring(kt2mps(SpeedNum))) end
                        Air_Support_Table[Aircraft].LastOrder.speed = kt2mps(SpeedNum)
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: " .. Aircraft .. " speed set to " .. tostring(Air_Support_Table[Aircraft].LastOrder.speed)) end
                        --SWITCH TO Absolute SPEED
                    end
                    ChngSpeed = true
                    Group.getByName(Aircraft):getController():setSpeed(Air_Support_Table[Aircraft].LastOrder.speed)
                else
                --Keep same speed alt everything, only move
                if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Number invalid, no change to speed " .. tostring(Air_Support_Table[Aircraft].LastOrder.speed)) end
                Group.getByName(Aircraft):getController():setSpeed(Air_Support_Table[Aircraft].LastOrder.speed)
                end
            end

            if (string.find(FlightArgs:lower(),'-a')) then --ALTITUDE SECTION
                if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Altitude Arg found!!") end
                local AltStr = string.match(FlightArgs,'\-a%-?%d+')
                if AltStr ~= nil then 
                    AltNum = tonumber(string.match(AltStr,'%-?%d+'))
                    if (AltNum <= ALT_INCREMENT) and (AltNum >= ALT_INCREMENT_NEG) then 
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Number is classified as DELTA # = " .. tostring(AltNum)) end
                        Air_Support_Table[Aircraft].LastOrder.alt = Air_Support_Table[Aircraft].LastOrder.alt + ft2m(AltNum)
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: " .. Aircraft .. " altitude set to " .. tostring(Air_Support_Table[Aircraft].LastOrder.alt)) end
                        --SWITCH TO DELTA ALT
                    else
                        if (AltNum < 0) then 
                            AltNum = AltNum * -1
                            -- Absolute ALT value can not be less than 0
                        end
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Number is classified as Absolute # = " .. tostring(AltNum)) end
                        Air_Support_Table[Aircraft].LastOrder.alt = ft2m(AltNum)
                        if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: " .. Aircraft .. " altitude set to " .. tostring(Air_Support_Table[Aircraft].LastOrder.alt)) end
                        --SWITCH TO Absolute ALT
                    end
                    ChngAlt = true
                    Group.getByName(Aircraft):getController():setAltitude(Air_Support_Table[Aircraft].LastOrder.alt, true)
                else
                --Keep same altitude
                if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Number invalid, no change to altitude " .. tostring(Air_Support_Table[Aircraft].LastOrder.alt)) end
                Group.getByName(Aircraft):getController():setAltitude(Air_Support_Table[Aircraft].LastOrder.alt, true)
                end
            end
            if (string.find(FlightArgs:lower(),'-dm')) then
                CommandMove = false
                local Cpos = Unit.getByName(Aircraft):getPosition().p
                if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Aircraft Current Position is> X: " .. tostring(Cpos.x) .. " Y: " .. tostring(Cpos.z)) end
            else
                Air_Support_Table[Aircraft].LastOrder.WP02.x = pos.x
                Air_Support_Table[Aircraft].LastOrder.WP02.y = pos.z
                local Cpos = Unit.getByName(Aircraft):getPosition().p
                if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Aircraft Current Position is> X: " .. tostring(Cpos.x) .. " Y: " .. tostring(Cpos.z)) end
                if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Orbit Position Set to> X: " .. tostring(pos.x) .. " Y: " .. tostring(pos.z)) end
                
                if (string.find(FlightArgs:lower(),'-rt')) then
                    if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: RaceTrack Orbit Selected!!") end
                    AST.LastOrder.RT = true
                    Air_Support_Table[Aircraft].LastOrder.RT = true
                    --Air_Support_Table[Aircraft].LastOrder.WP02.x = pos.x
                    --Air_Support_Table[Aircraft].LastOrder.WP02.y = pos.z
                    local RaceTrack = string.match(FlightArgs,'\-rt.%d+\-%d+')
                    local Bearing   = string.match(RaceTrack,'%d+')
                    local tmp       = string.match(RaceTrack,'\-%d+')
                    local Range     = string.match(tmp,'%d+')
                    Bearing = tonumber(Bearing)
                    Range = tonumber(Range)
                    if(Range < 500) then 
                        Range = Range * 1000
                    end
                    AST.LastOrder.RT_Bearing = Bearing
                    AST.LastOrder.RT_Distance = Range
                    local WP03pos   = RelativePosition(pos, Bearing, Range)
                    if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: RaceTrack = " .. tostring(RaceTrack) .. " Bearing: " .. tostring(Bearing) .. " Range: " .. tostring(Range)) end
                    AST.LastOrder.WP03.x = WP03pos.x
                    AST.LastOrder.WP03.y = WP03pos.z
                else
                    if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Circle Orbit Selected") end
                    AST.LastOrder.RT = false
                    Air_Support_Table[Aircraft].LastOrder.RT = false
                end
                ConfigureAirSupportMissionTask(Aircraft)
            end
        else 
            AST.LastOrder.WP02.x = pos.x
            AST.LastOrder.WP02.y = pos.z
            AST.LastOrder.RT = false
            if(OzDM.DEBUG == true) then env.info("MarkerAirSupportTasking: Orbit Position Set to> X: " .. tostring(pos.x) .. " Y: " .. tostring(pos.z)) end
            ConfigureAirSupportMissionTask(Aircraft)
        end
    end
end
---------------
function IsAirborneSetTask(args)--[[
This function checks if an Support Aircraft is airborne then assigns its mission to it
Author       : OzDeaDMeaT
Creation Date: 5-AUG-2023
Usage        : IsAirborneSetTask({Aircraft = UnitName, time = time})
Return       : nothing]]
    local UnitName = args.Aircraft
    local time = args.time
    if(IsUnit(UnitName)) then 
        if(Unit.getByName(UnitName):inAir() == false) then 
            if(OzDM.DEBUG == true) then env.info("IsAirborneSetTask: " .. UnitName .. " is not airborne yet, waiting another " .. tostring(time) .. " seconds!") end
            timer.scheduleFunction(IsAirborneSetTask,{Aircraft = UnitName, time = time}, timer.getTime() + time)
        else
            if(OzDM.DEBUG == true) then env.info("IsAirborneSetTask: " .. UnitName .. " is now airborne sending Mission Task now") end
            ConfigureAirSupportMissionTask(UnitName)
        end
    else
        if(OzDM.DEBUG == true) then env.info("IsAirborneSetTask: " .. tostring(UnitName) .. " is not a unit, exitting!!") end
    end
end
---------------
function ReportOnStationStatus(AircraftName)--[[
This function sends a report to the user interface showing units current MGRS grid and fuel state. Additional info depending on the 
Author       : OzDeaDMeaT
Creation Date: 5-AUG-2023
Usage        : ReportOnStationStatus(string)
Return       : MissionTask]]
    local AirSupportUnit = Unit.getByName(AircraftName)
    local AST = Air_Support_Table[AircraftName]
    local UnitPosition = AirSupportUnit:getPosition().p
    local FuelState = math.round(AirSupportUnit:getFuel() * 100,1)
    env.info("FUELSTATE =========== " .. FuelState)
    local MGRS_GRID = formatGRID(UnitPosition)
    --local Callsign  = GetCallsignID(AircraftName)
    local Modulation
    if(AST.FreqMode == 0) then
        Modulation = "AM"
    else
        Modulation = "FM"
    end
    local PlayTime = "ERROR"
    if (FuelState <= 8 ) then PlayTime = "RTB Imminent"
    elseif (FuelState > 8  and FuelState <= 16) then PlayTime = "Less than 1 Hour"
    elseif (FuelState > 16  and FuelState <= 24) then PlayTime = "Approximately 2 Hours"
    elseif (FuelState > 24  and FuelState <= 32) then PlayTime = "Approximately 3 Hours"
    elseif (FuelState > 32  and FuelState <= 40) then PlayTime = "Approximately 4 Hours"
    elseif (FuelState > 48  and FuelState <= 56) then PlayTime = "Approximately 5 Hours"
    elseif (FuelState > 56) then PlayTime = "Plus 5 Hours"
    end
    local UAV = AirSupportUnit:hasAttribute("UAVs")
    local AWACS = AirSupportUnit:hasAttribute("AWACS")
    local TANKER = AirSupportUnit:hasAttribute("Tankers")
    local MESSAGE
    if (UAV == true) then 
        MESSAGE = AircraftName .. " has arrived on station at grid " .. MGRS_GRID .. "\nRadio: " .. tostring(AST.Freq) .. Modulation .. "\nLaser Code: " .. tostring(AST.LaserCode) .. "\nFuel State: " .. tostring(FuelState) .. "%\nPlaytime: " .. PlayTime
    elseif (AWACS == true) then
        MESSAGE = AircraftName .. " has arrived on station at grid " .. MGRS_GRID .. "\nRadio: " .. tostring(AST.Freq) .. Modulation .. "\nFuel State: " .. tostring(FuelState) .. "%\nPlaytime: " .. PlayTime
    elseif (TANKER == true) then
        MESSAGE = AircraftName .. " has arrived on station at grid " .. MGRS_GRID .. "\nRadio: " .. tostring(AST.Freq) .. Modulation .. "\nTACAN (" .. AST.TACAN.CALLSIGN .. "): " .. tostring(AST.TACAN.CHANNEL) .. tostring(AST.TACAN.MODECHANNEL) .. "\nALT/SPEED: " .. math.round(m2ft(AST.LastOrder.alt),0) .. "ft at " .. math.round(mps2kt(AST.LastOrder.speed),0) .. "kt\nFuel State: " .. tostring(FuelState) .. "%\nPlaytime: " .. PlayTime
    else
        MESSAGE = AircraftName .. " has arrived on station at grid " .. MGRS_GRID .. "\nFuel State: " .. tostring(FuelState) .. "%\nPlaytime: " .. PlayTime
    end
    trigger.action.outTextForCoalition(AirSupportUnit:getCoalition(), --Coalition
    MESSAGE,
    10, --Time to stay on screen
    false) --Clear Previous Messages
end
---------------
function ConfigureAirSupportMissionTask(UnitName)--[[
This function collects information from the Air_Support_Table and prepares the mission task
Author       : OzDeaDMeaT
Creation Date: 5-AUG-2023
Usage        : ConfigureAirSupportMissionTask(string)
Return       : MissionTask]]
    local ProceedwithMissionPrep = false
    --DO ALL CHECKS AND IF ALL CHECKS ARE MET, SET ProceedwithMissionPrep to TRUE
    if(IsUnit(UnitName)) then
        if(Unit.getByName(UnitName):isActive()) then 
            if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask : " .. UnitName .. " group is active") end 
            if(type(Air_Support_Table[UnitName]) == 'table') then
                if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask : " .. UnitName .. " group is present in Air_Support_Table") end 
                ProceedwithMissionPrep = true
            else
                if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! ConfigureAirSupportMissionTask : " .. UnitName .. " group is NOT present in Air_Support_Table") end 
            end
        else
            if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! ConfigureAirSupportMissionTask : " .. UnitName .. " group is NOT active") end 
        end
    else
        if(OzDM.DEBUG == true) then env.info("!!!ERROR!!! ConfigureAirSupportMissionTask : UnitName was passed to function and was NOT a string value") end
    end
    if(ProceedwithMissionPrep == true) then
        if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask : All checks cleared, proceeding with MissionTask Preparation") end
        local AirSupportUnit = Unit.getByName(UnitName)
        local AST = Air_Support_Table[UnitName]
        local UAV = AirSupportUnit:hasAttribute("UAVs")
        local AWACS = AirSupportUnit:hasAttribute("AWACS")
        local TANKER = AirSupportUnit:hasAttribute("Tankers")
        local FLYING = AirSupportUnit:inAir()
        local UnitPosition = AirSupportUnit:getPosition().p
        local FuelState = math.round(AirSupportUnit:getFuel() * 100,1)
        local ArriveStringCommand = string.format("ReportOnStationStatus('%s')",UnitName)
        local MGRS_GRID = formatGRID({x = AST.LastOrder.WP02.x, y = 0, z = AST.LastOrder.WP02.y})
        local SUPPORT_MISSION
        local INITIAL_TASKS
        local OrbitType
        if(AST.LastOrder.RT == true) then 
            OrbitType = "Race-Track"
        else
            OrbitType = "Circle"
        end
        if (AWACS == true)  then 
            INITIAL_TASKS = New_AWACS_TASKS(AST.Invisible, AST.Immortal)
        end
        if (TANKER == true) then 
            INITIAL_TASKS = New_TANKER_TASKS(AST.Invisible, AST.Immortal)
        end
        if (UAV == true)    then
            INITIAL_TASKS = New_FAC_TASKS(AST.LaserCode, AST.Freq, AST.FreqMode, GetCallsignID(UnitName), AST.Invisible, AST.Immortal)
        end
        --Prep WP01
        SUPPORT_MISSION = NewMission()
        SUPPORT_MISSION.params.route.points[1] = NewWayPoint({x = UnitPosition.x, y= UnitPosition.z}, UnitPosition.y, AST.LastOrder.speed)
        SUPPORT_MISSION.params.route.points[1].task.params.tasks = INITIAL_TASKS
        if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask: ArriveStringCommand = " .. ArriveStringCommand) end
        if(AirSupportUnit:inAir() == false) then
            if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask: " .. tostring(AirSupportUnit:getCallsign() .. " is on the ground")) end
            SUPPORT_MISSION.params.airborne = false
            SUPPORT_MISSION.params.route.points[1].alt = land.getHeight({x=UnitPosition.x,UnitPosition.z})
            SUPPORT_MISSION.params.route.points[1].action = "From Ground Area"
            SUPPORT_MISSION.params.route.points[1].type = "TakeOffGround"
        else    
            if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask: " .. tostring(AirSupportUnit:getCallsign() .. " is airborne")) end
            SUPPORT_MISSION.params.airborne = true
            SUPPORT_MISSION.params.route.points[1].alt = UnitPosition.y --AST.LastOrder.alt
            --env.info("ALTITUDE for " .. UnitName .."in METERS: " .. UnitPosition.y)
            SUPPORT_MISSION.params.route.points[1].action = "Fly Over Point"
            SUPPORT_MISSION.params.route.points[1].type = "Turning Point"
        end
        --Prep WP02
        SUPPORT_MISSION.params.route.points[2] = NewWayPoint(AST.LastOrder.WP02, AST.LastOrder.alt, AST.LastOrder.speed)
        if(AST.LastOrder.RT == true) then       
            ORBITTASK = New_ORBIT_TASKS(OrbitType, AST.LastOrder.alt, AST.LastOrder.speed, AST.LastOrder.WP02, AST.LastOrder.WP03)
            SUPPORT_MISSION.params.route.points[3] = NewWayPoint(AST.LastOrder.WP03, AST.LastOrder.alt, AST.LastOrder.speed)
            if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask: INCLUDING THIRD WP for " .. tostring(AirSupportUnit:getCallsign())) end
        else
            ORBITTASK = New_ORBIT_TASKS(OrbitType, AST.LastOrder.alt, AST.LastOrder.speed, AST.LastOrder.WP02)
            if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask: EXCLUDE THIRD WP for " .. tostring(AirSupportUnit:getCallsign())) end
        end
        --Sets the ORBIT TASK
        ORBITTASK[1].params.action.params.command = ArriveStringCommand
        SUPPORT_MISSION.params.route.points[2].task.params.tasks = ORBITTASK
        if(AirSupportUnit:inAir() == false) then
            AirSupportUnit:getGroup():getController():setCommand(COMMANDS.START)
            if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask: Sending to IsAirborneSetTask(" .. UnitName .. ",60)") end
            IsAirborneSetTask({Aircraft = UnitName, time = 60})
        else
            AirSupportUnit:getGroup():getController():resetTask()
            AirSupportUnit:getGroup():getController():setTask(SUPPORT_MISSION)
            
            if (TANKER == true) then 
                --SUPPORT_MISSION.id = "Tanker"
                SetUnitTACAN(UnitName, AST.TACAN.CALLSIGN, AST.TACAN.MODECHANNEL, AST.TACAN.CHANNEL, AST.TACAN.AA)
                SetUnitRadioFrequency(UnitName, AST.Freq, AST.FreqMode)
            end

            if (UAV == true) then 
                SetUnitRadioFrequency(UnitName, AST.Freq, AST.FreqMode)
            end

            if (AWACS == true) then 
                SetUnitTACAN(UnitName, AST.TACAN.CALLSIGN, AST.TACAN.MODECHANNEL, AST.TACAN.CHANNEL, AST.TACAN.AA)
                SetUnitRadioFrequency(UnitName, AST.Freq, AST.FreqMode)
            end

            if(OzDM.DEBUG == true) then env.info("ConfigureAirSupportMissionTask: Assigning New Task to " .. tostring(AirSupportUnit:getCallsign())) end
        end
        trigger.action.outTextForCoalition(
            AirSupportUnit:getGroup():getCoalition(),
            tostring(AirSupportUnit:getCallsign()) .. ' copies, relocating to grid ' .. MGRS_GRID,
            10,
            false)
        MakeOrbitMark(UnitName)
    end
end
------------------------------------------------------------------------------------------------------------------------------------------
OzDM.EH.S_EVENT_MARK_REMOVE = {}
function OzDM.EH.S_EVENT_MARK_REMOVE:onEvent(EventData)
    local EventWhiteList = world.event.S_EVENT_MARK_REMOVE or world.event.S_EVENT_MARK_REMOVED or 27 --SETS THE EVENT WE ARE LOOKING FOR
    if EventData.id == EventWhiteList then
        local lowerTXT = EventData.text:lower()
        local PrefixCheck = string.sub(lowerTXT,1,1)
        if(PrefixCheck == OzDM.COMMAND_PREFIX) then
            if (string.find(lowerTXT,"coord") and OzDM.ENABLE_COORD == true)             then MarkerCoOrd(EventData)
               elseif (string.find(lowerTXT,"smoke") and OzDM.ENABLE_SMOKE == true)      then MarkerSmoke(EventData)
               elseif (string.find(lowerTXT,"flare") and OzDM.ENABLE_FLARE == true)      then MarkerFlare(EventData)   
               elseif (string.find(lowerTXT,"illum") and OzDM.ENABLE_ILLUM == true)      then MarkerIllum(EventData)
               elseif (string.find(lowerTXT,"clean") and OzDM.ENABLE_CLEAN == true)      then MarkerClean(EventData)
               elseif (string.find(lowerTXT,"isr") and OzDM.ENABLE_ISR == true)          then MarkerAirSupportTasking(EventData)
               elseif (string.find(lowerTXT,"tanker") and OzDM.ENABLE_TANKER == true)    then MarkerAirSupportTasking(EventData)
               elseif (string.find(lowerTXT,"awacs") and OzDM.ENABLE_AWACS == true)      then MarkerAirSupportTasking(EventData)
               elseif (string.find(lowerTXT,"mark") and OzDM.ENABLE_MARK == true)        then MarkTerrainObject(EventData,false)
	       elseif (string.find(lowerTXT,"mot") and OzDM.ENABLE_MARK == true)        then MarkTerrainObject(EventData,true)
               elseif (string.find(lowerTXT,"smite") and OzDM.ENABLE_EXPLOSION == true) then MarkerExplosion(EventData.pos,lowerTXT)
            end
        end
    end
end
world.addEventHandler(OzDM.EH.S_EVENT_MARK_REMOVE)

trigger.action.outText(
    'Map Marker Commands Initialized',
    3,
    false)

env.info('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
env.info('!!!! MAP MARKER COMMANDS INITIALIZED !!!!!')
env.info('!!!!!!!!!!! by OzDeaDMeaT !!!!!!!!!!!!!!!!')
env.info('!!!!!!!!!!! Version: ' .. scriptVer ..' !!!!!!!!!!!!!!!!')
