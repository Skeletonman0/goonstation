/*
	For when you want to have a mob control an shuttle's movement.
	Used by the constructable shuttle
*/
// modified for shuttles
/datum/movement_controller/shuttle_control
	var/obj/machinery/computer/transit_shuttle/construction/master
	var/move_dir = 0
	var/move_delay = 5
	var/running = 0
	var/next_move = 0

	New(master)
		..()
		src.master = master

	disposing()
		master = null
		..()

	keys_changed(mob/user, keys, changed)
		if (changed & (KEY_FORWARD|KEY_BACKWARD|KEY_RIGHT|KEY_LEFT|KEY_RUN|KEY_THROW))
			src.move_dir = 0
			src.running = 0
			if (keys & KEY_FORWARD)
				move_dir |= NORTH
			if (keys & KEY_BACKWARD)
				move_dir |= SOUTH
			if (keys & KEY_RIGHT)
				move_dir |= EAST
			if (keys & KEY_LEFT)
				move_dir |= WEST
			if (keys & KEY_RUN)
				src.running = 1
			if (keys & KEY_THROW)
				src.master.fire_weapons()
			if(src.move_dir)
				src.process_move(user)

	process_move(mob/user, keys)
		if(!src.move_dir)
			return 0
		if(TIME < src.next_move)
			return src.next_move - TIME
		var/delay = src.running ? src.move_delay : src.move_delay
		var/turf/T = src.master.loc

		if(istype(T))
			// move the shuttle
			master.move_shuttle(src.move_dir)
		src.next_move = TIME + delay
		return delay

	hotkey(mob/user, name)
		..()
		switch (name)
			if("exit")
				user.use_movement_controller = null
				user.reset_keymap()

	modify_keymap(client/C)
		..()
		C.apply_keybind("just exit")
