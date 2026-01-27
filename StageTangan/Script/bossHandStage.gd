class_name HandBoss extends CharacterBody2D

@export var max_health: int = 500
@export var speed: float = 100.0
@export var damage_contact: int = 15
@export var knockback_power: float = 300.0
@export var attack_cooldown_time: float = 1.0 

var current_health: int
var can_attack: bool = true 
var is_bouncing: bool = false

func _ready() -> void:
	current_health = max_health
	Global.Enemy = self

func _physics_process(delta):
	if Global.McHealth <= 0:
		velocity = Vector2.ZERO
		return 

	if is_instance_valid(Global.Player):
		move_towards_player(delta)
	
	move_and_slide()

func move_towards_player(delta):
	if is_bouncing:
		return

	var target_pos = Global.Player.global_position
	velocity = global_position.direction_to(target_pos) * speed

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		
		if collision == null:
			continue
			
		var body = collision.get_collider()
		
		if body == Global.Player and can_attack:
			attack_player()

func attack_player():
	if Global.McHealth <= 0:
		return

	if is_instance_valid(Global.Player):
		can_attack = false
		
		Global.take_damage(damage_contact)
		
		if Global.McHealth <= 0:
			print("Player Mati oleh BossHW")
			return 
		
		is_bouncing = true 
		
		var bounce_dir = global_position.direction_to(Global.Player.global_position) * -1
		velocity = bounce_dir * 300 
		
		print("Nabrak, HP Player Berkurang Mint")
		
		await get_tree().create_timer(0.2).timeout
		is_bouncing = false 
		
		await get_tree().create_timer(attack_cooldown_time - 0.2).timeout
		can_attack = true

func take_damage(amount: int):
	current_health -= amount
	
	modulate = Color.RED
	var timer = get_tree().create_timer(0.1)
	await timer.timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die():
	if Global.Enemy == self:
		Global.Enemy = null
	print("Mokad")
	queue_free()
