extends Area2D

@export var slow_multiplier := 0.4   # player jadi 40% speed
@export var duration := 3.0          # lumpur aktif berapa detik

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	await get_tree().create_timer(duration).timeout
	queue_free()

func _on_body_entered(body):
	if body == Global.Player:
		Global.slow_mov = slow_multiplier

func _on_body_exited(body):
	if body == Global.Player:
		Global.slow_mov = 1.0
