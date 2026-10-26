# wave_manager.gd: spawns each wave from its WaveData, counts enemies down as
# they die or reach the depot, and moves to the next wave or to victory.
class_name WaveManager
extends Node

signal wave_started(number: int)
signal wave_cleared(number: int)

const WAVE_DIR := "res://data/waves/"
const BREAK_SECONDS := 6

@export var level: Level

var waves: Array[WaveData] = []
var current := 0
var alive := 0
var spawning := false
var breaking := false
var _break_left := 0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var break_timer: Timer = $BreakTimer


func _ready() -> void:
	waves = load_waves()
	break_timer.timeout.connect(_on_break_tick)


static func load_waves() -> Array[WaveData]:
	var list: Array[WaveData] = []
	var files := Array(ResourceLoader.list_directory(WAVE_DIR)).filter(func(f): return f.ends_with(".tres"))
	files.sort()
	for file in files:
		list.append(load(WAVE_DIR + file))
	return list


func can_start() -> bool:
	return not spawning and alive == 0 and current < waves.size() and not GameState.is_over


# Start the next wave now (also used to skip the break between waves).
func start_next_wave() -> void:
	if not can_start():
		return
	breaking = false
	break_timer.stop()
	GameState.countdown_changed.emit(-1)
	current += 1
	GameState.set_wave(current)
	wave_started.emit(current)
	_spawn_wave(waves[current - 1])


func _spawn_wave(wave: WaveData) -> void:
	spawning = true
	for entry in wave.entries:
		var scene: PackedScene = load(entry["enemy"])
		for i in int(entry["count"]):
			if GameState.is_over:
				spawning = false
				return
			_spawn(scene, float(entry.get("hp_scale", 1.0)))
			spawn_timer.start(float(entry["interval"]))
			await spawn_timer.timeout
	spawning = false
	_check_cleared()


func _spawn(scene: PackedScene, hp_scale: float) -> void:
	var enemy: Enemy = scene.instantiate()
	enemy.setup(hp_scale, level.cell_center(level.depot_cell))
	enemy.position = level.cell_center(level.spawn_cell)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_depot.connect(_on_enemy_reached_depot)
	alive += 1
	get_tree().current_scene.get_node("Enemies").add_child(enemy)


func _on_enemy_died(_enemy: Enemy, reward: int) -> void:
	alive -= 1
	GameState.earn(reward)
	_check_cleared()


func _on_enemy_reached_depot(_enemy: Enemy, damage: int) -> void:
	alive -= 1
	GameState.lose_lives(damage)
	_check_cleared()


func _check_cleared() -> void:
	if spawning or alive > 0 or GameState.is_over:
		return
	GameState.earn(waves[current - 1].clear_bonus)
	wave_cleared.emit(current)
	if current >= waves.size():
		GameState.finish(true)
		return
	breaking = true
	_break_left = BREAK_SECONDS
	GameState.countdown_changed.emit(_break_left)
	break_timer.start(1.0)


func _on_break_tick() -> void:
	_break_left -= 1
	GameState.countdown_changed.emit(_break_left)
	if _break_left <= 0:
		start_next_wave()
	else:
		break_timer.start(1.0)
