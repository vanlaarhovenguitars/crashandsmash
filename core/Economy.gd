extends RefCounted
## Coin economy for placing defenders. Pure logic, unit-testable.
## Coins come from a starting pool, a slow passive trickle, and Money Printer toys.

var coins: int

func _init(starting: int = 75) -> void:
	coins = starting

func can_afford(cost: int) -> bool:
	return coins >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	coins -= cost
	return true

func add(amount: int) -> void:
	coins += amount
