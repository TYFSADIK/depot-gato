# projectile.gd: flies toward its target, homing while the target lives and
# carrying on in a straight line if it dies first. Hits the first enemy it touches.
class_name Projectile
extends Area2D

@export var speed := 220.0
@export var sprite_name := "kibble"
@export var lifetime := 2.0

var damage := 1.0
var target: Enemy
var direction := Vector2.RIGHT
var _spent := false


func _ready() -> void:
	$Sprite.texture = Art.texture(sprite_name)
	body_entered.connect(_on_body_entered)
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)


func _physics_process(delta: float) -> void:
	if is_instance_valid(target) and target.is_alive():
		direction = global_position.direction_to(target.global_position)
	rotation = direction.angle()
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _spent or not body is Enemy or not body.is_alive():
		return
	_spent = true
	hit(body)
	queue_free()


func hit(enemy: Enemy) -> void:
	enemy.take_damage(damage)
