extends RefCounted
## Central definitions for every defender and enemy. Tweak these numbers to balance
## the game — everything else reads from here. Swapping the placeholder `color` for a
## real sprite later is a one-line change per unit.
##
## Defender roles:
##   "income"  - generates coins over time (the "sunflower")
##   "shooter" - fires projectiles down its lane
##   "tank"    - high HP wall with a short-range melee hit

const MONEY_PRINTER := {
	"id": "money_printer", "name": "Money Printer", "role": "income",
	"cost": 25, "hp": 35, "income": 25, "income_interval": 5.0,
	"color": Color(1.0, 0.85, 0.10),
}
const BEAST_TOY := {
	"id": "beast_toy", "name": "Beast Toy", "role": "shooter",
	"cost": 50, "hp": 45, "damage": 12, "attack_interval": 1.2,
	"color": Color(0.20, 0.70, 1.0),
}
const CREATURE := {
	"id": "creature", "name": "Creature", "role": "tank",
	"cost": 100, "hp": 140, "damage": 8, "attack_interval": 1.5,
	"color": Color(0.25, 0.80, 0.35),
}
const BAT := {
	"id": "bat", "name": "Bat", "role": "shooter",
	"cost": 40, "hp": 25, "damage": 7, "attack_interval": 0.6,
	"color": Color(0.65, 0.35, 0.85),
}

## Order shown in the HUD selection bar (also maps to keyboard keys 1-4).
const DEFENDERS := [MONEY_PRINTER, BEAST_TOY, CREATURE, BAT]

const ROBOT := {
	"id": "robot", "name": "Robot", "hp": 60, "damage": 10,
	"attack_interval": 1.0, "speed": 45.0,
	"color": Color(0.62, 0.64, 0.70),
}
