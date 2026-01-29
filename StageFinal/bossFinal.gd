extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var Hitbox = $Hitbox
@onready var BodyArea = $BodyArea
@onready var shoot_point = $ShootPoint
@onready var smokes = $smokes


@export var knockback_dmg: int = 5
@export var speed = 30.0
@export var max_health = 800
@export var mud_pause_time := 2.0
@export var mud_cooldown := 15.0
@export var pseudo_dash_multiplier := 6.0
@export var pseudo_dash_duration := 0.08
@export var pseudo_dash_cooldown := 0.25
@export var whirlwind_duration := 6.0
@export var whirlwind_cooldown := 10.0
@export var fireball_config: Vector3 = Vector3(4.0, 70.0, 9999.0)
@export var fireball_cooldown := 3.0
@export var phase2_threshold := 400


var bullet_path = preload("res://StageKepala/bullet2.tscn")
var laser_path = preload("res://StageKepala/laser.tscn")
var MudAreaScene = preload("res://StageKaki/mud_area.tscn")
var whirlwind_scene = preload("res://StageJantung/whirlwind.tscn")
const FIREBALL_SCENE = preload("res://StageTangan/fireball.tscn")
var waves_path = preload("res://StageKepala/bullet.tscn")


var can_knockback := true
var can_shoot_bullets= true
var can_shoot_laser = true
var can_shoot_waves = true
var shoot_cooldown_bullets = 0.8
var shoot_cooldown_lasers = 15
var shoot_cooldown_waves = 5
var can_spawn_mud := true
var can_summon_whirlwind := true
var can_cast_fireball := true
var mud_chance := 0.4
var whirlwind_available: Array = []


var HP : int
var is_mc_in_range = false
var can_attack: bool = true
var can_pseudo_dash := true
var is_paused := false
var state = "idle"
var phase_2 = false

func _ready() -> void:
	z_index = 0
	HP = max_health
	
	whirlwind_available.resize(100)
	for i in range(whirlwind_available.size()):
		whirlwind_available[i] = true
	
	Hitbox.connect("body_entered", body_entered)
	Hitbox.connect("body_exited", body_exited)
	
	anim.animation_finished.connect(_on_animation_finished)

	Global.Enemy = self
	OnIdle()
	smokes.animation = "smokes"
	smokes.play()

func _physics_process(_delta):
	if Global.McHealth <= 0:
		velocity = Vector2.ZERO
		return
		
	if is_paused:
		velocity = Vector2.ZERO
		return

	match state:
		"knockback":
			move_and_slide()
			return

		"move":
			if state != "knockback":
				DetectPlayer()
			move_and_slide()

			
			if not phase_2:
				try_spawn_mud()
				fire_bullet()
				fire_waves()
				
			if phase_2:
				try_fire_fireball()
				try_fire_laser()
				try_fire_whirlwind()

		"idle":
			velocity = Vector2.ZERO

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

func _on_animation_finished():
	if state == "move":
		anim.play("walk")

func dash_flash():
	anim.modulate = Color(1, 1, 1, 0.3)
	await get_tree().create_timer(0.05).timeout
	anim.modulate = Color.WHITE

func DetectPlayer():
	if state == "knockback":
		return
	if not can_pseudo_dash:
		return
	if not Global.Player:
		return

	can_pseudo_dash = false

	var dir = (Global.Player.global_position - global_position).normalized()

	dash_flash()

	velocity = dir * speed * pseudo_dash_multiplier

	await get_tree().create_timer(pseudo_dash_duration).timeout
	velocity = Vector2.ZERO

	await get_tree().create_timer(pseudo_dash_cooldown).timeout
	can_pseudo_dash = true

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
	anim.animation = "cast"
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

func fire_laser():
	can_shoot_laser = false

	state = "idle"
	velocity = Vector2.ZERO

	var laser = laser_path.instantiate()
	get_parent().add_child(laser)
	laser.global_position = shoot_point.global_position

	if Global.Player:
		var dir = (Global.Player.global_position - shoot_point.global_position).normalized()

		var sweep_dir := 1
		if randf() < 0.5:
			sweep_dir = -1

		var warning_angle := deg_to_rad(40)

		laser.rotation = dir.angle() - (warning_angle * sweep_dir)

		laser.sweep_dir = sweep_dir

	anim.animation = "cast"
	anim.play()

	await get_tree().create_timer(2.0).timeout
	OnMove()

	await get_tree().create_timer(shoot_cooldown_lasers).timeout
	can_shoot_laser = true

func try_fire_laser():
	if not phase_2:
		return
	if not can_shoot_laser:
		return
	fire_laser()

func fire_whirlwind():
	can_summon_whirlwind = false
	state = "idle"
	velocity = Vector2.ZERO

	anim.animation = "cast"
	anim.play()

	# delay warning (telegraph)
	await get_tree().create_timer(0.8).timeout

	# spawn whirlwind
	var whirlwind = whirlwind_scene.instantiate()
	get_parent().add_child(whirlwind)

	if Global.Player:
		var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
		whirlwind.global_position = Global.Player.global_position + offset
	else:
		whirlwind.global_position = global_position

	whirlwind.launch(whirlwind_duration)

	# tunggu durasi skill
	await get_tree().create_timer(whirlwind_duration).timeout
	OnMove()

	# cooldown
	await get_tree().create_timer(whirlwind_cooldown).timeout
	can_summon_whirlwind = true

func try_fire_whirlwind():
	if not phase_2:
		return
	if not can_summon_whirlwind:
		return

	fire_whirlwind()

func spawn_mud():
	can_spawn_mud = false

	var mud = MudAreaScene.instantiate()
	mud.z_index = -1
	get_parent().add_child(mud)
	mud.global_position = global_position + Vector2(0, 24)

	enter_mud_attack()

	await get_tree().create_timer(mud_cooldown).timeout
	can_spawn_mud = true

func enter_mud_attack():
	is_paused = true
	velocity = Vector2.ZERO

	await get_tree().create_timer(mud_pause_time).timeout

	is_paused = false
	
func try_spawn_mud():
	if phase_2:
		return
	if not can_spawn_mud:
		return

	spawn_mud()

func fire_fireball():
	if not is_inside_tree():
		return
	if not can_cast_fireball:
		return

	can_cast_fireball = false

	state = "idle"
	velocity = Vector2.ZERO

	anim.animation = "cast"
	anim.play()

	# delay cast (telegraph)
	await get_tree().create_timer(0.5).timeout

	var fireball = FIREBALL_SCENE.instantiate()
	get_parent().add_child(fireball)

	fireball.global_position = shoot_point.global_position

	if Global.Player:
		var dir = (Global.Player.global_position - shoot_point.global_position).normalized()
		fireball.direction = dir
		fireball.rotation = dir.angle()

	print("fireball cast")

	# balik ke move
	await get_tree().create_timer(0.4).timeout
	OnMove()

	# cooldown
	await get_tree().create_timer(fireball_cooldown).timeout
	can_cast_fireball = true

func try_fire_fireball():
	if not phase_2:
		return
	if not can_cast_fireball:
		return

	fire_fireball()

func OnKnockback(player):
	state = "knockback"
	Global.take_damage(knockback_dmg)

	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 125.0

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
	elif HP <= phase2_threshold and not phase_2:
		enter_phase_2()

func enter_phase_2():
	phase_2 = true
	speed = 50

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
