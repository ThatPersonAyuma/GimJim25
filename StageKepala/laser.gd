extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var sfx = $AudioStreamPlayer2D

@export var sweep_speed := 40.0
@export var sweep_angle := 80.0
@export var laser_dmg := 5

var sweep_dir := 1
var swept := 0.0
var active := true
var hit_bodies := []

func _ready():
	anim.animation = "laser"
	anim.play()
	sfx.play()
	connect("body_entered", _on_body_entered)

func _process(delta):
	if not active:
		return

	var step = sweep_speed * delta * sweep_dir
	rotation += deg_to_rad(step)
	swept += abs(step)

	if swept >= sweep_angle:
		active = false
		queue_free()

func _on_body_entered(body):
	if body == Global.Player and not hit_bodies.has(body):
		hit_bodies.append(body)
		Global.take_damage(laser_dmg)
