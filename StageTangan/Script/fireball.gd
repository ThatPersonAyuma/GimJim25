class_name HandBossFireball extends Node2D

@export var speed: float = 400.0
@export var damage: int = 20
@export var life_time: float = 5.0 

var direction: Vector2 = Vector2.RIGHT

func _ready():
	print("Fireball _ready() called! Direction: ", direction)
	
	get_tree().create_timer(life_time).timeout.connect(queue_free)
	
	for child in get_children():
		if child is VisibleOnScreenNotifier2D:
			child.screen_exited.connect(queue_free)
			break
	
	for child in get_children():
		if child is Area2D:
			child.body_entered.connect(_on_body_entered)
			break

func _physics_process(delta):
	global_position += direction * speed * delta
	
func _on_body_entered(body):
	print("Fireball hit: ", body.name)
	if body == Global.Player:
		if Global.McHealth > 0 and is_instance_valid(Global.Player):
			Global.take_damage(damage)
			# Knockback saat kena fireball
			var knockback_power = 250.0
			Global.McKnockBack(knockback_power / Global.Player.knockback_raw_pow, global_position)
			print("Player kena fireball!")
		queue_free()
	elif body != Global.Enemy: 
		queue_free()
