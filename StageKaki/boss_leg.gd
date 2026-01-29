extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var stomp_hitbox = $StompHitbox
@onready var MudAreaScene = preload("res://StageKaki/mud_area.tscn")

@onready var stomp_sfx = $StompSFX
@onready var mud_sfx = $MudSFX

@export var max_health := 100
@export var knockback_power := 70.0

var HP := 0
var is_dead := false

@export var move_speed := 55.0
@export var jump_trigger_distance := 150.0
@export var jump_duration := 0.5
@export var stomp_cooldown_time := 14
@export var stomp_y_offset := 42.0
var is_paused := false
@export var post_stomp_pause := 1.2

@export var stomp_damage := 15
@export var stomp_knockback_power := 0.2

@onready var basic_hitbox = $BasicHitbox

@export var basic_attack_distance := 65.0
@export var basic_attack_damage := 5
@export var basic_attack_count := 3
@export var basic_attack_interval := 0.35

var can_stomp := true

@export var mud_chance := 0.4
@export var mud_pause_time := 1.0

enum { CHASE, STOMP, BASIC, MUD, KNOCKBACK }
var state = CHASE

var jump_start_pos: Vector2
var jump_target_pos: Vector2
var jump_timer := 0.0
var stomp_cooldown := false

var player_was_outside_stomp_range := true

func _ready():
	state = CHASE
	HP = max_health
	Global.Enemy = self
	stomp_hitbox.monitoring = false
	basic_hitbox.monitoring = false

func _physics_process(delta):
	if is_dead:
		return
		
	if is_paused:
			velocity = Vector2.ZERO
			move_and_slide()
			return
	if Global.McHealth <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if Global.Player == null:
		return

	match state:
		KNOCKBACK:
			move_and_slide()
			return
		CHASE:
			chase_player()
			check_player_distance()

		STOMP:
			process_stomp(delta)
		BASIC:
			pass

func chase_player():
	var dir = (Global.Player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

	if abs(dir.x) > abs(dir.y):
		anim.play("walk_right" if dir.x > 0 else "walk_left")
	else:
		anim.play("walk_down" if dir.y > 0 else "walk_up")

func check_player_distance():
	if state != CHASE:
		return

	var dist = global_position.distance_to(Global.Player.global_position)

	var player_inside_stomp_range = dist <= jump_trigger_distance

	if player_inside_stomp_range \
	and player_was_outside_stomp_range \
	and not stomp_cooldown:
		enter_stomp()
		player_was_outside_stomp_range = false
		return

	if dist <= basic_attack_distance:
		if randf() < mud_chance:
			enter_mud_attack()
		else:
			enter_basic_attack()
		return

	if not player_inside_stomp_range:
		player_was_outside_stomp_range = true


func spawn_mud():
	var mud = MudAreaScene.instantiate()
	get_parent().add_child(mud)

	mud.global_position = global_position

func enter_mud_attack():
	state = MUD
	is_paused = true
	velocity = Vector2.ZERO
	
	if mud_sfx:
		mud_sfx.pitch_scale = randf_range(0.9, 1.1) # opsional
		mud_sfx.play()

	spawn_mud()

	await get_tree().create_timer(mud_pause_time).timeout

	is_paused = false
	state = CHASE


func enter_basic_attack():
	state = BASIC
	is_paused = true
	velocity = Vector2.ZERO

	await basic_attack_sequence()

	is_paused = false
	state = CHASE

func basic_attack_sequence():
	for i in range(basic_attack_count):
		anim.play("basic_attack")
		
		if stomp_sfx:
			stomp_sfx.play()

		basic_hitbox.monitoring = true
		await get_tree().physics_frame

		if basic_hitbox.overlaps_body(Global.Player):
			Global.McKnockBack(0.05, global_position)
			Global.take_damage(basic_attack_damage)

		basic_hitbox.monitoring = false
		await get_tree().create_timer(basic_attack_interval).timeout

func enter_stomp():
	state = STOMP
	can_stomp = false
	jump_timer = 0.0
	velocity = Vector2.ZERO

	jump_start_pos = global_position
	jump_target_pos = Global.Player.global_position
	jump_target_pos.y -= stomp_y_offset

	anim.play("stomp")

func process_stomp(delta):
	jump_timer += delta
	var t = clamp(jump_timer / jump_duration, 0.0, 1.0)
	global_position = jump_start_pos.lerp(jump_target_pos, t)

	if t >= 1.0:
		state = CHASE
		land_after_stomp()

func land_after_stomp():
	if stomp_sfx:
		stomp_sfx.play()
	stomp_hitbox.monitoring = true

	await get_tree().physics_frame

	if stomp_hitbox.overlaps_body(Global.Player):
		Global.McKnockBack(stomp_knockback_power, global_position)
		Global.take_damage(stomp_damage)

	stomp_hitbox.monitoring = false
	
	is_paused = true
	anim.play("idle")
	await get_tree().create_timer(post_stomp_pause).timeout
	is_paused = false

	stomp_cooldown = true
	await get_tree().create_timer(stomp_cooldown_time).timeout
	stomp_cooldown = false

func take_damage(amount: int):
	if is_dead or state == KNOCKBACK:
		return

	HP -= amount
	print("Boss Leg HP:", HP)

	state = KNOCKBACK
	is_paused = false

	var dir = (global_position - Global.Player.global_position).normalized()
	velocity = dir * knockback_power

	modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.4).timeout
	modulate = Color.WHITE

	await get_tree().create_timer(1.0).timeout

	velocity = Vector2.ZERO
	state = CHASE

	if HP <= 0:
		die()


func die():
	is_dead = true
	is_paused = true
	velocity = Vector2.ZERO

	if Global.Enemy == self:
		Global.Enemy = null

	print("Boss Leg Destroyed")
	queue_free()
