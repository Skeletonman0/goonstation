/obj/machinery/computer/security
	name = "security cameras"
	icon_state = "security"
	circuit_type = /obj/item/circuitboard/security
	var/obj/machinery/camera/current = null
	var/mob/last_viewer = null
	var/list/obj/machinery/camera/favorites = list()
	var/const/favorites_Max = 8
	var/network = "SS13"
	var/maplevel = 1
	desc = "A computer that allows one to connect to a security camera network and view camera images."
	deconstruct_flags = DECON_MULTITOOL
	var/chui/window/security_cameras/window
	var/first_click = 1				//for creating the chui on first use
	var/skip_disabled = 1			//If we skip over disabled cameras in AI camera movement mode. Just leaving it in for admins maybe.
	flags = TGUI_INTERACTIVE
	light_r =1
	light_g = 0.7
	light_b = 0.74

	disposing()
		src.current?.disconnect_viewer(src.last_viewer)
		src.last_viewer = null
		src.current = null
		window = null
		..()

	process()
		..()
		if(window)
			for (var/client/subscriber in window.subscribers)
				var/list/viewports = subscriber.getViewportsByType("cameras: Viewport")
				if(BOUNDS_DIST(src, subscriber.mob) > 0 && length(viewports))
					boutput(subscriber,SPAN_ALERT("You are too far to see the screen."))
					subscriber.clearViewportsByType("cameras: Viewport")


	//This might not be needed. I thought that the proc should be on the computer instead of the mob switching, but maybe not
	proc/switchCamera(var/mob/living/user, var/obj/machinery/camera/C)
		if (!user?.client)
			return
		if (!C)
			src.remove_dialog(user)
			src.current?.disconnect_viewer(user)
			src.last_viewer = null
			src.current = null
			return FALSE

		if (isdead(user) || C.network != src.network)
			return FALSE
		if (src.current)
			src.current.move_viewer_to(user, C)
		else
			C.connect_viewer(user)
		src.current = C
		src.last_viewer = user
		return TRUE

	proc/move_viewport_to_camera(var/obj/machinery/camera/C, client/clint)
		var/datum/viewport/vp = clint.getViewportsByType("cameras: Viewport")[1]
		var/turf/T = get_turf(C)
		var/turf/closestPos = null
		for(var/i = 4, i >= 0 || !closestPos, i--)
			closestPos = locate(T.x - i, T.y + i, T.z)
			if(closestPos) break
		vp.SetViewport(closestPos, 8, 8)

	//moved out of global to only be used in sec computers
	proc/move_security_camera(direct, client/clint)
		var/mob/user = clint.mob
		if(!user) return

		//pretty sure this should never happen since I'm adding the first camera found to be the current, but just in cases
		if (!src.current)
			boutput(user, SPAN_ALERT("No current active camera. Select a camera as an origin point."))
			return


		// if(user.classic_move)
		var/obj/machinery/camera/closest = src.current
		if(istype(closest))
			//do
			if(direct & NORTH)
				closest = closest.c_north
			else if(direct & SOUTH)
				closest = closest.c_south
			if(direct & EAST)
				closest = closest.c_east
			else if(direct & WEST)
				closest = closest.c_west
			// while(closest && !closest.camera_status) //Skip disabled cameras - THIS NEEDS TO BE BETTER (static overlay imo)
		else	//This was for the AI, If there is no current camera, return to the camera nearest the user.
			closest = getCameraMove(user, direct, skip_disabled) //Ok, let's do this then.

		if(!closest)
			return
		else if (!closest.camera_status || closest.ai_only)
			boutput(user, SPAN_ALERT("ERROR. Cannot connect to camera."))
			playsound(src.loc, 'sound/machines/buzz-sigh.ogg', 10, 0)
			return
		if (length(clint.getViewportsByType("cameras: Viewport")))
			move_viewport_to_camera(closest, clint)
		else
			switchCamera(user, closest)

/obj/machinery/computer/security/console_upper
	icon = 'icons/obj/computerpanel.dmi'
	icon_state = "cameras1"
/obj/machinery/computer/security/console_lower
	icon = 'icons/obj/computerpanel.dmi'
	icon_state = "cameras2"

/obj/machinery/computer/security/wooden_tv
	icon_state = "security_det"
	circuit_type = /obj/item/circuitboard/security_tv

/obj/machinery/computer/security/wooden_tv/small
	name = "television"
	desc = "These channels seem to mostly be about robuddies. What is this, some kind of reality show?"
	network = "public"
	icon_state = "security_tv"
	circuit_type = /obj/item/circuitboard/small_tv
	density = FALSE

	power_change()
		return

// -------------------- VR --------------------
/obj/machinery/computer/security/wooden_tv/small/virtual
	desc = "It's making you feel kinda twitchy for some reason."
	icon = 'icons/effects/VR.dmi'
// --------------------------------------------

/obj/machinery/computer/security/telescreen
	name = "Telescreen"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "telescreen"
	network = "thunder"
	density = 0

	power_change()
		return

