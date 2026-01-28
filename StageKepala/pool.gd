extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var col = $CollisionShape2D

@export var grow_time := 0.6
@export var target_scale := Vector2(3, 1.5)
@export var life_time := 2.5
@export var slow_percent := 0.4

var active := false

func _ready():
	z_index = -1
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

	# mulai kecil
	scale = Vector2.ZERO
	col.disabled = true

	_grow_pool()

func _grow_pool():
	var tween = create_tween()
	tween.tween_property(self,"scale",target_scale,grow_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished
	col.disabled = false
	active = true

	await get_tree().create_timer(life_time).timeout
	queue_free()

func _on_body_entered(body: Node2D):
	if not active:
		return

	if body == Global.Player:
		print("kena pool air")
		Global.slow_mov = 1.0 - slow_percent
		
func _on_body_exited(body):
	if body == Global.Player:
		Global.slow_mov = 1.0
		print("keluar slow")
