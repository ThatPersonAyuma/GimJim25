class_name SmallFireball extends Node2D

@onready var sfx = $SFX

@export var speed: float = 300.0
@export var damage: int = 5
@export var life_time: float = 5.0

var direction: Vector2 = Vector2.RIGHT

func _ready():
	print("Small Fireball spawned!")
	sfx.play()
	
	get_tree().create_timer(life_time).timeout.connect(queue_free)
	
	for child in get_children():
		if child is Area2D:
			child.body_entered.connect(_on_body_entered)
			break

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body == Global.Player:
		if Global.McHealth > 0 and is_instance_valid(Global.Player):
			Global.take_damage(damage)
			var knockback_power = 100.0
			Global.McKnockBack(knockback_power / Global.Player.knockback_raw_pow, global_position)
			print("Small Fireball HIT! Damage: ", damage)
		queue_free()
	elif body != Global.Enemy:
		queue_free()
