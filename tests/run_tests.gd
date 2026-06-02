extends SceneTree
## Headless logic tests for the pure rules in core/.
## Run from the project root with:
##   godot --headless --script res://tests/run_tests.gd
## Exits with a non-zero code if any check fails (CI-friendly).

const StageRules := preload("res://core/StageRules.gd")
const Economy := preload("res://core/Economy.gd")
const CombatMath := preload("res://core/CombatMath.gd")

var _failures := 0
var _total := 0

func _check(label: String, condition: bool) -> void:
	_total += 1
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		_failures += 1

func _initialize() -> void:
	# --- StageRules (numbers from the design recording) ---
	_check("stage 1 requires 3", StageRules.kills_to_advance(1) == 3)
	_check("stage 2 requires 4", StageRules.kills_to_advance(2) == 4)
	_check("stage 3 is endless", StageRules.is_endless(3))
	_check("stage 1 won at 3 kills", StageRules.is_stage_won(1, 3))
	_check("stage 1 not won at 2 kills", not StageRules.is_stage_won(1, 2))
	_check("endless stage never 'won'", not StageRules.is_stage_won(3, 9999))

	# --- Economy ---
	var e := Economy.new(75)
	_check("starts with 75 coins", e.coins == 75)
	_check("can afford 50", e.can_afford(50))
	_check("cannot afford 100", not e.can_afford(100))
	_check("spend 50 succeeds", e.spend(50) and e.coins == 25)
	_check("overspend fails, coins unchanged", not e.spend(100) and e.coins == 25)
	e.add(50)
	_check("add restores coins", e.coins == 75)

	# --- CombatMath ---
	_check("damage subtracts", CombatMath.apply_damage(60, 10) == 50)
	_check("damage floors at zero", CombatMath.apply_damage(5, 10) == 0)
	_check("is_dead at 0", CombatMath.is_dead(0))
	_check("not dead at 1", not CombatMath.is_dead(1))
	_check("hits_to_kill exact", CombatMath.hits_to_kill(60, 10) == 6)
	_check("hits_to_kill rounds up", CombatMath.hits_to_kill(61, 10) == 7)

	print("")
	if _failures == 0:
		print("ALL TESTS PASSED (%d checks)" % _total)
	else:
		print("TESTS FAILED: %d of %d checks" % [_failures, _total])
	quit(_failures)
