class_name HandBoss extends CharacterBody2D

const FIREBALL_SCENE = preload("res://StageTangan/fireball.tscn")
const SHOCKWAVE_SCENE = preload("res://StageTangan/shockwave.tscn")
const PUNCH_HITBOX_SCENE = preload("res://StageTangan/punch_hitbox.tscn")

@export var max_health: int = 500
@export var speed: float = 100.0
@export var damage_contact: int = 15
@export var knockback_power: float = 300.0
@export var attack_cooldown_time: float = 1.0 


@export var fireball_cooldown: float = 3.0
var fireball_timer: float = 0.0
var is_casting_fireball: bool = false

@export var shockwave_cooldown: float = 5.0
@export var shockwave_min_range: float = 30.0
@export var shockwave_max_range: float = 500.0
var shockwave_timer: float = 0.0
var is_casting_shockwave: bool = false

@export var punch_cooldown: float = 2.0
@export var punch_range: float = 80.0
var punch_timer: float = 0.0
var is_punching: bool = false

var current_health: int
var can_attack: bool = true 
var is_bouncing: bool = false

func _ready() -> void:
	current_health = max_health
	Global.Enemy = self

func _physics_process(delta: float) -> void:
	if Global.McHealth <= 0:
		velocity = Vector2.ZERO
		is_casting_fireball = false
		is_casting_shockwave = false
		is_punching = false
		return 
	
	_update_skill_timers(delta)
	
	if is_instance_valid(Global.Player):
		move_towards_player()
	
	move_and_slide()

func _update_skill_timers(delta: float) -> void:
	if is_casting_fireball or is_casting_shockwave or is_punching:
		return
	
	var dist = 0.0
	if is_instance_valid(Global.Player):
		dist = global_position.distance_to(Global.Player.global_position)
	
	fireball_timer += delta
	if fireball_timer >= fireball_cooldown:
		if dist > 70:
			fireball_timer = 0.0
			shoot_fireball()
			return
	
	shockwave_timer += delta
	if shockwave_timer >= shockwave_cooldown:
		if dist >= shockwave_min_range and dist <= shockwave_max_range:
			shockwave_timer = 0.0
			cast_shockwave()
			return
	
	punch_timer += delta
	if punch_timer >= punch_cooldown:
		if dist < punch_range and dist > 30:
			punch_timer = 0.0
			perform_punch()
			return

func move_towards_player() -> void:
	if is_bouncing or is_casting_fireball or is_casting_shockwave or is_punching:
		return

	var target_pos = Global.Player.global_position
	velocity = global_position.direction_to(target_pos) * speed

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision == null: continue
			
		var body = collision.get_collider()
		if body == Global.Player and can_attack:
			attack_player()

func shoot_fireball() -> void:
	is_casting_fireball = true
	velocity = Vector2.ZERO 
	modulate = Color(1.5, 1.0, 0.5) 
	
	await get_tree().create_timer(0.5).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var spawn_pos = global_position
		var target_pos = Global.Player.global_position
		var dir = spawn_pos.direction_to(target_pos)
		
		var fireball = FIREBALL_SCENE.instantiate()
		fireball.set("direction", dir)
		fireball.rotation = dir.angle()
		
		get_tree().current_scene.add_child(fireball)
		fireball.global_position = spawn_pos
		print("BOSS: Fireball spawned")
	
	modulate = Color.WHITE 
	await get_tree().create_timer(0.5).timeout
	is_casting_fireball = false

func cast_shockwave() -> void:
	is_casting_shockwave = true
	velocity = Vector2.ZERO
	modulate = Color(1.0, 0.3, 0.3)
	
	print("BOSS: Charging Shockwave...")
	await get_tree().create_timer(1.0).timeout
	
	if Global.McHealth > 0:
		var shockwave = SHOCKWAVE_SCENE.instantiate()
		get_tree().current_scene.add_child(shockwave)
		shockwave.global_position = global_position
		print("BOSS: Shockwave released")
	
	modulate = Color.WHITE
	await get_tree().create_timer(0.5).timeout
	is_casting_shockwave = false

func perform_punch() -> void:
	is_punching = true
	velocity = Vector2.ZERO
	modulate = Color(1.2, 0.5, 1.2) # Warna Ungu

	print("Boss charge punch")
	await get_tree().create_timer(0.3).timeout

	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var dir = global_position.direction_to(Global.Player.global_position)
		var punch = PUNCH_HITBOX_SCENE.instantiate()
		get_tree().current_scene.add_child(punch)

		punch.global_position = global_position + (dir * 50)
		punch.rotation = dir.angle()
		print("Boss punch released")
	
	modulate = Color.WHITE
	await get_tree().create_timer(0.5).timeout
	is_punching = false

func attack_player() -> void:
	if Global.McHealth <= 0 or not can_attack:
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
		
		await get_tree().create_timer(0.2).timeout
		is_bouncing = false 
		
		await get_tree().create_timer(attack_cooldown_time - 0.2).timeout
		can_attack = true

func _trigger_death_scene() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Main/death_scene.tscn")

func take_damage(amount: int) -> void:
	current_health -= amount
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die() -> void:
	if Global.Enemy == self:
		Global.Enemy = null
	print("Mokad")
	modulate = Color.DARK_RED
	await get_tree().create_timer(1.0).timeout
	queue_free()
