extends Area2D
@onready var anim = $AnimatedSprite2D
@onready var sfx = $AudioStreamPlayer2D
@export var speed = 200
@export var waves_dmg: int = 10
var direction := Vector2.ZERO

func _ready():
	connect("body_entered", _on_body_entered)
	sfx.play()

func set_direction(dir: Vector2):
	direction = dir
	rotation = direction.angle()

func _process(delta):
	position += direction * speed * delta
	anim.animation = "waves"
	anim.play()

func _on_body_entered(body: Node2D):
	if body == Global.Player:
		print("kena player")
		Global.take_damage(waves_dmg)
		queue_free()
