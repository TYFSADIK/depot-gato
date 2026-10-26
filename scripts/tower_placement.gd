# tower_placement.gd: turns mouse input into towers.
# Pick a cat in the HUD (or press 1, 2, 3), then click a grass tile. A ghost
# shows the range in green where you can build and red where you cannot.
# Right-click a placed cat to sell it back for 70%. Esc or right-click cancels.
class_name TowerPlacement
extends Node2D

signal selection_changed(index: int)

const TOWERS: Array[PackedScene] = [
	preload("res://scenes/towers/basic_tower.tscn"),
	preload("res://scenes/towers/sniper_tower.tscn"),
	preload("res://scenes/towers/splash_tower.tscn"),
]

@export var level: Level

var selected := -1
var towers := {}
var _ghost_cell := Vector2i(-1, -1)
var _ghost_ok := false
var _info: Array[Dictionary] = []


func _ready() -> void:
	z_index = 5
	for scene in TOWERS:
		var t: Tower = scene.instantiate()
		_info.append({"name": t.display_name, "cost": t.cost, "range": t.attack_range, "sprite": t.sprite_name})
		t.free()


func tower_info(index: int) -> Dictionary:
	return _info[index]


func select(index: int) -> void:
	selected = index if index != selected else -1
	selection_changed.emit(selected)
	queue_redraw()


func can_place(cell: Vector2i) -> bool:
	return selected >= 0 and level.is_buildable(cell) and GameState.can_afford(_info[selected]["cost"]) and not GameState.is_over


# Returns the new tower, or null if the cell or the budget does not allow it.
func place(index: int, cell: Vector2i) -> Tower:
	if not level.is_buildable(cell) or GameState.is_over:
		return null
	if not GameState.spend(_info[index]["cost"]):
		return null
	var tower: Tower = TOWERS[index].instantiate()
	tower.position = level.cell_center(cell)
	level.occupied[cell] = tower
	towers[cell] = tower
	get_tree().current_scene.get_node("Towers").add_child(tower)
	return tower


func sell(cell: Vector2i) -> bool:
	if not towers.has(cell):
		return false
	var tower: Tower = towers[cell]
	GameState.earn(tower.sell_value())
	towers.erase(cell)
	level.occupied.erase(cell)
	tower.queue_free()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3:
				select(event.keycode - KEY_1)
			KEY_ESCAPE:
				selected = -1
				selection_changed.emit(selected)
				queue_redraw()
	elif event is InputEventMouseMotion:
		_update_ghost(get_global_mouse_position())
	elif event is InputEventMouseButton and event.pressed:
		var cell := level.world_to_cell(get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT and selected >= 0:
			if place(selected, cell) != null and not Input.is_key_pressed(KEY_SHIFT):
				select(selected)
			_update_ghost(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if selected >= 0:
				select(selected)
			else:
				sell(cell)


func _update_ghost(world: Vector2) -> void:
	_ghost_cell = level.world_to_cell(world)
	_ghost_ok = can_place(_ghost_cell)
	queue_redraw()


func _draw() -> void:
	if selected < 0 or not level.in_bounds(_ghost_cell):
		return
	var center := level.cell_center(_ghost_cell)
	var color := Color(0.3, 1, 0.4) if _ghost_ok else Color(1, 0.3, 0.3)
	draw_circle(center, _info[selected]["range"], Color(color, 0.15))
	draw_arc(center, _info[selected]["range"], 0, TAU, 48, Color(color, 0.7), 1.0)
	draw_texture(Art.texture(_info[selected]["sprite"]), center - Vector2(8, 8), Color(1, 1, 1, 0.6))
	draw_rect(Rect2(center - Vector2(8, 8), Vector2(16, 16)), color, false, 1.0)
