# tower.gd: base script for all three cats.
# An Area2D sized to the range keeps a live list of enemies inside it; a Timer
# fires on the cooldown and launches a projectile at the best target.
class_name Tower
extends Node2D

@export var display_name := "Tower"
@export var sprite_name := "tabby"
@export var cost := 50
@export var attack_range := 40.0
@export var cooldown := 0.5
@export var damage := 4.0
@export var projectile_scene: PackedScene

var targets_in_range: Array[Enemy] = []

@onready var range_area: Area2D = $Range
@onready var range_shape: CollisionShape2D = $Range/CollisionShape2D
@onready var timer: Timer = $Cooldown
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	$Sprite.texture = Art.texture(sprite_name)
	var circle := CircleShape2D.new()
	circle.radius = attack_range
	range_shape.shape = circle
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	timer.wait_time = cooldown
	timer.timeout.connect(_on_cooldown)
	timer.start()


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy and not targets_in_range.has(body):
		targets_in_range.append(body)
		# The path loops, so an enemy can leave and re-enter the same range.
		if not body.died.is_connected(_forget):
			body.died.connect(_forget, CONNECT_ONE_SHOT)


func _on_body_exited(body: Node2D) -> void:
	if body is Enemy:
		targets_in_range.erase(body)


func _forget(enemy: Enemy, _reward: int) -> void:
	targets_in_range.erase(enemy)


# The enemy closest to the depot by remaining path length. Skips anything freed
# or already dying, so two towers never waste shots on a corpse.
func pick_target() -> Enemy:
	var best: Enemy = null
	var best_left := INF
	for enemy in targets_in_range:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.is_alive():
			continue
		var left := enemy.remaining_distance()
		if left < best_left:
			best_left = left
			best = enemy
	return best


func _on_cooldown() -> void:
	targets_in_range = targets_in_range.filter(func(e): return is_instance_valid(e))
	var target := pick_target()
	if target == null:
		return
	fire(target)


func fire(target: Enemy) -> void:
	var shot: Projectile = projectile_scene.instantiate()
	shot.damage = damage
	shot.target = target
	shot.global_position = muzzle.global_position
	get_tree().current_scene.get_node("Projectiles").add_child(shot)


func sell_value() -> int:
	return int(cost * 0.7)
