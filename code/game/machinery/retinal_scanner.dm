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

// SCAN FUNCTIONS
/obj/machinery/retinal_scanner/proc/retinal_scan(target)
	var found = 0 //if we found the user record
	var targetdna = ""
	var/datum/data/record/retacc = null

	if(istype(target, /mob/living/carbon)) //Scanning a body
		var /mob/living/carbon/T = target
		targetdna = T.dna.unique_enzymes //DNA of the user
		retacc = null //The retinal access record, if we found one
		for(var/datum/data/record/RA in data_core.retinalaccess) //For each retinal record, check if it matches our user's dna
			if((RA.fields["b_dna"] == targetdna))
				found = 1 //If it does, we found our person
				retacc = RA
				break

	if(istype(target,/obj/item/bodypart/head)) //Scanning a head
		var /obj/item/bodypart/head/T = target
		if(!T.owner)
			targetdna = T.b_dna
			retacc = null //The retinal access record, if we found one
			for(var/datum/data/record/RA in data_core.retinalaccess) //For each retinal record, check if it matches our head's dna
				if((RA.fields["b_dna"] == targetdna))
					found = 1 //If it does, we found our person
					retacc = RA
					break

	if(found)
		//Ripped from modules/jobs/access.dm with minor adjustments
		var/list/acc = retacc.fields["access"] //Get the access list from the record

		var/list/L = req_access
		if(!L.len && (!req_one_access || !req_one_access.len)) //no requirements
			return 1

		for(var/req in req_access)
			if(!(req in acc)) //doesn't have this access
				return 0
		if(req_one_access && req_one_access.len)
			for(var/req in req_one_access)
				if(req in acc) //has an access from the single access list
					return 1
			return 0
		return 1
	else
		return 0

/obj/machinery/retinal_scanner/proc/scan_success()
	if(driver)
		driver.pulsed()
		use_power(5)
	playsound(src.loc, 'sound/machines/retinal_scan_pass.ogg', 50, 0)

/obj/machinery/retinal_scanner/proc/scan_failure()
	use_power(5)
	playsound(src.loc, 'sound/machines/retinal_scan_denied.ogg', 50, 0)
	flick("denied", src)


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
	//Scanning with head
	if(istype(W, /obj/item/bodypart/head))
		if(!stat && clearance && driver && !scanning) // -[ABSOLUTELY READY]-
			flick("scan", src)
			var /obj/item/bodypart/head/H = W
			if(!H.b_dna) //Dunno how this'd happens, but as a precaution.
				scan_failure()
				user << "<span class='notice'>The scanner doesn't recognise you.</span>"
				return

			scanning = 1 //Scan start


			user.visible_message("<span class='warning'>[user.name] holds [H.name] up to the retinal scanner!</span>",\
									   "<span class='notice'>You hold [H.name] up to retinal scanner.</span>")

			if(do_after(user,10,needhand = 0,target = src)) //takes a second to scan

				if(retinal_scan(H))
					scan_success()
				else
					scan_failure()
					user << "<span class='warning'>Access Denied</span>"
			else
				user << "<span class='notice'>Scan Interupted.</span>"



			scanning = 0 //Scan finish

		else if((!clearance || !driver) && !(stat & MAINT)) //Missing pieces but closed
			user << "<span class='notice'>The device isn't ready for use.</span>"
		else if(stat & BROKEN) // -[BROKEN]-
			user << "<span class='warning'>It's too damaged to be used.</span>"
		else // -[OPEN OR OFF]-
			user << "<span class='notice'>Nothing Happens.</span>"


	//Screwdriver based interaction
	else if(istype(W, /obj/item/weapon/screwdriver))
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

	//Crowbar based interaction
	else if(istype(W, /obj/item/weapon/crowbar))
		// -[BROKEN]-
		if(stat & BROKEN)
			if(do_after(user, 30, target = src))
				new /obj/item/stack/sheet/metal(loc)
				user.visible_message(\
					"[user.name] salvages [src] using [W]",\
					"<span class='notice'>You salvage what you can of the retinal scanner.</span>")
				playsound(src.loc, W.usesound, 50, 1)
				qdel(src)
		// -[OPEN]-
		else if(stat & MAINT)
			if(do_after(user, 30, target = src))
				new /obj/item/wallframe/retinal_scanner(loc)
				user.visible_message(\
					"[user.name] removes [src] from the wall using [W]",\
					"<span class='notice'>You detach the retinal scanner from the wall.</span>")
				user << "<span class='notice'>The clearance board is destroyed in the process</span>"
				playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
				qdel(src)
		// -[NOT BROKEN OR OPEN]-
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
				playsound(src.loc, 'sound/machines/click.ogg', 50, 0)
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
		if(!stat && clearance && driver && !scanning) // -[ABSOLUTELY READY]-
			flick("scan", src)

			if(!user.has_dna()) //Dunno how this'd happens, but as a precaution.
				scan_failure()
				user << "<span class='notice'>The scanner doesn't recognise you.</span>"
				return

			scanning = 1 //Scan start

			if(do_after(user,10,needhand = 0,target = src)) //takes a second to scan
				if(istype(user, /mob/living/carbon))
					if(retinal_scan(user))
						scan_success()
					else
						scan_failure()
						user << "<span class='warning'>Access Denied</span>"
			else
				user << "<span class='notice'>Scan Interupted.</span>"

			scanning = 0 //Scan finish

		else if((!clearance || !driver) && !(stat & MAINT)) //Missing pieces but closed
			user << "<span class='notice'>The device isn't ready for use.</span>"
		else if(stat & BROKEN) // -[BROKEN]-
			user << "<span class='warning'>It's too damaged to be used.</span>"
		else // -[OPEN OR OFF]-
			user << "<span class='notice'>Nothing Happens.</span>"


