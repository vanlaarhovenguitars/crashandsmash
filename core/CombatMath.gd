extends RefCounted
## Pure combat helpers shared by defenders, robots, and projectiles. Unit-testable.

static func apply_damage(current_hp: int, damage: int) -> int:
	return max(0, current_hp - damage)

static func is_dead(hp: int) -> bool:
	return hp <= 0

## Hits required to kill, rounding up. Returns -1 for non-positive damage.
static func hits_to_kill(hp: int, damage: int) -> int:
	if damage <= 0:
		return -1
	return int(ceil(float(hp) / float(damage)))
