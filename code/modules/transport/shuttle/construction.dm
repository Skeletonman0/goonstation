/obj/machinery/computer/transit_shuttle/construction
	name = "Shuttle"
	icon_state = "shuttle"
	desc = "A computer that allows you to build your own shuttle!"
	shuttlename = "NSS IMCODER"
	var/mob/driver

	var/datum/movement_controller/movementcontroller
	glide_size = 4
	var/speed = 8
	/// do we ram into stuff and destroy it
	var/destructive = TRUE

	/// important objs we had at the time of rebuilding
	var/list/shipparts
	/// turfs we had at the time of rebuilding
	var/list/turfs

	/// our engines and weapons
	var/list/engines
	var/list/weapons
/obj/overlay/dummy_turf
	name = ""
	anchored = TRUE
	mouse_opacity = 0

	New(atom/loc)
		..()
		appearance = loc.appearance
		plane = loc.plane


/obj/machinery/computer/transit_shuttle/construction/New()
	..()
	src.reload_ship()
	movementcontroller = new/datum/movement_controller/shuttle_control(src)

/obj/machinery/computer/transit_shuttle/construction/ui_interact(mob/user, datum/tgui/ui)
	ui = tgui_process.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "ConstructShuttle")
		ui.open()

/obj/machinery/computer/transit_shuttle/construction/attack_hand(mob/user, datum/tgui/ui)
	..()
	if (!driver)
		src.add_driver(user)
	else
		if(((driver == user) || !driver?.client))
			src.eject_driver()

/obj/machinery/computer/transit_shuttle/construction/ui_data(mob/user)
	. = ..()
	.["coords"] = list("x" = src.x,"y" = src.y,"z" = src.z)

/obj/machinery/computer/transit_shuttle/construction/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.) return
	switch(action)
		if ("reload")
			src.unset_dummy()
			src.reload_ship()
		if ("rename")
			src.shuttlename = params["name"]

/obj/machinery/computer/transit_shuttle/construction/proc/fire_weapons()
	for (var/obj/machinery/shuttle/weapon/weapon in shipparts)
		weapon.fire()

/obj/machinery/computer/transit_shuttle/construction/get_movement_controller(mob/user)
	. = ..()
	return movementcontroller

/obj/machinery/computer/transit_shuttle/construction/proc/get_edge(var/dir)
	// check the edge of our ship to see where we need to move
	. = list()
	for (var/turf/T in turfs)
		var/turf/F = get_step(T,dir)
		// check if the turf is on our border
		if (!(F in turfs) || !F)
			. += T

/obj/machinery/computer/transit_shuttle/construction/proc/can_move(var/dir)
	// check if we're bumping up against an object
	// if destructive mode is enabled, beat the shit out of said object
	. = TRUE
	for(var/turf/T in get_edge(dir))
		var/turf/F = get_step(T,dir)
		if (F && !istype(F,/turf/space) && !istype(F,/turf/unsimulated/floor)) // planets
			if (src.destructive)
				hit_object(F,T,dir)
			. = FALSE
		for(var/atom/B in F.contents)
			if (B in shipparts) continue

			if (istype(B,/obj/lattice))
				if (src.destructive)
					hit_object(B,T,dir)
				. = FALSE
				continue
			if (!B.Cross(src) && !istype(B,/mob)) // can we pass through it
				if (src.destructive)
					hit_object(B,T,dir)
				. = FALSE

/obj/machinery/computer/transit_shuttle/construction/proc/hit_object(var/atom/A,var/atom/hitter,var/dir)
	if(prob(25)) // chance to not survive
		hitter.ex_act(2)
		if (istype(hitter,/turf/space) || istype(hitter,/turf/unsimulated))
			var/dummy = locate(/obj/overlay/dummy_turf) in hitter
			qdel(dummy)
			for (var/obj/O in shipparts)
				if (hitter == get_turf(O))
					shipparts -= O
			turfs -= hitter
	if (istype(A,/mob))
		var/mob/M = A
		var/turf/throw_at = get_edge_target_turf(get_turf(A), dir)
		M.throw_at(throw_at, 5, 2)
		A.ex_act(2)
	else
		A.ex_act(1)

	for (var/turf/T in turfs)
		for (var/mob/M in T)
			shake_camera(M, 6, 8)

