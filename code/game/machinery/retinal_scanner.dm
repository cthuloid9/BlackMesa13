/obj/machinery/retinal_scanner
	name = "retinal scanner"
	desc = "A retinal scanner."
	icon = 'icons/obj/retinal_scanner.dmi'
	icon_state = "ready"
	power_channel = ENVIRON
	obj_integrity = 170
	max_integrity = 170
	integrity_failure = 50
	var/id = null
	var/clearance = null //Whether or not the device has had clearance set
	var/specialfunctions = OPEN // Bitflag, see assembly file
	var/obj/item/device/assembly/control/airlock/driver = null //Airlock Control
	armor = list(melee = 50, bullet = 50, laser = 50, energy = 50, bomb = 10, bio = 100, rad = 100, fire = 90, acid = 70)
	anchored = 1
	use_power = 1
	idle_power_usage = 2

	//var/condition = "normal"
	var/scanning = 0

// CONSTRUCTOR
/obj/machinery/retinal_scanner/New(loc, ndir = 0, built = 0)
	..()
	if(built)
		setDir(ndir)
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -24 : 24)
		pixel_y = (dir & 3)? (dir ==1 ? -24 : 24) : 0
		stat |= MAINT
		update_icon()
	else
		driver = new(src)
		driver.id = id
		driver.specialfunctions = OPEN

		src.check_access(null) //convert req_access_txt to req_access list()

		if(req_access.len || req_one_access.len) //If we have any access requirements
			clearance = 1

// ICON UPDATE
/obj/machinery/retinal_scanner/update_icon()
	if(!stat) //No conditions
		if(clearance && driver) //Configured and ready for use
			icon_state = "ready"
		else //No access set or missing control board
			icon_state = "not_ready"
	else if (stat & BROKEN) //Being broken overrides all other states
		icon_state = "broken"
	else if (stat & MAINT) //Being open overrieds being off, as both look the same
		icon_state = "open"
	else if(stat & NOPOWER || stat & EMPED)
		icon_state = "off"

// INTERACTION
/obj/machinery/retinal_scanner/attackby(obj/item/W, mob/user, params)
	//Screwdriver based interaction
	if(istype(W, /obj/item/weapon/screwdriver))
		// -[BROKEN OPEN]-
		if(stat & BROKEN)
			user << "<span class='warning'>The unit is so damaged that the side panel is already bent open.</span>"
		// -[PANEL OPEN]-
		else if(stat & MAINT)
			stat &= ~MAINT //remove MAINT flag
			playsound(src.loc, W.usesound, 50, 1)
			user << "<span class='notice'>You fasten the side panel.</span>"
			update_icon()
		// -[NORMAL OR OFF]-
		else
			stat |= MAINT //turn MAINT flag on
			playsound(src.loc, W.usesound, 50, 1)
			user << "<span class='notice'>You unfasten the side panel.</span>"
			update_icon()

	//Wrench based interaction
	else if(istype(W, /obj/item/weapon/wrench))
		// -[BROKEN OR OPEN]-
		if(stat & MAINT || stat & BROKEN)
			if(driver) //If there's a card inside
				user.put_in_hands(driver)
				driver.add_fingerprint(driver)

				src.driver = null
				user.visible_message("[user.name] removes the control board from [src.name]!",\
									 "<span class='notice'>You remove the control board.</span>")
				playsound(src.loc, W.usesound, 50, 1)
			else //No card
				user << "<span class='notice'>There is no control board to remove.</span>"
		// -[NORMAL OR OFF]-
		else
			user << "<span class='warning'>You need to open the side panel before you can do that.</span>"

	//Assembly based interaction
	else if(istype(W, /obj/item/device/assembly/))
		// -[BROKEN OR OPEN]-
		if(stat & MAINT || stat & BROKEN)
			if(!driver)
				if(!istype(W, /obj/item/device/assembly/control/airlock)) //The assembly isn't a door control
					user << "<span class='warning'>The retinal scanner and this device are incompatible.</span>"
				else //The assembly IS a door control
					if(!user.drop_item())
						return
					W.forceMove(src)
					driver = W
					user.visible_message(\
						"[user.name] has inserted the control board to [src.name].",\
						"<span class='notice'>You insert the control board.</span>")
					playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
			else
				user << "<span class='notice'>The retinal scanner already contains a control board.</span>"
		else
			user << "<span class='notice'>You cannot do this while the side panel is closed.</span>"

	//Clearance board based interaction
	else if(istype(W, /obj/item/weapon/electronics/airlock))
		if(stat & MAINT || stat & BROKEN)
			if(!clearance)
				if(!user.drop_item())
					return

				//define item as a board we can refer to
				var/obj/item/weapon/electronics/airlock/board = W

				//Copy access from the card
				if(board.one_access)
					req_one_access = board.accesses
				else
					req_access = board.accesses

				// This action is permanent so that not any random person can come along and change the access for a button.
				// Scanners that are spawned in the map are set by the mapper and those which are build are locked once set up.
				user.visible_message(\
					"[user.name] has inserted the clearance board to [src.name].",\
					"<span class='notice'>You insert the clearance board and it permenantly locks into place.</span>")
				playsound(src.loc, 'sound/machines/lock_into_place.ogg', 50, 1)
				qdel(board) //we dont need the card anymore

				clearance = 1 //Thats taken care of
			else
				user << "<span class='notice'>The retinal scanner already has a clearance board.</span>"
		else
			user << "<span class='notice'>You cannot do this while the side panel is closed.</span>"

	//REPAIR INTERACTION
	else if(istype(W, /obj/item/wallframe/retinal_scanner/))
		if(stat & BROKEN)
			user << "<span class='notice'>You start to repair the retinal scanner...</span>"
			if(do_after(user, 30, target = src))
				user.visible_message("[user.name] repairs the retinal scanner.",\
							"<span class='notice'>You repair the retinal scaner.</span>")
				stat &= ~BROKEN //remove broken
				qdel(W)
				obj_integrity = max_integrity
				update_icon()
		else
			user << "<span class='notice'>The device isn't broken.</span>"

	else //OTHER INTERACTIONS
		return ..()