/obj/machinery/retinal_scanner/MouseDrop_T(mob/target, mob/user)
	if(user == target)
		attack_hand(user) //pointless self drag
		return

	if(scanning) //Cant start another scan while one is running
		return

	//Both parties must be near the scanner
	if(user.stat || user.lying || !Adjacent(user) || !user.Adjacent(target) || !iscarbon(target))
		return

	//Only humans, monkeys and ayyliums have dna and bodyparts
	if(!istype(target, /mob/living/carbon))
		user << "<span class='notice'>The scanner doesn't recognise them.</span>"
		return

	var/mob/living/carbon/T = target

	//Gotta have a head to scan the eyes
	var foundhead = 0
	for(var/obj/item/bodypart/BP in T.bodyparts)
		if(istype(BP, /obj/item/bodypart/head))
			foundhead = 1
			break

	if(!foundhead)
		user << "<span class='warning'>There are no eyes to scan!</span>"
		return


	src.add_fingerprint(user)
	if(!stat && clearance && driver && !scanning) // -[ABSOLUTELY READY]-
		flick("scan", src)

		if(!T.has_dna()) //Dunno how this'd happens, but as a precaution.
			scan_failure()
			user << "<span class='notice'>The scanner doesn't recognise them.</span>"
			return

		scanning = 1 //Scan start

		user.visible_message("<span class='warning'>[user.name] holds [target.name] against the retinal scanner!</span>",\
									   "<span class='notice'>You hold [target.name] against the retinal scanner.</span>")

		var passed = 0 //Whether or not do_after succeeded

		if(T.stat || T.weakened || T.stunned) //If the target would instantly fail do_after on their own, user does do_while instead
			var startloc = T.loc //Due to the target not being involved in the do_after, we need a way to check they're still there at the end
			if(do_after(user,10,needhand = 0,target = src)) //takes a second to scan
				if(T.loc == startloc) //If they haven't moved since we started
					passed = 1
		else
			if(do_after(T,10,needhand = 0,target = src)) //takes a second to scan
				passed = 1

		if(passed)
			if(retinal_scan(T))
				scan_success()
			else
				scan_failure()
				user << "<span class='warning'>Access Denied</span>"
		else
			user << "<span class='notice'>Scan Interupted.</span>"

		scanning = 0 //Scan finish

	else if((!clearance || !driver) && !(stat & MAINT)) //Missing pieces but closed
		user << "<span class='notice'>The device isn't ready for use.</span>"
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
				user << "<span class='warning'>   *NO CLEARANCE RESTRICTIONS SET!</span>"
			if(!driver)
				user << "<span class='warning'>   *NO DOOR CONTROL BOARD!</span>"
	else if(stat & MAINT)
		user << "It is powered down due to the side panel being open. [(!clearance || !driver)?"There are components clearly missing.":""]"
	else if(stat & BROKEN)
		user << "It is severely damaged and requires repair. The side panel is bent open."
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