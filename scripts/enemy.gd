# enemy.gd: one walking enemy. A small state machine gates movement and animation:
#   IDLE      spawned, waiting for the navigation map and a path
#   WALKING   following the NavigationAgent2D path, "walk" animation loops
#   ATTACKING reached the depot: costs lives, then removes itself
#   DEAD      "death" animation, reward paid, then queue_free()
class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy, reward: int)
signal reached_depot(enemy: Enemy, damage: int)

enum State { IDLE, WALKING, ATTACKING, DEAD }

# Stats per kind. Balance lives in data, not in code paths.
const KINDS := {
	"mouse": {"hp": 14.0, "speed": 34.0, "reward": 4, "damage": 1, "scale": 1.0},
	"rat": {"hp": 45.0, "speed": 22.0, "reward": 8, "damage": 2, "scale": 1.15},
	"armored_rat": {"hp": 160.0, "speed": 15.0, "reward": 25, "damage": 5, "scale": 1.3},
}

@export var kind := "mouse"

var max_hp := 1.0
var hp := 1.0
var speed := 1.0
var reward := 0
var damage := 0
var state := State.IDLE
var depot_position := Vector2.ZERO

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite
@onready var hp_bar: ProgressBar = $HpBar
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	add_to_group("enemies")
	sprite.texture = Art.texture(kind)
	sprite.hframes = 2
	sprite.scale = Vector2.ONE * KINDS[kind]["scale"]
	speed = KINDS[kind]["speed"]
	reward = KINDS[kind]["reward"]
	damage = KINDS[kind]["damage"]
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.visible = false
	_style_hp_bar()
	_build_animations()


# Called by WaveManager before the enemy enters the tree.
func setup(hp_scale: float, depot: Vector2) -> void:
	max_hp = KINDS[kind]["hp"] * hp_scale
	hp = max_hp
	depot_position = depot


func _physics_process(_delta: float) -> void:
	match state:
		State.IDLE:
			# The navigation map syncs on the physics frame after the TileMapLayer
			# registers its regions; asking for a path earlier returns nothing.
			if NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) == 0:
				return
			agent.target_position = depot_position
			state = State.WALKING
			anim.play("walk")
		State.WALKING:
			if global_position.distance_to(depot_position) < 6.0:
				_reach_depot()
				return
			var next := agent.get_next_path_position()
			velocity = global_position.direction_to(next) * speed
			sprite.flip_h = velocity.x < -0.1
			move_and_slide()


# Path length still to walk: towers target the enemy closest to the depot.
func remaining_distance() -> float:
	var path := agent.get_current_navigation_path()
	var i := agent.get_current_navigation_path_index()
	if path.is_empty() or i >= path.size():
		return global_position.distance_to(depot_position)
	var total := global_position.distance_to(path[i])
	for j in range(i, path.size() - 1):
		total += path[j].distance_to(path[j + 1])
	return total


func is_alive() -> bool:
	return state != State.DEAD and state != State.ATTACKING and not is_queued_for_deletion()


func take_damage(amount: float) -> void:
	if not is_alive():
		return
	hp -= amount
	hp_bar.visible = true
	hp_bar.value = hp
	if hp <= 0.0:
		_die()
	else:
		anim.play("hurt")
		anim.queue("walk")


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	hp_bar.visible = false
	died.emit(self, reward)
	anim.play("death")
	await anim.animation_finished
	queue_free()


func _reach_depot() -> void:
	state = State.ATTACKING
	set_deferred("collision_layer", 0)
	reached_depot.emit(self, damage)
	queue_free()


func _style_hp_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("1a1c2c")
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("38b764")
	hp_bar.add_theme_stylebox_override("background", bg)
	hp_bar.add_theme_stylebox_override("fill", fill)


# walk: two-frame leg cycle; hurt: red flash; death: shrink and fade.
func _build_animations() -> void:
	var lib := AnimationLibrary.new()
	var walk := Animation.new()
	walk.length = 0.3
	walk.loop_mode = Animation.LOOP_LINEAR
	var t := walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(t, "Sprite:frame")
	walk.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	walk.track_insert_key(t, 0.0, 0)
	walk.track_insert_key(t, 0.15, 1)
	lib.add_animation("walk", walk)

	var hurt := Animation.new()
	hurt.length = 0.12
	t = hurt.add_track(Animation.TYPE_VALUE)
	hurt.track_set_path(t, "Sprite:modulate")
	hurt.track_insert_key(t, 0.0, Color(1, 0.35, 0.35))
	hurt.track_insert_key(t, 0.12, Color.WHITE)
	lib.add_animation("hurt", hurt)

	var death := Animation.new()
	death.length = 0.25
	t = death.add_track(Animation.TYPE_VALUE)
	death.track_set_path(t, "Sprite:modulate")
	death.track_insert_key(t, 0.0, Color.WHITE)
	death.track_insert_key(t, 0.25, Color(1, 1, 1, 0))
	var s := death.add_track(Animation.TYPE_VALUE)
	death.track_set_path(s, "Sprite:scale")
	death.track_insert_key(s, 0.0, sprite.scale)
	death.track_insert_key(s, 0.25, sprite.scale * 0.3)
	lib.add_animation("death", death)
	anim.add_animation_library("", lib)
