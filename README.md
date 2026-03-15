# CHRONO//BREACH
GUDEV Gamejam 16, Spring 2026. Theme: Time.

A top-down shooter where time is your health. It only counts down while you move. Stand still and the world almost freezes around you. Keep moving and stay alive — but every step is a gamble.

Kill enemies to earn time back. Grab the time cores spread across the map to open the exit portal. Survive as many rounds as you can.

---

## Opening it in Godot 4

You need Godot 4 — grab it free at godotengine.org if you haven't already.

1. Open Godot 4
2. Hit **Import** on the Project Manager screen
3. Find this folder and select `project.godot`
4. Click **Import and Edit**
5. Give it a few seconds to import the assets
6. Press **F5** or the Play button and you're in

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

Dash costs a bit of stability but gives you invincibility frames while you're in it. Use it to dodge through things, not just to go faster.

---

## How the game works

Your stability bar is the only resource that matters. It drains while you move, drains harder when you miss shots or take hits, and refills when you kill things. The twist: it only ticks down when you're actually moving. Stop and time almost pauses. Every moment of movement is a conscious trade.

Each round:
- Enemies spawn across the map
- Find the time cores and collect them to activate the exit portal
- You can kill everything or just run for the portal — your call
- After each round there's a shop where you spend credits on upgrades

Kill enemies in quick succession to build a combo multiplier. Higher combos mean bigger time rewards per kill. Hit kill streaks of 5, 10, 20 or 30 and you get chunky bonus time on top. Clear a round with time to spare and you get a speed bonus too. Finish without killing anyone and you get a Pacifist bonus instead.

---

## The 8 Operatives

Everyone plays differently. Pick whoever fits your style.

| Operative | Title | Ability | How the bar fills |
|---|---|---|---|
| VECTOR | The Baseline Agent | None — just you and your aim | N/A |
| GLITCH | The Corrupted Fragment | OVERCLOCK — 4 seconds of extreme bullet time | Killing enemies |
| PHANTOM | The Ghost Process | SPECTRAL VEIL — 5 seconds where enemies can't see you | Taking hits |
| PURGE | The Deletion Protocol | MASS DELETION — every enemy on screen is instantly removed | Moving around |
| ECHO | The Restore Daemon | FULL RESTORE — brings your stability back to full | Clock dropping below 20 seconds |
| NOVA | The Temporal Thief | TIME HEIST — bullet time plus 20 seconds stolen from the timeline | Killing enemies |
| WRAITH | The Suspended Process | STASIS FIELD — all enemies freeze for 3 seconds while you move freely | Passively over time |
| ARBITER | The Prime Directive | SYNC BLAST — shockwave that hits every enemy on screen at once | Taking damage |

---

## Modes

**Normal** — the main game. Rounds get harder, maps get bigger, enemies multiply exponentially. Boss enemies show up every 5 rounds.

**Tutorial** — walks you through the basics step by step. Worth doing once if you're new.

**Shooting Range** — no time limit, enemies keep respawning. Good for warming up or just messing around.

---

## A few things worth knowing

Standing still is completely valid. The time freeze mechanic exists to be used.

Shots that hit an enemy are free. Shots that miss cost stability. Aim properly.

Rapid-fire raises a heat multiplier that makes each shot progressively more expensive. Burst and pause rather than holding the trigger down.

Boss enemies show up every 5 rounds and have multiple phases. They hit hard and shoot more bullets as they take damage. Save your ability for them.

If you somehow survive long enough, the maps get very large and enemy counts scale exponentially. You have been warned.

---

Made with Godot 4.
