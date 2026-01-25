extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

@export var move_speed := 60.0

@export var jump_trigger_distance := 220.0
@export var jump_duration := 0.5
@export var stomp_cooldown_time := 2.0

enum {
	CHASE,
	STOMP
}
var state = CHASE

var jump_start_pos: Vector2
var jump_target_pos: Vector2
var jump_timer := 0.0
var stomp_cooldown := false

func _ready():
	state = CHASE

func _physics_process(delta):
	if Global.Player == null:
		return

	match state:
		CHASE:
			chase_player()
			check_player_distance()

		STOMP:
			process_stomp(delta)

func chase_player():
	var dir = Global.Player.global_position - global_position
	dir = dir.normalized()

	velocity = dir * move_speed
	move_and_slide()

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("walk_right")
		else:
			anim.play("walk_left")
	else:
		if dir.y > 0:
			anim.play("walk_down")
		else:
			anim.play("walk_up")

func check_player_distance():
	if stomp_cooldown or state == STOMP:
		return

	var dist = global_position.distance_to(Global.Player.global_position)

	if dist <= jump_trigger_distance:
		enter_stomp()

func enter_stomp():
	state = STOMP
	jump_timer = 0.0
	velocity = Vector2.ZERO

	jump_start_pos = global_position
	jump_target_pos = Global.Player.global_position

	anim.play("stomp")

func process_stomp(delta):
	jump_timer += delta
	var t = jump_timer / jump_duration
	t = clamp(t, 0.0, 1.0)

	global_position = jump_start_pos.lerp(jump_target_pos, t)

	if t >= 1.0:
		land_after_stomp()

func land_after_stomp():
	state = CHASE
	stomp_cooldown = true

	await get_tree().create_timer(stomp_cooldown_time).timeout
	stomp_cooldown = false