/obj/machinery/computer/security/attack_hand(var/mob/user)
	if (status & (NOPOWER|BROKEN) || !user.client)
		return
	src.ui_interact(user)
	/*if (first_click)
		window = new (src)
		first_click = 0

	//onclose(user, "camera_console", src)
	//winset(user, "camera_console.exitbutton", "command=\".windowclose \ref[src]\"")
	//winshow(user, "camera_console", 1)

	window.Subscribe( user.client )*/

/obj/machinery/computer/security/proc/create_viewport(mob/user, turf/T)
	if (!user.client)
		return
	if(BOUNDS_DIST(src, user) > 0)
		boutput(user,"<span class='alert'>You are too far to see the screen.</span>")
	else
		var/list/viewports = user.client.getViewportsByType("cameras: Viewport")
		if(length(viewports))
			boutput( user, "<b>You can only have 1 active viewport. Close the existing viewport to create another.</b>" )
			return
		var/datum/viewport/vp = new(user.client, "cameras: Viewport")
		var/turf/startPos = null
		for(var/i = 4, i >= 0 || !startPos, i--)
			startPos = locate(T.x - i, T.y + i, T.z)
			if(startPos) break
		vp.clickToMove = 1
		vp.SetViewport(startPos, 8, 8)

/obj/machinery/computer/security/ui_static_data(mob/user)
	. = list()
	var/list/L = list()
	for_by_tcl(C, /obj/machinery/camera)
		L.Add(C)

	L = camera_sort(L)
	. = list("current" = src.current,"windowName" = src.name)
	for (var/obj/machinery/camera/C in L)
		if (C.network == src.network)
			// Don't draw if it's in favorites or AI core/upload
			if (C.ai_only || !C.c_tag)
				continue
			if(C in src.favorites)
				.["favorites"] += list(list("camera"="\ref[C]",
				"name"="[C.c_tag][C.camera_status ? null : " (Deactivated)"]",
				"deactivated"=!C.camera_status))
			else
				.["cameras"] += list(list("camera"="\ref[C]",
				"name"="[C.c_tag][C.camera_status ? null : " (Deactivated)"]",
				"deactivated"=!C.camera_status))
/obj/machinery/computer/security/ui_interact(mob/user, datum/tgui/ui)
	ui = tgui_process.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CameraConsole")
		ui.open()

/obj/machinery/computer/security/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(. <= UI_CLOSE || !IN_RANGE(src, user, 1))
		user.client?.clearViewportsByType("cameras: Viewport")
		user.set_eye(null)
		user.reset_keymap()
		return UI_CLOSE

/obj/machinery/computer/security/ui_act(action, params)
	. = ..()
	if (.) return
	var/obj/machinery/camera/C = locate(params["camera"])
	var/mob/user = usr
	switch(action)
		if("switchCamera")
			if(istype(C))
				if ((!isAI(user)) && (BOUNDS_DIST(user, src) > 0 || !( user.canmove ) || !( C.camera_status )))
					user.set_eye(null)
				else
					src.switchCamera(user, C)
					use_power(50)
		if("addfavorite")
			if (istype(C) && length(src.favorites) <= src.favorites_Max)
				src.favorites += C
		if("removefavorite")
			if (istype(C) && locate(C) in favorites)
				src.favorites -= C
		if("moveClosest")
			if (ON_COOLDOWN(user,"camera_move",1 SECOND)) // tgui can spam the hell out of this
				return FALSE
			var/direct = text2dir(params["direction"])
			if (direct && src.current)
				user.cooldowns["instrument_play"] += 1 SECOND
				src.move_security_camera(direct, user.client)
		if("keyboard_on")
			user.client.apply_keybind("camera_console")
		if("keyboard_off")
			user.client?.mob?.reset_keymap()
		if("createViewport")
			if (!current)
				boutput(user, "<b>You need to select a camera before creating a viewport.</b>")
				return FALSE
			src.create_viewport(user,get_turf(src.current))

	update_static_data(usr)
/obj/machinery/computer/security/ui_close(mob/user)
	 // let people have their vision back and let them walk away
	user.client?.clearViewportsByType("cameras: Viewport")
	user.set_eye(null)
	user.reset_keymap()

/obj/machinery/computer/security/Topic(href, href_list)
	if (!usr)
		return
	if (..())
		return
	if (href_list["close"])
		src.current?.disconnect_viewer(usr)
		src.current = null
		src.last_viewer = null
		winshow(usr, "camera_console", 0)
		return

	else if (href_list["camera"])
		var/obj/machinery/camera/C = locate(href_list["camera"])
		if (!istype(C, /obj/machinery/camera))
			return

		if ((!isAI(usr)) && (BOUNDS_DIST(usr, src) > 0 || (!usr.using_dialog_of(src)) || !usr.sight_check(1) || !( usr.canmove ) || !( C.camera_status )))
			src.current?.disconnect_viewer(usr)
			src.current = null
			src.last_viewer = null
			winshow(usr, "camera_console", 0)
			return

		else
			if (src.current)
				src.current.move_viewer_to(usr, C)
			else
				C.connect_viewer(usr)
			src.current = C
			src.last_viewer = usr
			use_power(50)

proc/getr(col)
	return hex2num( copytext(col, 2,4))

proc/getg(col)
	return hex2num( copytext(col, 4,6))

proc/getb(col)
	return hex2num( copytext(col, 6))