/obj/machinery/retinal_scanner/attack_hand(mob/user)
	if(!user)
		return
	if(usr == user && (!issilicon(user)))
		src.add_fingerprint(user)
		if(!stat) // -[NOT OPEN, BROKEN OR OFF]-
			flick("scan", src)
			if(do_after(user,20,needhand = 0,target = src)) //takes a second to scan
				if(driver)
					driver.pulsed()
					use_power(5)
		else if(stat & BROKEN) // -[BROKEN]-
			user << "<span class='warning'>It's too damaged to be used.</span>"
		else // -[OPEN OR OFF]-
			user << "<span class='notice'>Nothing Happens.</span>"




// EXAMINE
/obj/machinery/retinal_scanner/examine(mob/user)
	..()
	if(!stat) //No statuses
		if(clearance && driver)
			user << "It is powered and functioning normally."
		else //Something is missing
			user << "<span class='warning'>It is displaying an error:</span>"
			if(!clearance)
				user << "<span class='warning'>   *NO CLEARANCE RESTRICTIONS SET</span>"
			if(!driver)
				user << "<span class='warning'>   *NO DOOR CONTROL BOARD</span>"
	else if(stat & MAINT)
		user << "It is powered down due to the side panel being open[driver?". It contains a control board":""]."
	else if(stat & BROKEN)
		user << "It is severely damaged and requires repair. The side panel is bent open[driver?" and the control board is accessable.":"."]"
	else if(stat & NOPOWER || stat & EMPED)
		user << "It is lacking power."


// DAMAGE
/obj/machinery/retinal_scanner/obj_break(damage_flag)
	if(!(flags & NODECONSTRUCT))
		stat |= BROKEN
		scanning = 0
		update_icon()

/obj/machinery/retinal_scanner/deconstruct(disassembled = TRUE)
	if(!(flags & NODECONSTRUCT))
		visible_message("<span class='warning'>The retinal scanner is destroyed!</span>")
		update_icon()

// POWER CHECK
/obj/machinery/retinal_scanner/power_change()
	..()
	update_icon()

// ITEM FRAME FORM
/obj/item/wallframe/retinal_scanner
	name = "retinal scanner frame"
	desc = "Used for building retinal scanners."
	icon = 'icons/obj/retinal_scanner.dmi'
	icon_state = "frame"
	result_path = /obj/machinery/retinal_scanner
	materials = list(MAT_METAL=MINERAL_MATERIAL_AMOUNT)


//Deconstruct frames back into sheets
/obj/item/wallframe/retinal_scanner/attack_self(mob/user)
	var/obj/item/stack/sheet/metal/S = new(src.loc,2)
	user.put_in_hands(S)
	S.add_fingerprint(user)
	qdel(src)