/obj/machinery/computer/transit_shuttle/construction/proc/eject_driver()
	if (!driver) return
	driver.use_movement_controller = null
	driver.reset_keymap()
	boutput(driver, "<span class='alert'>You stop controlling the [src.shuttlename].</span>")
	src.unset_dummy()
	driver = null
/obj/machinery/computer/transit_shuttle/construction/proc/add_driver(mob/user)
	driver = user
	driver.use_movement_controller = src
	driver.reset_keymap()
	src.set_dummy()
	boutput(driver, "<span class='alert'>You start controlling the [src.shuttlename].</span>")




/obj/machinery/computer/transit_shuttle/construction/move_shuttle(var/dir)
	if (!is_cardinal(dir) || !driver) return FALSE
	if (!(locate(/obj/machinery/shuttle/engine) in shipparts))
		boutput(driver, "<span class='alert'><b>No engines detected!</b></span>")
		return FALSE
	if (istype(get_turf(src),/turf/space) || istype(get_turf(src),/turf/unsimulated))
		eject_driver()
		return FALSE
	var/canMove = can_move(dir)
	if (!canMove || !length(turfs))
		return FALSE

	var/list/frontedge = get_edge(dir)
	var/list/oldturfs = turfs
	turfs = list()
	var/backdir = turn(dir,180)
	var/turf/dummyspace = locate(/turf/space)
	for (var/turf/T in frontedge)
		// move back from the front edge, pushing the turfs forward
		var/done = FALSE
		var/turf/oldT = T

		while (!done)
			var/turf/forward = get_step(T,dir)
			if (!forward) continue

			// gliding turf hack alert
			var/obj/dummy = locate(/obj/overlay/dummy_turf) in T
			// pretend to be space until we stop moving, THEN inherit appearance
			forward.ReplaceWith(T.type, keep_old_material = TRUE, force=TRUE)
			if (dummy)
				dummy.set_loc(forward)
				forward.icon = dummyspace.icon
				forward.icon_state = dummyspace.icon_state

			forward.plane = PLANE_SPACE
			forward.set_density(T.density)
			forward.set_dir(T.dir)
			forward.intact = T.intact

			for (var/atom/movable/AM in T.contents)
				if ((AM in shipparts) || istype(AM,/mob) || !AM.anchored)
					AM.glide_size = src.glide_size
					AM.set_loc(forward)
					AM.glide_size = initial(AM.glide_size)
			turfs += forward

			T = get_step(oldT,backdir)

			if (!(T in oldturfs) || !T)
				turfs -= oldT // remove the back edge
				oldT.ReplaceWithSpace()
				done = TRUE
			oldT = T

/obj/machinery/computer/transit_shuttle/construction/proc/set_dummy()
	for (var/turf/T in turfs)
		var/obj/dummy = locate(/obj/overlay/dummy_turf) in T
		if (!dummy)
			dummy = new /obj/overlay/dummy_turf(T)
		else
			dummy.New(T)
/obj/machinery/computer/transit_shuttle/construction/proc/unset_dummy()
	for (var/turf/T in turfs)
		var/obj/dummy = locate(/obj/overlay/dummy_turf) in T
		if (dummy)
			T.appearance = dummy.appearance
			qdel(dummy)
		T.plane = initial(T.plane)

/obj/machinery/computer/transit_shuttle/construction/proc/reload_ship()
	if (istype(get_area(src),/area/station)) return FALSE
	unset_dummy()
	// if we rely on the area based approach, we lose chunks of the ship if it doesnt fit
	// instead we use this system which will find adjacent turfs that belong to us and arent part of the station
	var/turf/T = get_turf(src)
	turfs = list()
	shipparts = list()

	var/list/next = list()
	var/list/processed = list()
	next += T
	processed += T

	// this is borrowed from the room designator
	while (length(next))
		var/turf/C = next[1]
		if (!C) continue
		if (length(next) > 100) break // hard limit on autodetected turfs
		next -= C

		if (istype(C, /turf/space) || istype(C, /turf/unsimulated)) // not part of our ship
			continue
		var/area/A = get_area(C)
		if (!istype(A,/area/shuttle) && !istype(A,/area/built_zone) && !istype(A,/area/space))
			continue
		turfs += C
		for(var/obj/O in C)
			//if (istype(O,/obj/overlay/tile_effect)) continue
			shipparts += O

		var/turf/N
		// add adjacent turfs to queue
		for(var/D in cardinal)
			N = get_step(C, D)
			if (N && !(N in processed))
				next += N
				processed += N
	set_dummy()
	return length(turfs)


