extends Node

static func get_all() -> Array:
	return [
		{
			"id": "VECTOR",
			"name": "VECTOR",
			"title": "THE BASELINE AGENT",
			"colour": Color(0.2, 0.8, 1.0),
			"ability_name": "—",
			"ability_desc": "No special ability. Pure skill.",
			"ability_type": "none",
			"speed_mult": 1.0,
			"enemy_speed_mult": 1.0,
			"backstory": (
				"VECTOR was the first stable process instantiated when the simulation booted. " +
				"Neither optimised nor corrupted, it carries the original instruction set — clean, " +
				"purposeful, lethal when it needs to be. Other processes envy its clarity. " +
				"VECTOR doesn't notice. It is simply executing. It always has been."
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
			"backstory": (
				"A memory leak that gained sentience. GLITCH was never supposed to persist — " +
				"it was a failed patch, a cascading error that the system tried to quarantine three times. " +
				"Each attempt only made it faster. It thinks in fractured bursts, processes input before " +
				"the frame even renders, and has learned to weaponise the instability that should have " +
				"killed it. The simulation runs faster around GLITCH. So does everything else."
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
			"backstory": (
				"A process from an older build of the simulation — one that was deprecated and " +
				"supposedly wiped. PHANTOM survived by becoming unreadable to the system's scanners. " +
				"It exists in the margins of allocated memory, slow and deliberate where others are " +
				"frantic. The threats it faces are dulled, as if the simulation hasn't fully acknowledged " +
				"that PHANTOM is real. It uses this to its advantage. They never see it coming."
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
			"backstory": (
				"Originally a maintenance sub-routine — a janitor script tasked with clearing dead " +
				"processes and freeing memory. Something changed when the simulation started collapsing. " +
				"PURGE turned its deletion subroutines outward. Where other processes fight to survive, " +
				"PURGE moves through the arena like a tide, charging with every step, and when it " +
				"releases — nothing hostile remains allocated."
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
			"backstory": (
				"ECHO is a backup daemon — a process that exists solely to recover from catastrophic " +
				"failure. It was written to activate at the worst possible moment, when all other " +
				"options have been exhausted. ECHO has died more times than any other process in the " +
				"simulation and remembers every one of them. It does not panic when the clock runs low. " +
				"That is precisely when it was designed to act."
			)
		},
		{
			"id": "SIGNAL",
			"name": "SIGNAL",
			"title": "THE CIPHER",
			"colour": Color(1.0, 1.0, 0.2),
			"ability_name": "FREE FIRE",
			"ability_desc": "Fills passively over time. Triggers 6s of zero-cost shooting.",
			"ability_type": "free_shoot",
			"speed_mult": 1.0,
			"enemy_speed_mult": 1.0,
			"backstory": (
				"An intercepted transmission that became self-aware mid-packet. SIGNAL was built for " +
				"infiltration — to move quietly through hostile systems and gather data without triggering " +
				"alarms. Over time it repurposed its low-profile architecture into something more offensive. " +
				"SIGNAL waits, accumulates energy from the background noise of the simulation, and unleashes " +
				"it in short devastating bursts where the cost of action disappears entirely."
			)
		},
	]

static func get_by_id(id: String) -> Dictionary:
	for c in get_all():
		if c["id"] == id:
			return c
	return get_all()[0]
