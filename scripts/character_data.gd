extends Node

static func get_all() -> Array:
	return [
		{
			"id": "VECTOR",
			"name": "VECTOR",
			"title": "THE BASELINE AGENT",
			"colour": Color(0.2, 0.8, 1.0),
			"ability_name": "NONE",
			"ability_desc": "No special ability. Just skill.",
			"ability_type": "none",
			"speed_mult": 1.0,
			"enemy_speed_mult": 1.0,
			"image_path": "res://assets/characters/char_vector.jpg",
			"backstory": (
				"VECTOR was the first stable process the simulation booted up. " +
				"Clean code, no corruption, no special tricks. It just works. " +
				"Other processes are faster or sneakier but VECTOR is the one that " +
				"was built to last. If something needs doing, VECTOR does it."
			)
		},
		{
			"id": "GLITCH",
			"name": "GLITCH",
			"title": "THE CORRUPTED FRAGMENT",
			"colour": Color(1.0, 0.2, 0.9),
			"ability_name": "OVERCLOCK",
			"ability_desc": "Fill by killing. Triggers 4s of extreme slow-motion bullet time.",
			"ability_type": "bullet_time",
			"speed_mult": 1.35,
			"enemy_speed_mult": 1.35,
			"image_path": "res://assets/characters/char_glitch.jpg",
			"backstory": (
				"GLITCH started as a bad patch. The system tried to delete it three times " +
				"and failed every time. Each failed deletion made it faster. Now it runs " +
				"at a speed the simulation was never designed for, processing inputs before " +
				"the frame even renders. It is dangerous, unstable, and very hard to kill."
			)
		},
		{
			"id": "PHANTOM",
			"name": "PHANTOM",
			"title": "THE GHOST PROCESS",
			"colour": Color(0.6, 0.6, 1.0),
			"ability_name": "SPECTRAL VEIL",
			"ability_desc": "Fill by taking hits. Triggers 5s where enemies cannot detect you.",
			"ability_type": "invisibility",
			"speed_mult": 1.0,
			"enemy_speed_mult": 0.72,
			"image_path": "res://assets/characters/char_phantom.jpg",
			"backstory": (
				"PHANTOM is from an older build that got deprecated and wiped. " +
				"Most of it was wiped. The part that survived learned to stay hidden. " +
				"The scanners read it as empty memory. The threats around it are slower, " +
				"as if the simulation has not quite decided PHANTOM is real. " +
				"That uncertainty is all the advantage it needs."
			)
		},
		{
			"id": "PURGE",
			"name": "PURGE",
			"title": "THE DELETION PROTOCOL",
			"colour": Color(1.0, 0.3, 0.0),
			"ability_name": "MASS DELETION",
			"ability_desc": "Fill by moving. Triggers instant termination of all active threats.",
			"ability_type": "wipeout",
			"speed_mult": 1.0,
			"enemy_speed_mult": 1.0,
			"image_path": "res://assets/characters/char_purge.jpg",
			"backstory": (
				"PURGE used to be a cleanup script. Free memory, remove dead processes, " +
				"keep the system tidy. When things started breaking it turned those same " +
				"tools outward. Now it walks the arena and charges with every step. " +
				"When the charge is full it releases and everything hostile just stops existing."
			)
		},
		{
			"id": "ECHO",
			"name": "ECHO",
			"title": "THE RESTORE DAEMON",
			"colour": Color(0.2, 1.0, 0.5),
			"ability_name": "FULL RESTORE",
			"ability_desc": "Fill when your time drops below 20s. Triggers full time restoration.",
			"ability_type": "restore",
			"speed_mult": 1.0,
			"enemy_speed_mult": 1.0,
			"image_path": "res://assets/characters/char_echo.jpg",
			"backstory": (
				"ECHO exists to recover from failure. That is literally what it was written for. " +
				"Activate at the worst moment, when everything else is gone. " +
				"It has died more times than any other process in the simulation and it " +
				"remembers all of them. It does not panic when the clock hits zero. " +
				"That is exactly when it was built to wake up."
			)
		},
		{
			"id": "NOVA",
			"name": "NOVA",
			"title": "THE TEMPORAL THIEF",
			"colour": Color(1.0, 0.6, 0.1),
			"ability_name": "TIME HEIST",
			"ability_desc": "Fill by killing enemies. Triggers bullet time and steals +20s from the timeline.",
			"ability_type": "time_heist",
			"speed_mult": 1.2,
			"enemy_speed_mult": 1.2,
			"image_path": "res://assets/characters/char_nova.jpg",
			"backstory": (
				"NOVA got stuck in a corrupted loop for a thousand iterations and the only " +
				"thing it had to do was figure out how time worked. Now it knows. " +
				"It banks stolen seconds from every kill and when the pile is big enough " +
				"it tears open the timeline and takes what it wants. Very fast. Very loud. " +
				"Very effective."
			)
		},
		{
			"id": "WRAITH",
			"name": "WRAITH",
			"title": "THE SUSPENDED PROCESS",
			"colour": Color(0.5, 0.9, 0.7),
			"ability_name": "STASIS FIELD",
			"ability_desc": "Fills passively over time. Triggers 3s where all enemies freeze but you move freely.",
			"ability_type": "stasis",
			"speed_mult": 0.9,
			"enemy_speed_mult": 0.65,
			"image_path": "res://assets/characters/char_wraith.jpg",
			"backstory": (
				"WRAITH has been in suspended state more than any other process alive. " +
				"It learned to push that outward. One pulse and the whole arena freezes at " +
				"frame zero. Every enemy locked, every bullet stopped. WRAITH moves through " +
				"them quietly and takes its time. It is not fast. It does not need to be."
			)
		},
		{
			"id": "ARBITER",
			"name": "ARBITER",
			"title": "THE PRIME DIRECTIVE",
			"colour": Color(0.4, 0.6, 1.0),
			"ability_name": "SYNC BLAST",
			"ability_desc": "Fill by taking damage. Detonates a shockwave that hits every enemy on screen.",
			"ability_type": "sync_blast",
			"speed_mult": 0.95,
			"enemy_speed_mult": 0.85,
			"image_path": "res://assets/characters/char_arbiter.jpg",
			"backstory": (
				"ARBITER was the shutdown switch. If the simulation got out of hand it " +
				"was supposed to close everything down. It never fired. The damage that " +
				"was meant to destroy it started feeding it instead. Now it absorbs hits " +
				"and stores the energy until it has enough to level everything in the room. " +
				"Still doing its job. Just differently."
			)
		},
	]

static func get_by_id(id: String) -> Dictionary:
	for c in get_all():
		if c["id"] == id:
			return c
	return get_all()[0]
