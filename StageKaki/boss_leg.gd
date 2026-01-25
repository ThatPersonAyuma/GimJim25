extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

var state = "idle"
var facing_list = ["up", "down", "left", "right"]
var facing = "down"

var idle_time = 2.0
var move_time = 2.0
var move_speed = 60

# === MEKANIK LOMPAT ===
@export var jump_trigger_distance := 200.0
@export var jump_speed := 300.0
@export var jump_duration := 0.8
var jump_start_pos: Vector2
var jump_target_pos: Vector2
var jump_timer := 0.0

var stomp_cooldown := false

var target_position: Vector2

func _ready():
	randomize()
	enter_idle()

func _physics_process(delta):
	# cek jarak player terus
	check_player_distance()

	if state == "move":
		var dir = Vector2.ZERO
		match facing:
			"up": dir = Vector2.UP
			"down": dir = Vector2.DOWN
			"left": dir = Vector2.LEFT
			"right": dir = Vector2.RIGHT

		velocity = dir * move_speed
		move_and_slide()

	elif state == "stomp":
		jump_timer += delta
		var t = jump_timer / jump_duration
		t = clamp(t, 0.0, 1.0)

		# lerp posisi → BOS TIDAK NGEJAR PLAYER
		global_position = jump_start_pos.lerp(jump_target_pos, t)

		if t >= 1.0:
			land_after_jump()

func land_after_jump():
	stomp_cooldown = true
	state = "idle"

	await get_tree().create_timer(2.0).timeout
	stomp_cooldown = false

	enter_idle()


func check_player_distance():
	if state == "stomp" or stomp_cooldown:
		return

	if Global.Player == null:
		return

	var dist = global_position.distance_to(Global.Player.global_position)

	if dist <= jump_trigger_distance:
		enter_jump()

# =========================
# STATE FUNCTIONS
# =========================

func enter_idle():
	state = "idle"
	velocity = Vector2.ZERO
	anim.play("idle")

	var my_state = state
	await get_tree().create_timer(idle_time).timeout

	# kalau state berubah (misalnya stomp), STOP
	if state != my_state:
		return

	choose_random_facing()
	enter_move()


func enter_move():
	state = "move"
	anim.play("walk_" + facing)

	var my_state = state
	await get_tree().create_timer(move_time).timeout

	if state != my_state:
		return

	enter_idle()


func enter_jump():
	state = "stomp"
	jump_timer = 0.0

	# kunci posisi player SEKALI
	jump_start_pos = global_position
	jump_target_pos = Global.Player.global_position

	anim.play("stomp")


func choose_random_facing():
	facing = facing_list.pick_random()
