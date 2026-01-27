extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var  NearbyAttackRange = $NA_range
@onready var NearbyAttackCollision = $NearbyAttack/CollisionShape2D
@onready var WaterBeam = $WaterBeam 
@onready var NearbyAttack = $NearbyAttack
@onready var shoot_point = $ShootPoint

@export var knockback_dmg: int = 10
@export var speed = 50.0
@export var max_health = 50


var waves_path = preload("res://StageKepala/bullet.tscn")
var bullet_path = preload("res://StageKepala/bullet2.tscn")
var can_shoot_bullets= true
var can_shoot_waves = true
var shoot_cooldown_bullets = 0.8
var shoot_cooldown_waves = 3
var player = null
var HP : int
var is_mc_in_range = false
var can_attack: bool = true
var state = "idle"
var phase_2 = false

func _ready() -> void:
	HP = max_health
	
	NearbyAttackRange.connect("body_entered", body_entered)
	NearbyAttackRange.connect("body_exited", body_exited)
	self.remove_child(WaterBeam)
	
	anim.animation_finished.connect(_on_animation_finished)

	Global.Enemy = self
	OnIdle()

func _physics_process(delta):
	if Global.McHealth <= 0:
		velocity = Vector2.ZERO
		return

	if phase_2 and state == "move":
		DetectPlayer()
		move_and_slide()
		fire_bullet()
		fire_waves()

	if state == "move":
		DetectPlayer()
		move_and_slide()
		fire_waves()

	elif state == "knockback":
		move_and_slide()

func OnIdle():
	state = "idle"
	velocity = Vector2.ZERO
	anim.animation = "idle"
	anim.play()
	
	await get_tree().create_timer(2.0).timeout
	print("ini seharusnya jalan abis 2 detik")
	OnMove()
	
func OnMove():
	state = "move"
	anim.animation = "walk"
	anim.play()
	
	#await get_tree().create_timer(0.2).timeout
	#print("ini seharusnya diam abis 1 detik")
	#dOnIdle()

func _on_animation_finished():
	if state == "move":
		anim.play("walk")

func DetectPlayer():
		var target_pos = Global.Player.global_position
		velocity = global_position.direction_to(target_pos) * speed

func fire_waves():
	if not can_shoot_waves:
		return

	can_shoot_waves = false

	var bullet = waves_path.instantiate()
	get_parent().add_child(bullet)

	bullet.global_position = shoot_point.global_position

	if Global.Player:
		var dir = (Global.Player.global_position - shoot_point.global_position).normalized()
		bullet.set_direction(dir)

	print("bullet fired")
	anim.animation = "fire_waves"
	anim.play()
	await get_tree().create_timer(shoot_cooldown_waves).timeout
	can_shoot_waves = true

func fire_bullet():
	if not can_shoot_bullets:
		return

	can_shoot_bullets = false

	var bullet = bullet_path.instantiate()
	get_parent().add_child(bullet)

	bullet.global_position = shoot_point.global_position

	if Global.Player:
		var dir = (Global.Player.global_position - shoot_point.global_position).normalized()
		bullet.set_direction(dir)

	print("bullet fired")

	await get_tree().create_timer(shoot_cooldown_bullets).timeout
	can_shoot_bullets = true

func OnKnockback(player):
	state = "knockback"
	Global.take_damage(knockback_dmg)

	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 200.0

	await get_tree().create_timer(0.5).timeout
	OnMove()

func OnKnockbackAtk(player):
	state = "knockback"
	take_damage(knockback_dmg)

	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 300.0

	await get_tree().create_timer(0.5).timeout
	OnMove()
	
func take_damage(amount):
	HP -= amount 
	print("current HP: ", HP) 
	modulate = Color.RED 
	var timer = get_tree().create_timer(0.05) 
	await timer.timeout 
	modulate = Color.WHITE
	
	if HP <= 0:
		die()
	elif HP <= 30 and not phase_2:
		enter_phase_2()

func enter_phase_2():
	phase_2 = true
	speed = 55

func die():
	if Global.Enemy == self:
		Global.Enemy = null
	print("boss die")
	queue_free()

func body_entered(body: Node2D):
	if body == Global.Player:
		self.is_mc_in_range = true
		print("Knockback from: ", body.name)

		if body.is_attacking:
			OnKnockbackAtk(body)
		else:
			OnKnockback(body) 

func body_exited(body):
	if body == Global.Player:
		print("Character Out: ", body.name)
