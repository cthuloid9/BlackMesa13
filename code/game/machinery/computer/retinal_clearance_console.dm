/obj/machinery/computer/retinalclearance_console
	name = "retinal clearance console"
	desc = "Used to manage Black Mesa personnel's retinal clearance profiles."
	icon_screen = "retinal"
	icon_keyboard = "retinal_key"
	req_one_access = list(access_security, access_forensics_lockers)
	circuit = /obj/item/weapon/circuitboard/computer/secure_data
	var/obj/item/weapon/card/id/scan = null
	var/authenticated = null
	var/rank = null
	var/screen = null
	var/datum/data/record/active1 = null
	var/datum/data/record/active2 = null
	var/a_id = null
	var/temp = null
	var/printing = null
	var/can_change_id = 0
	var/list/Perp
	var/tempname = null
	//Sorting Variables
	var/sortBy = "name"
	var/order = 1 // -1 = Descending - 1 = Ascending


/obj/machinery/computer/retinalclearance_console/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/weapon/card/id))
		if(!scan)
			if(!user.drop_item())
				return
			O.loc = src
			scan = O
			user << "<span class='notice'>You insert [O].</span>"
		else
			user << "<span class='warning'>There's already an ID card in the console.</span>"
	else
		return ..()

//Someone needs to break down the dat += into chunks instead of long ass lines.
/obj/machinery/computer/retinalclearance_console/attack_hand(mob/user)
	if(..())
		return
	if(src.z > 6)
		user << "<span class='boldannounce'>Unable to establish a connection</span>: \black You're too far away from the station!"
		return
	var/dat

	if(temp)
		dat = text("<TT>[]</TT><BR><BR><A href='?src=\ref[];choice=Clear Screen'>Clear Screen</A>", temp, src)
	else
		dat = text("Confirm Identity: <A href='?src=\ref[];choice=Confirm Identity'>[]</A><HR>", src, (scan ? text("[]", scan.name) : "----------"))
		if(authenticated)
			switch(screen)
				if(1)

					//body tag start + onload and onkeypress (onkeyup) javascript event calls
					dat += "<body onload='selectTextField(); updateSearch();' onkeyup='updateSearch();'>"
					//search bar javascript
					dat += {"

		<head>
			<script src="jquery.min.js"></script>
			<script type='text/javascript'>

				function updateSearch(){
					var filter_text = document.getElementById('filter');
					var filter = filter_text.value.toLowerCase();

					if(complete_list != null && complete_list != ""){
						var mtbl = document.getElementById("maintable_data_archive");
						mtbl.innerHTML = complete_list;
					}

					if(filter.value == ""){
						return;
					}else{
						$("#maintable_data").children("tbody").children("tr").children("td").children("input").filter(function(index)
						{
							return $(this)\[0\].value.toLowerCase().indexOf(filter) == -1
						}).parent("td").parent("tr").hide()
					}
				}

				function selectTextField(){
					var filter_text = document.getElementById('filter');
					filter_text.focus();
					filter_text.select();
				}

			</script>
		</head>


	"}
					dat += {"
<p style='text-align:center;'>"}
					dat += text("<A href='?src=\ref[];choice=New Personnel Profile'>New Personnel Profile</A><BR>", src)
					//search bar
					dat += {"
						<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable'>
							<tr id='search_tr'>
								<td align='center'>
									<b>Search:</b> <input type='text' id='filter' value='' style='width:300px;'>
								</td>
							</tr>
						</table>
					"}
					dat += {"
</p>
<table style="text-align:center;" cellspacing="0" width="100%">
<tr>
<th>Records:</th>
</tr>
</table>

<span id='maintable_data_archive'>
<table id='maintable_data' style="text-align:center;" border="1" cellspacing="0" width="100%">
<tr>
<th><A href='?src=\ref[src];choice=Sorting;sort=name'>Name</A></th>
<th><A href='?src=\ref[src];choice=Sorting;sort=id'>ID</A></th>
<th><A href='?src=\ref[src];choice=Sorting;sort=rank'>Rank</A></th>
</tr>"}
					if(!isnull(data_core.general))
						for(var/datum/data/record/R in sortRecord(data_core.general, sortBy, order))
							var/background = "'background-color:#4F7529;'"


							dat += "<tr style=[background]>"
							dat += text("<td><input type='hidden' value='[] [] [] '></input><A href='?src=\ref[];choice=Browse Record;d_rec=\ref[]'>[]</a></td>", R.fields["name"], R.fields["id"], R.fields["rank"], src, R, R.fields["name"])
							dat += text("<td>[]</td>", R.fields["id"])
							dat += text("<td>[]</td>", R.fields["rank"])
						dat += {"
						</table></span>
						<script type='text/javascript'>
							var maintable = document.getElementById("maintable_data_archive");
							var complete_list = maintable.innerHTML;
						</script>
						<hr width='75%' />"}
					dat += text("<A href='?src=\ref[];choice=Record Maintenance'>Record Maintenance</A><br><br>", src)
					dat += text("<A href='?src=\ref[];choice=Log Out'>{Log Out}</A>",src)
				if(2)
					dat += "<B>Records Maintenance</B><HR>"
					dat += "<BR><A href='?src=\ref[src];choice=Delete All Records'>Delete All Records</A><BR><BR><A href='?src=\ref[src];choice=Return'>Back</A>"
				if(3)
					dat += "<font size='4'><b>Retinal Profile</b></font><br>"
					if(istype(active1, /datum/data/record) && data_core.general.Find(active1)) //GENERAL RECORD
						if(istype(active1.fields["photo_front"], /obj/item/weapon/photo))
							var/obj/item/weapon/photo/P1 = active1.fields["photo_front"]
							user << browse_rsc(P1.img, "photo_front")
						if(istype(active1.fields["photo_side"], /obj/item/weapon/photo))
							var/obj/item/weapon/photo/P2 = active1.fields["photo_side"]
							user << browse_rsc(P2.img, "photo_side")
						dat += {"<table><tr><td><table>
						<tr><td>Name:</td><td><A href='?src=\ref[src];choice=Edit Field;field=name'>&nbsp;[active1.fields["name"]]&nbsp;</A></td></tr>
						<tr><td>ID:</td><td><A href='?src=\ref[src];choice=Edit Field;field=id'>&nbsp;[active1.fields["id"]]&nbsp;</A></td></tr>
						<tr><td>Sex:</td><td>&nbsp;[active1.fields["sex"]]&nbsp;</td></tr>
						<tr><td>Age:</td><td>&nbsp;[active1.fields["age"]]&nbsp;</td></tr>"}
						if(config.mutant_races)
							dat += "<tr><td>Species:</td><td>&nbsp;[active1.fields["species"]]&nbsp;</td></tr>"
						dat += {"<tr><td>Rank:</td><td>&nbsp;[active1.fields["rank"]]&nbsp;</td></tr>
						</table></td>
						<td><table><td align = center><a href='?src=\ref[src];choice=Edit Field;field=show_photo_front'><img src=photo_front height=80 width=80 border=4></a><br>
						<a href='?src=\ref[src];choice=Edit Field;field=upd_photo_front'>Update front photo</a></td>
						<td align = center><a href='?src=\ref[src];choice=Edit Field;field=show_photo_side'><img src=photo_side height=80 width=80 border=4></a><br>
						<a href='?src=\ref[src];choice=Edit Field;field=upd_photo_side'>Update side photo</a></td></table>
						</td></tr></table></td></tr></table>"}
					else
						dat += "<br>General Record Lost!<br>"
					if((istype(active2, /datum/data/record) && data_core.retinalaccess.Find(active2))) //ACCESS RECORD
						var/header = ""

						//var/target_name = active2.fields["name"]
						//var/target_owner = target_name
						var/target_rank = active1.fields["rank"]





						header += "<hr>"

						var/jobs_all = ""
						var/list/alljobs = list("Unassigned")
						alljobs += get_all_jobs() + "Custom"
						for(var/job in alljobs)
							jobs_all += "<a href='?src=\ref[src];choice=assign;assign_target=[job]'>[replacetext(job, " ", "&nbsp")]</a> " //make sure there isn't a line break in the middle of a job


						var/body



						var/accdesc = text("")
						var/jobs = text("")

						accdesc += {"<script type="text/javascript">
											function markRed(){
												var nameField = document.getElementById('namefield');
												nameField.style.backgroundColor = "#FFDDDD";
											}
											function markGreen(){
												var nameField = document.getElementById('namefield');
												nameField.style.backgroundColor = "#DDFFDD";
											}
											function showAll(){
												var allJobsSlot = document.getElementById('alljobsslot');
												allJobsSlot.innerHTML = "<a href='#' onclick='hideAll()'>hide</a><br>"+ "[jobs_all]";
											}
											function hideAll(){
												var allJobsSlot = document.getElementById('alljobsslot');
												allJobsSlot.innerHTML = "<a href='#' onclick='showAll()'>show</a>";
											}
										</script>"}
						accdesc += "<form name='cardcomp' action='?src=\ref[src]' method='get'>"
						accdesc += "<input type='hidden' name='src' value='\ref[src]'>"
						accdesc += "<input type='hidden' name='choice' value='reg'>"
						accdesc += "</form>"
						accdesc += "<b>Assignment: [target_rank]</b> "

						jobs += "<span id='alljobsslot'><a href='#' onclick='showAll()'>[target_rank]</a></span>" //CHECK THIS


						var/accesses = ""


						accesses += "<div align='center'><b>Clearance</b></div>"
						accesses += "<table style='width:100%'>"
						accesses += "<tr>"
						for(var/i = 1; i <= 7; i++)
							if(authenticated == 1)
								continue
							accesses += "<td style='width:14%'><b>[get_region_accesses_name(i)]:</b></td>"
						accesses += "</tr><tr>"
						for(var/i = 1; i <= 7; i++)
							if(authenticated == 1 )
								continue
							accesses += "<td style='width:14%' valign='top'>"
							for(var/A in get_region_accesses(i))
								if(A in active2.fields["access"])
									accesses += "<a href='?src=\ref[src];choice=access;access_target=[A];allowed=0'><font color=\"red\">[replacetext(get_access_desc(A), " ", "&nbsp")]</font></a> "
								else
									accesses += "<a href='?src=\ref[src];choice=access;access_target=[A];allowed=1'>[replacetext(get_access_desc(A), " ", "&nbsp")]</a> "
								accesses += "<br>"
							accesses += "</td>"
						accesses += "</tr></table>"
						body = "[accdesc]<br>[jobs]<br><br>[accesses]" //CHECK THIS


						dat += "<tt>[header][body]<hr><br></tt>"

					dat += "<A href='?src=\ref[src];choice=Return'>Back</A><BR>"
				else
		else
			dat += text("<A href='?src=\ref[];choice=Log In'>{Log In}</A>", src)
	var/datum/browser/popup = new(user, "secure_rec", "Retinal Clearance Console", 900, 680)
	popup.set_content(dat)
	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()
	return

/*Revised /N
I can't be bothered to look more of the actual code outside of switch but that probably needs revising too.
What a mess.*/
/obj/machinery/computer/retinalclearance_console/Topic(href, href_list)
	. = ..()
	if(.)
		return .
	if(!( data_core.general.Find(active1) ))
		active1 = null
	if(!( data_core.retinalaccess.Find(active2) ))
		active2 = null
	if(usr.contents.Find(src) || (in_range(src, usr) && isturf(loc)) || issilicon(usr) || IsAdminGhost(usr))
		usr.set_machine(src)
		switch(href_list["choice"])
// SORTING!
			if("Sorting")
				// Reverse the order if clicked twice
				if(sortBy == href_list["sort"])
					if(order == 1)
						order = -1
					else
						order = 1
				else
				// New sorting order!
					sortBy = href_list["sort"]
					order = initial(order)
//BASIC FUNCTIONS
			if("Clear Screen")
				temp = null

			if("Return")
				screen = 1
				active1 = null
				active2 = null

			if("Confirm Identity")
				if(scan)
					if(ishuman(usr) && !usr.get_active_held_item())
						usr.put_in_hands(scan)
					else
						scan.loc = get_turf(src)
					scan = null
				else
					var/obj/item/I = usr.get_active_held_item()
					if(istype(I, /obj/item/weapon/card/id))
						if(!usr.drop_item())
							return
						I.loc = src
						scan = I

			if("Log Out")
				authenticated = null
				screen = null
				active1 = null
				active2 = null

			if("Log In")
				if(issilicon(usr))
					var/mob/living/silicon/borg = usr
					active1 = null
					active2 = null
					authenticated = borg.name
					rank = "AI"
					screen = 1
				else if(IsAdminGhost(usr))
					active1 = null
					active2 = null
					authenticated = usr.client.holder.admin_signature
					rank = "Central Command"
					screen = 1
				else if(istype(scan, /obj/item/weapon/card/id))
					active1 = null
					active2 = null
					if(check_access(scan))
						authenticated = scan.registered_name
						rank = scan.assignment
						screen = 1
//RECORD FUNCTIONS
			if("Record Maintenance")
				screen = 2
				active1 = null
				active2 = null

			if("Browse Record")
				var/datum/data/record/R = locate(href_list["d_rec"])
				var/S = locate(href_list["d_rec"])
				if(!( data_core.general.Find(R) ))
					temp = "Record Not Found!"
				else
					for(var/datum/data/record/E in data_core.retinalaccess)
						if((E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"]))
							S = E
					active1 = R
					active2 = S
					screen = 3

			if("Add Entry")
				if(!( istype(active2, /datum/data/record) ))
					return
				var/a2 = active2
				var/t1 = stripped_multiline_input("Add Comment:", "Secure. records", null, null)
				if(!canUseRetinalAccessConsole(usr, t1, null, a2))
					return
				var/counter = 1
				while(active2.fields[text("com_[]", counter)])
					counter++
				active2.fields[text("com_[]", counter)] = text("Made by [] ([]) on [] [], []<BR>[]", src.authenticated, src.rank, worldtime2text(), time2text(world.realtime, "MMM DD"), year_integer+540, t1,)

//RECORD CREATE
			if("New Personnel Profile")
				//General Record
				var/datum/data/record/G = new /datum/data/record()
				G.fields["name"] = "New Record"
				G.fields["id"] = "[num2hex(rand(1, 1.6777215E7), 6)]"
				G.fields["rank"] = "Unassigned"
				G.fields["sex"] = "Male"
				G.fields["age"] = "Unknown"
				if(config.mutant_races)
					G.fields["species"] = "Human"
				G.fields["photo_front"] = new /icon()
				G.fields["photo_side"] = new /icon()
				G.fields["fingerprint"] = "?????"
				G.fields["p_stat"] = "Active"
				G.fields["m_stat"] = "Stable"
				data_core.general += G
				active1 = G

				//Security Record
				var/datum/data/record/R = new /datum/data/record()
				R.fields["name"] = active1.fields["name"]
				R.fields["id"] = active1.fields["id"]
				R.name = text("Security Record #[]", R.fields["id"])
				R.fields["criminal"] = "None"
				R.fields["mi_crim"] = list()
				R.fields["ma_crim"] = list()
				R.fields["notes"] = "No notes."
				data_core.security += R
				active2 = R

				//Medical Record
				var/datum/data/record/M = new /datum/data/record()
				M.fields["id"]			= active1.fields["id"]
				M.fields["name"]		= active1.fields["name"]
				M.fields["blood_type"]	= "?"
				M.fields["b_dna"]		= "?????"
				M.fields["mi_dis"]		= "None"
				M.fields["mi_dis_d"]	= "No minor disabilities have been declared."
				M.fields["ma_dis"]		= "None"
				M.fields["ma_dis_d"]	= "No major disabilities have been diagnosed."
				M.fields["alg"]			= "None"
				M.fields["alg_d"]		= "No allergies have been detected in this patient."
				M.fields["cdi"]			= "None"
				M.fields["cdi_d"]		= "No diseases have been diagnosed at the moment."
				M.fields["notes"]		= "No notes."
				data_core.medical += M

				//Retinal Access Record
				var/datum/data/record/A = new/datum/data/record()
				A.fields["id"]          = active1.fields["id"]
				A.fields["name"]        = active1.fields["name"]
				A.fields["access"]      = list()
				A.fields["b_dna"]       = "?????"
				data_core.retinalaccess += A

//ACCESS FUNCTIONS
			if("access")
				if(href_list["allowed"])
					if(authenticated)
						var/access_type = text2num(href_list["access_target"])
						var/access_allowed = text2num(href_list["allowed"])
						if(access_type in (get_all_accesses()))
							active2.fields["access"] -= access_type
							if(access_allowed == 1)
								active2.fields["access"] += access_type
							playsound(src, "terminal_type", 50, 0)

			if ("assign")
				if (authenticated)
					var/t1 = href_list["assign_target"]
					if(t1 == "Custom")
						var/newJob = reject_bad_text(input("Enter a custom job assignment.", "Assignment", active2.fields["rank"]), MAX_NAME_LEN)
						if(newJob)
							t1 = newJob

					else if(t1 == "Unassigned")
						active2.fields["access"] -= get_all_accesses()

					else
						var/datum/job/jobdatum
						for(var/jobtype in typesof(/datum/job))
							var/datum/job/J = new jobtype
							if(ckey(J.title) == ckey(t1))
								jobdatum = J
								break
						if(!jobdatum)
							usr << "<span class='error'>No log exists for this job.</span>"
							return

						active2.fields["access"] =  jobdatum.get_access()
					if (active2.fields["rank"])
						active2.fields["rank"] = t1
						playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)

//OTHER FIELD FUNCTIONS
			if("Edit Field")
				var/a1 = active1
				//var/a2 = active2

				switch(href_list["field"])
					if("name")
						if(istype(active1, /datum/data/record) || istype(active2, /datum/data/record))
							var/t1 = copytext(sanitize(input("Please input name:", "Secure. records", active1.fields["name"], null)  as text),1,MAX_MESSAGE_LEN)
							if(!canUseRetinalAccessConsole(usr, t1, a1))
								return
							if(istype(active1, /datum/data/record))
								active1.fields["name"] = t1
							if(istype(active2, /datum/data/record))
								active2.fields["name"] = t1
					if("id")
						if(istype(active2,/datum/data/record) || istype(active1,/datum/data/record))
							var/t1 = stripped_input(usr, "Please input id:", "Secure. records", active1.fields["id"], null)
							if(!canUseRetinalAccessConsole(usr, t1, a1))
								return
							if(istype(active1,/datum/data/record))
								active1.fields["id"] = t1
							if(istype(active2,/datum/data/record))
								active2.fields["id"] = t1
					if("show_photo_front")
						if(active1.fields["photo_front"])
							if(istype(active1.fields["photo_front"], /obj/item/weapon/photo))
								var/obj/item/weapon/photo/P = active1.fields["photo_front"]
								P.show(usr)
					if("upd_photo_front")
						var/icon/photo = get_photo(usr)
						if(photo)
							qdel(active1.fields["photo_front"])
							active1.fields["photo_front"] = photo
					if("show_photo_side")
						if(active1.fields["photo_side"])
							if(istype(active1.fields["photo_side"], /obj/item/weapon/photo))
								var/obj/item/weapon/photo/P = active1.fields["photo_side"]
								P.show(usr)
					if("upd_photo_side")
						var/icon/photo = get_photo(usr)
						if(photo)
							qdel(active1.fields["photo_side"])
							active1.fields["photo_side"] = photo



	add_fingerprint(usr)
	updateUsrDialog()
	return

/obj/machinery/computer/retinalclearance_console/proc/get_photo(mob/user)
	var/obj/item/weapon/photo/P = null
	if(issilicon(user))
		var/mob/living/silicon/tempAI = user
		var/datum/picture/selection = tempAI.GetPhoto()
		if(selection)
			P = new()
			P.photocreate(selection.fields["icon"], selection.fields["img"], selection.fields["desc"])
	else if(istype(user.get_active_held_item(), /obj/item/weapon/photo))
		P = user.get_active_held_item()
	return P

/obj/machinery/computer/retinalclearance_console/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return

	for(var/datum/data/record/R in data_core.retinalaccess)
		if(prob(10/severity))
			switch(rand(1,3))
				if(1)
					if(prob(10))
						R.fields["name"] = "[pick(lizard_name(MALE),lizard_name(FEMALE))]"
					else
						R.fields["name"] = "[pick(pick(first_names_male), pick(first_names_female))] [pick(last_names)]"
				if(2)
					if(prob(50))
						R.fields["access"] = list()
				if(3)
					if(prob(50))
						R.fields["b_dna"] = "\[CORRUPTED]"
			continue

		else if(prob(1))
			qdel(R)
			continue

	..(severity)

/obj/machinery/computer/retinalclearance_console/proc/canUseRetinalAccessConsole(mob/user, message1 = 0, record1, record2)
	if(user)
		if(authenticated)
			if(user.canUseTopic(src))
				if(!trim(message1))
					return 0
				if(!record1 || record1 == active1)
					if(!record2 || record2 == active2)
						return 1
	return 0
