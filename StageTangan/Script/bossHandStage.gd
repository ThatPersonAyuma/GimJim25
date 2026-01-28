class_name HandBoss extends CharacterBody2D

const FIREBALL_SCENE = preload("res://StageTangan/fireball.tscn") 

@export var max_health: int = 500
@export var speed: float = 100.0
@export var damage_contact: int = 15
@export var knockback_power: float = 300.0
@export var attack_cooldown_time: float = 1.0 

@export var fireball_cooldown: float = 3.0
var fireball_timer: float = 0.0
var is_casting_fireball: bool = false

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
	
	if not is_casting_fireball:
		fireball_timer += delta
		
		if fireball_timer >= fireball_cooldown:
			fireball_timer = 0.0
			if is_instance_valid(Global.Player):
				var dist = global_position.distance_to(Global.Player.global_position)
				if dist > 50:
					shoot_fireball()
	
	if is_instance_valid(Global.Player):
		move_towards_player()
	
	move_and_slide()

func move_towards_player():
	if is_bouncing or is_casting_fireball:
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

func shoot_fireball():
	is_casting_fireball = true
	velocity = Vector2.ZERO 
	
	modulate = Color(1.5, 1.0, 0.5) 
	
	await get_tree().create_timer(0.5).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		# Simpan posisi dan arah SEBELUM instantiate
		var spawn_pos = global_position
		var target_pos = Global.Player.global_position
		var dir = spawn_pos.direction_to(target_pos)
		
		# Buat fireball
		var fireball = FIREBALL_SCENE.instantiate()
		
		# Set properti SEBELUM add_child
		fireball.set("direction", dir)
		fireball.rotation = dir.angle()
		
		# Tambahkan ke scene
		get_tree().current_scene.add_child(fireball)
		
		# Set posisi SETELAH add_child menggunakan call_deferred
		fireball.global_position = spawn_pos
		
		print("BOSS: Fireball spawned at ", spawn_pos)
	
	modulate = Color.WHITE 
	
	await get_tree().create_timer(0.5).timeout
	
	is_casting_fireball = false 

func attack_player():
	if Global.McHealth <= 0:
		return
	if is_instance_valid(Global.Player):
		can_attack = false
		
		Global.take_damage(damage_contact)
		
		if Global.McHealth <= 0:
			print("Player Mati oleh Boss")
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
