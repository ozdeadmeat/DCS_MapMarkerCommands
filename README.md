DCS World Map Marker Commands This script is designed as a quick way to add the ability to order tankers, AWACS and Drones around the airspace quickly and easily with little to no LUA experience.

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
        
    - Explode Command (!xplode)             : Causes an explosion at the marker location
        -- Example> !xplode:250
To utilize the demo mission create a folder in your DCS Profile in the location below

"DCSPROFILEROOT"\Missions\OzDM-MMC

Put the mission and the MapMarkerCommands.lua files into this location and open them up in the Mission Editor and play mission. Furhter details on configuration are in the MapMarkerCommands.lua file.

Important Note: Your DCS will need to be desanitized to use the demo mission.

BUG: AI Drones do not use laser codes they are assigned

Additional features I would like to add:

- Ability to change speed and altitude of Drones DONE!!
- Add ISR Drones retasking DONE!!
- Change Radio Freq (DONE VIA SCRIPT)
- Change Speed and Altitude DONE!!
- Draw Orbit Marker (RaceTrack or Circular) DONE!!
- Add Tanker retasking DONE!!
- Change Radio Freq (DONE VIA SCRIPT)
- Change TACAN (DONE VIA SCRIPT)
- Change Speed and Altitude DONE!!
- Draw Orbit Marker (RaceTrack or Circular) DONE!!
- Add AWACs retasking DONE!!
- Change Radio Freq (DONE VIA SCRIPT)
- Change TACAN (DONE VIA SCRIPT)
- Change Speed and Altitude DONE!!
- Draw Orbit Marker (RaceTrack or Circular) DONE!!
CoOrdinate message DONE!!
