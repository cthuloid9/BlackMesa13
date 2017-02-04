/*

### This file contains a list of all the areas in your station. Format is as follows:

/area/CATEGORY/OR/DESCRIPTOR/NAME 	(you can make as many subdivisions as you want)
	name = "NICE NAME" 				(not required but makes things really nice)
	icon = "ICON FILENAME" 			(defaults to areas.dmi)
	icon_state = "NAME OF ICON" 	(defaults to "unknown" (blank))
	requires_power = 0 				(defaults to 1)
	music = "music/music.ogg"		(defaults to "music/music.ogg")

NOTE: there are two lists of areas in the end of this file: centcom and station itself. Please maintain these lists valid. --rastaf0

*/

area/blackmesa
	icon = 'icons/turf/BM13_areas.dmi'
	icon_state = "blackmesalogo"

//-----------------------------------------------------//

////////////
//TEMPLATE//
////////////
/area/blackmesa/template
	name = "\improper Blackmesa Template Area"
	icon = 'icons/turf/BM13_areas.dmi'
	icon_state = "template"

//-----------------------------------------------------//

////////////
//SECTOR C//
////////////
/area/blackmesa/sector_c
	name = "sector catagory"
	icon_state = "sector-c"

/area/blackmesa/sector_c/primary_enterance
	name = "\improper Primary Enterance"
	icon_state = "prim-enter"

/area/blackmesa/sector_c/waiting_platform
	name = "\improper Waiting Platform"
	icon_state = "waiting-plat-c"

/area/blackmesa/sector_c/main_desk
	name = "\improper Main Desk"
	icon_state = "main-desk"

/area/blackmesa/sector_c/main_circle_hall
	name = "\improper Main Circle Hallway"
	icon_state = "main-circle-hall"

/area/blackmesa/sector_c/bathroom
	name = "\improper Bathroom"
	icon_state = "bathroom-c"

/area/blackmesa/sector_c/sec_checkpoint_1
	name = "\improper Security Checkpoint"
	icon_state = "sec-check-1"

/area/blackmesa/sector_c/tram
	name = "\improper Bathroom"
	icon_state = "tram-c"

/area/blackmesa/sector_c/core
	name = "\improper Core"
	icon_state = "core"

/area/blackmesa/sector_c/locker_room
	name = "\improper Locker Room"
	icon_state = "locker-room-c"

/area/blackmesa/sector_c/hev_suit_room
	name = "\improper H.E.V Suit Room"
	icon_state = "hev-room-c"

/area/blackmesa/sector_c/staff_lounge
	name = "\improper Staff Lounge"
	icon_state = "staff-lougne-c"

/area/blackmesa/sector_c/staff_kitchen
	name = "\improper Staff Kitchen"
	icon_state = "staff-kitchen-c"

/area/blackmesa/sector_c/staff_hallway_1
	name = "\improper Staff Hallway"
	icon_state = "staff-hallway-1-c"

/area/blackmesa/sector_c/elevator_enterance
	name = "\improper Elevator Enterance"
	icon_state = "elevator-enter-c"

/area/blackmesa/sector_c/elevator_exit
	name = "\improper Bathroom"
	icon_state = "elevator-exit-c"

	///////////////
	//ABOVEGROUND//
	///////////////

/area/blackmesa/aboveground
	name = "sector category"
	icon_state = "aboveground"

/area/blackmesa/aboveground/desert
	name = "\improper Desert"
	icon_state = "desert"

/area/blackmesa/aboveground/waste_processing_plant
	name = "\improper Waste Processing Entrance"
	icon_state = "waste_enter"