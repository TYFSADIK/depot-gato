# splash_projectile.gd: a yarn ball. On impact, everything inside its blast
# Area2D takes damage, not just the enemy it touched.
class_name SplashProjectile
extends Projectile

@export var blast_radius := 22.0

@onready var blast: Area2D = $Blast


func _ready() -> void:
	super()
	var circle := CircleShape2D.new()
	circle.radius = blast_radius
	$Blast/CollisionShape2D.shape = circle


func hit(enemy: Enemy) -> void:
	var hit_any := false
	for body in blast.get_overlapping_bodies():
		if body is Enemy and body.is_alive():
			body.take_damage(damage)
			hit_any = hit_any or body == enemy
	if not hit_any and enemy.is_alive():
		enemy.take_damage(damage)
