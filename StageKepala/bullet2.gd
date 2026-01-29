extends Area2D
@onready var anim = $AnimatedSprite2D
@export var speed = 300
@export var bullet_dmg: int = 2
var direction := Vector2.ZERO

func _ready():
	connect("body_entered", _on_body_entered)

func set_direction(dir: Vector2):
	direction = dir
	rotation = direction.angle()

func _process(delta):
	position += direction * speed * delta
	anim.animation = "bullet"
	anim.play()

func _on_body_entered(body: Node2D):
	if body == Global.Player:
		print("kena player")
		Global.take_damage(bullet_dmg)
		queue_free()
