extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

var state = "idle"
var facing_list = ["up", "down", "left", "right"]
var facing = "down"

var idle_time = 2.0
var move_time = 2
var move_speed = 60

func _ready():
	randomize()
	enter_idle()

func enter_idle():
	state = "idle"
	velocity = Vector2.ZERO
	anim.play("idle")

	await get_tree().create_timer(idle_time).timeout
	choose_random_facing()
	enter_move()

func enter_move():
	state = "move"
	anim.play("walk_" + facing)

	await get_tree().create_timer(move_time).timeout
	enter_idle()

func choose_random_facing():
	facing = facing_list.pick_random()

func _physics_process(delta):
	if state == "move":
		var dir = Vector2.ZERO
		match facing:
			"up": dir = Vector2.UP
			"down": dir = Vector2.DOWN
			"left": dir = Vector2.LEFT
			"right": dir = Vector2.RIGHT

		velocity = dir * move_speed
		move_and_slide()
