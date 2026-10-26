# Test suite. Run the test scene headless at a fixed frame rate, so whole games
# simulate as fast as the CPU allows:
#   godot --headless --fixed-fps 60 res://tests/run_tests.tscn
# Unit checks first, then two full games played by the test itself:
#   1. no towers: enemies must walk the whole path and the depot must fall;
#   2. a fixed tower layout: all eight waves must be held.
extends Node

const MAIN := preload("res://scenes/main.tscn")
const MAX_FRAMES := 60 * 60 * 15

var passed := 0
var failed := 0


func check(condition: bool, what: String) -> void:
	if condition:
		passed += 1
		print("  ok    ", what)
	else:
		failed += 1
		print("  FAIL  ", what)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Depot Gato tests")
	_test_art()
	_test_game_state()
	_test_map()
	_test_waves()
	await _test_navigation_and_defeat()
	await _test_full_game_with_towers()
	await _test_thin_defence_falls()
	print("\n%d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _test_art() -> void:
	var ok := true
	for sprite_name in Art.SPRITES:
		var rows: Array = Art.SPRITES[sprite_name]
		for row in rows:
			ok = ok and row.length() == rows[0].length()
			for ch in row:
				ok = ok and (ch == "." or Art.PALETTE.has(ch))
	check(ok, "every sprite is rectangular and uses palette colours only")
	check(Art.texture("tabby").get_size() == Vector2(16, 16), "sprite textures build at 16x16")
	check(Art.texture("mouse").get_size() == Vector2(32, 16), "enemy sheets hold two walk frames")


func _test_game_state() -> void:
	GameState.reset(8)
	var seen := []
	GameState.currency_changed.connect(func(v): seen.append(v))
	check(GameState.spend(50) and GameState.currency == GameState.START_CURRENCY - 50, "spend lowers currency")
	check(not GameState.spend(10_000), "cannot spend more than you have")
	GameState.earn(5)
	check(seen == [GameState.START_CURRENCY - 50, GameState.START_CURRENCY - 45], "HUD signal fires on every change")
	GameState.lose_lives(GameState.START_LIVES + 5)
	check(GameState.lives == 0 and GameState.is_over, "lives stop at zero and end the game")
	check(not GameState.spend(1), "no spending after game over")


func _test_map() -> void:
	var rows := Level.MAP
	var width: int = rows[0].length()
	check(rows.all(func(r): return r.length() == width), "map rows are the same width")
	var spawn := Vector2i(-1, -1)
	var depot := Vector2i(-1, -1)
	for y in rows.size():
		for x in width:
			if rows[y][x] == "S":
				spawn = Vector2i(x, y)
			elif rows[y][x] == "D":
				depot = Vector2i(x, y)
	# Breadth-first search over path tiles: the depot must be reachable.
	var frontier := [spawn]
	var seen := {spawn: true}
	while not frontier.is_empty():
		var c: Vector2i = frontier.pop_front()
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if n.y >= 0 and n.y < rows.size() and n.x >= 0 and n.x < width and not seen.has(n) and rows[n.y][n.x] in "#SD":
				seen[n] = true
				frontier.append(n)
	check(seen.has(depot), "the path connects the spawn to the depot")


func _test_waves() -> void:
	var waves := WaveManager.load_waves()
	check(waves.size() == 8, "eight waves load from data/waves")
	var ok := true
	for w in waves:
		for e in w.entries:
			ok = ok and ResourceLoader.exists(e["enemy"]) and int(e["count"]) > 0 and float(e["interval"]) > 0.0
	check(ok, "every wave entry points at a real enemy scene with a count and interval")


func _start_game() -> Node:
	Engine.time_scale = 1.0
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	await get_tree().physics_frame
	return main


func _play_until_over(main: Node) -> int:
	var waves: WaveManager = main.get_node("WaveManager")
	var frames := 0
	while not GameState.is_over and frames < MAX_FRAMES:
		if waves.can_start() and not waves.breaking:
			waves.start_next_wave()
		await get_tree().physics_frame
		frames += 1
	return frames


func _end_game(main: Node) -> void:
	main.queue_free()
	get_tree().current_scene = self
	await get_tree().process_frame


func _test_navigation_and_defeat() -> void:
	var main := await _start_game()
	var waves: WaveManager = main.get_node("WaveManager")
	var reached := [0]
	waves.wave_started.connect(func(_n):
		for e in main.get_node("Enemies").get_children():
			if not e.reached_depot.is_connected(_count):
				e.reached_depot.connect(_count.bind(reached)))
	var level: Level = main.get_node("Level")
	waves.start_next_wave()
	# Follow the first mouse: it must leave the spawn and make progress along the path.
	for i in 30:
		await get_tree().physics_frame
	var first: Enemy = main.get_node("Enemies").get_child(0)
	var start_left := first.remaining_distance()
	for i in 120:
		await get_tree().physics_frame
	check(is_instance_valid(first) and first.state == Enemy.State.WALKING, "the first mouse is walking")
	check(is_instance_valid(first) and first.remaining_distance() < start_left - 50, "it moves along the navigation path toward the depot")
	check(level.ground.get_cell_atlas_coords(level.world_to_cell(first.global_position)) == Level.PATH, "it stays on path tiles")
	var frames := await _play_until_over(main)
	check(GameState.is_over and GameState.lives == 0, "with no towers the depot falls (after %d frames)" % frames)
	check(GameState.wave >= 2, "enemies walked the full path and cost lives (lost on wave %d)" % GameState.wave)
	await _end_game(main)


func _count(_enemy, _damage, counter) -> void:
	counter[0] += 1


func _test_full_game_with_towers() -> void:
	var main := await _start_game()
	var placement: TowerPlacement = main.get_node("TowerPlacement")
	var level: Level = main.get_node("Level")
	check(placement.place(0, Vector2i(0, 1)) == null, "cannot build on the path")
	check(placement.place(0, Vector2i(5, 3)) == null, "cannot build on a rock")
	var first := placement.place(0, Vector2i(10, 2))
	check(first != null, "can build on grass")
	check(placement.place(0, Vector2i(10, 2)) == null, "cannot build twice on one tile")
	var before := GameState.currency
	check(placement.sell(Vector2i(10, 2)) and GameState.currency == before + int(first.cost * 0.7), "selling refunds 70%")
	check(level.is_buildable(Vector2i(10, 2)), "a sold tile is buildable again")

	# A plan a player could follow: build as money allows, in this order.
	var plan := [
		[0, Vector2i(10, 2)], [0, Vector2i(8, 4)], [0, Vector2i(4, 6)], [1, Vector2i(13, 6)],
		[0, Vector2i(15, 9)], [2, Vector2i(13, 9)], [1, Vector2i(20, 6)], [0, Vector2i(22, 4)],
		[2, Vector2i(4, 9)], [1, Vector2i(25, 11)], [2, Vector2i(22, 11)], [0, Vector2i(27, 8)],
		[1, Vector2i(15, 4)], [2, Vector2i(25, 8)], [1, Vector2i(10, 9)], [2, Vector2i(20, 2)],
	]
	var waves: WaveManager = main.get_node("WaveManager")
	var built := 0
	var frames := 0
	var kills := [0]
	while not GameState.is_over and frames < MAX_FRAMES:
		while built < plan.size() and placement.place(plan[built][0], plan[built][1]) != null:
			built += 1
		if waves.can_start() and not waves.breaking:
			waves.start_next_wave()
		await get_tree().physics_frame
		frames += 1
	check(GameState.is_over and GameState.lives > 0, "with towers all %d waves are held (%d lives left, %d towers built)" % [GameState.total_waves, GameState.lives, built])
	check(GameState.wave == 8, "the game ran through wave 8")
	check(main.get_node("Projectiles").get_child_count() < 40, "projectiles are cleaned up")
	await _end_game(main)


# Balance check: waves must escalate, so three basic cats cannot hold all eight.
func _test_thin_defence_falls() -> void:
	var main := await _start_game()
	var placement: TowerPlacement = main.get_node("TowerPlacement")
	for cell in [Vector2i(10, 2), Vector2i(8, 4), Vector2i(4, 6)]:
		placement.place(0, cell)
	await _play_until_over(main)
	check(GameState.is_over and GameState.lives == 0, "a thin defence of three Tabbies falls (on wave %d)" % GameState.wave)
	check(GameState.wave >= 3, "but it holds the early waves")
	await _end_game(main)
