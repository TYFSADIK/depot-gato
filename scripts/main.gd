# main.gd: wires the scene together. Level, towers, enemies and projectiles
# are separate nodes; the HUD talks to gameplay only through signals.
extends Node2D

@onready var level: Level = $Level
@onready var waves: WaveManager = $WaveManager
@onready var placement: TowerPlacement = $TowerPlacement
@onready var hud = $HUD


func _ready() -> void:
	var infos := []
	for i in TowerPlacement.TOWERS.size():
		infos.append(placement.tower_info(i))
	hud.build(infos)
	hud.start_pressed.connect(waves.start_next_wave)
	hud.tower_pressed.connect(placement.select)
	hud.restart_pressed.connect(restart)
	placement.selection_changed.connect(func(i): hud.set_selected(i, placement.tower_info(i) if i >= 0 else {}))
	waves.wave_started.connect(func(_n): hud.set_start_enabled(false))
	waves.wave_cleared.connect(func(_n): hud.set_start_enabled(not GameState.is_over))
	GameState.reset(waves.waves.size())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		waves.start_next_wave()


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
