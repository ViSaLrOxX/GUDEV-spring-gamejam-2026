# GUDEV GAMEJAM
GUDEV Gamejam 16, Spring 2026. Theme: Time.

Top-down shooter where time is your health. It only counts down while you move. Stand still and the world almost freezes. Keep moving and stay alive, but every step costs you.

Kill enemies to earn time back. Grab the time cores scattered across the map to open the exit portal. Survive as many rounds as you can.

---

## Opening it in Godot 4

You need Godot 4, free at godotengine.org.

1. Open Godot 4
2. Hit Import on the Project Manager screen
3. Find this folder and select `project.godot`
4. Click Import and Edit
5. Give it a few seconds to import the assets
6. Press F5 or the Play button and you're in

---

## Controls

| Action | Input |
|---|---|
| Move | WASD |
| Aim | Mouse |
| Shoot | Left Click |
| Dash | Shift |
| Use Ability | E |
| Shop | Tab |
| Settings | Escape |

Dash costs a bit of stability but gives you invincibility frames. Use it to dodge through things, not just to move faster.

---

## How it works

Your stability bar is the only resource that matters. It drains while you move, drains harder when you miss shots or take hits, and refills when you kill things. It only ticks down when you are actually moving. Stop and time almost pauses. Every step is a trade.

Each round:
- Enemies spawn across the map
- Collect the time cores to activate the exit portal
- Kill everything or just run for the portal, your call
- Between rounds there is a shop where you spend credits on upgrades

Kill enemies back to back to build a combo multiplier. Higher combos give bigger time rewards per kill. Hit kill streaks of 5, 10, 20 or 30 and you get bonus time on top. Clear a round with time to spare and you get a speed bonus. Finish without killing anyone and you get a Pacifist bonus instead.

---

## The 8 Operatives

| Operative | Title | Ability | How the bar fills |
|---|---|---|---|
| VECTOR | The Baseline Agent | None, just you and your aim | N/A |
| GLITCH | The Corrupted Fragment | OVERCLOCK: 4 seconds of extreme bullet time | Killing enemies |
| PHANTOM | The Ghost Process | SPECTRAL VEIL: 5 seconds where enemies cannot see you | Taking hits |
| PURGE | The Deletion Protocol | MASS DELETION: every enemy on screen is instantly removed | Moving around |
| ECHO | The Restore Daemon | FULL RESTORE: brings your stability back to full | Clock dropping below 20 seconds |
| NOVA | The Temporal Thief | TIME HEIST: bullet time plus 20 seconds stolen from the timeline | Killing enemies |
| WRAITH | The Suspended Process | STASIS FIELD: all enemies freeze for 3 seconds while you move freely | Passively over time |
| ARBITER | The Prime Directive | SYNC BLAST: shockwave that hits every enemy on screen at once | Taking damage |

---

## Modes

**Normal** - standard progression, rounds get harder, maps get bigger, enemies multiply fast. Boss shows up every 5 rounds.

**Tutorial** - walks you through the basics. Worth doing once if you are new.

**Shooting Range** - no time limit, enemies keep respawning. Good for warming up.

---

## Tips

Standing still is a valid tactic. The mechanic exists to be used.

Shots that hit an enemy are free. Missed shots cost stability. Aim.

Rapid firing raises a heat multiplier that makes each shot more expensive. Burst and pause rather than holding the trigger.

Bosses appear every 5 rounds and have multiple phases. They get more aggressive as they take damage. Save your ability for them.

Maps get very large and enemy counts scale exponentially in later rounds.

---

Made with Godot 4.
