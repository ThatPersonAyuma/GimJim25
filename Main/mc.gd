extends CharacterBody2D

@export var Speed: int = 200
@export var knockback_raw_pow: int = 500
@export var dash_power:int = 260
@export var max_arrow:int = 3
@export var range_attack_radius = 500
@export var is_corrupted = false
@export var max_cam_left = -10000000
@export var max_cam_top = -10000000
@export var max_cam_right = 10000000
@export var max_cam_bottom = 10000000
@export var cam_zoom: float = 1

@onready var camera = $Camera2D
@onready var anim_player = $Animation
@onready var anim_sprite = $AnimatedSprite2D
@onready var melee_attack_cooldown = $MeeleCooldownTimer
@onready var arrow_cooldown = $RangeCooldownTimer
@onready var dash_cooldown = $DashCooldownTimer

@onready var sword_sfx = $SwoshSFX
@onready var sword_hit_sfx = $SwordHitSFX
@onready var bow_sfx = $BowSFX
@onready var footstep_sfx = $FootstepSFX
@onready var hurt_sfx = $HurtSFX

var is_attacking = false
var attacks_max = 4
var attack_count = 0
var attack_melee_interval_count = 0.5
var attack_melee_interval = 0
var is_dashing = false
var melee_attack_damage = 25
var dash: Vector2 = Vector2.ZERO
var arrows: Array[Node2D] = [] 
var available_arrows: Array[bool] = [true, true, true]
var travel_arrow_count = 0
var is_next_attack = false
var attacks = ["attack1", "attack2", "attack3", "attack4"]
var attacks_corrupted = ["attack1_corrupted", "attack2_corrupted", "attack3_corrupted", "attack4_corrupted"]
var is_hurt = false

var heavy_attack_damage = 50 
var heavy_attack_cooldown = 5
var is_heavy_attack_ready = true
var is_heavy_running = false

var footstep_timer := 0.0
@export var footstep_interval := 0.65

func _enter_tree():
	Global.Player = self

func _ready() -> void:
	print("Sprite: ", anim_sprite.sprite_frames.get_animation_names())
	camera.limit_left = max_cam_left
	camera.limit_top = max_cam_top
	camera.limit_right = max_cam_right
	camera.limit_bottom = max_cam_bottom
	camera.zoom = Vector2(cam_zoom, cam_zoom)
	
	$Area2D.connect("body_entered", give_damage)
	anim_player.animation_finished.connect(_on_animation_player_animation_finished)
	var arrow = preload("res://Main/arrow.tscn")
	var parent = get_node("..")
	for i in range(3):
		var temp_arrow = arrow.instantiate()
		#print("is self index exist: ", "self_index" in temp_arrow)
		parent.add_child.call_deferred(temp_arrow)
		temp_arrow.self_index = i
		temp_arrow.max_distance = self.range_attack_radius
		arrows.push_back(temp_arrow)
	if "travel_arrow_count" not in self: print("Varibale travel_arrow_count tidak ada")

func _process(delta):
	if anim_sprite.animation in ["walk", "walk_corrupted"] and not is_attacking and not is_dashing:
		footstep_timer -= delta

		if footstep_timer <= 0.0:
			play_footstep_sfx()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0

func _physics_process(delta):
	if not is_hurt and Global.CanCharMove:
		DetectAttack()
		if not is_attacking:
			if not is_dashing:
				if Global.CanCharMove:
					Movement()
		else:
			attack_melee_interval+=delta
			velocity = Vector2.ZERO
			
	if Global.knocback_pow > 0:
		Knockback()
	if is_dashing:
		velocity = dash
	move_and_slide()

func DetectAttack():
	if not is_heavy_running and melee_attack_cooldown.is_stopped() and Input.is_action_just_pressed("attack_sword"):
		if attack_count == 0:
			attack_count += 1
			is_attacking = true
			do_melee_attack()
		elif not is_next_attack and attack_count<attacks_max and attack_melee_interval < attack_melee_interval_count:
				attack_count += 1
				is_next_attack = true
	
	elif arrow_cooldown.is_stopped() and Input.is_action_just_pressed("attack_bow") and attack_count == 0:
		if is_range_attack_available(): do_range_attack()
	elif is_heavy_attack_ready and Input.is_action_just_pressed("attack_heavy"):
		do_heavy_attack()
		
func do_heavy_attack():
	is_heavy_attack_ready = false
	anim_player.play("heavy_attack" if is_corrupted else "heavy_attack")
	is_attacking = true
	self.is_heavy_running = true
	get_tree().create_timer(heavy_attack_cooldown).timeout.connect(func():
		if not is_instance_valid(self): return
		self.is_heavy_attack_ready = true)
		
func is_range_attack_available() -> bool:
	if Global.Enemy == null:
		return false
	return (self.global_position - Global.Enemy.global_position).length() <= range_attack_radius

func do_range_attack():
	arrow_cooldown.start()
	self.travel_arrow_count += 1
	bow_sfx.play()
	for i in range(max_arrow):
		if available_arrows[i]:
			arrows[i].launch()
			available_arrows[i] = false
			break
		
func do_melee_attack():
	attack_melee_interval = 0
	anim_player.play(attacks_corrupted[0] if is_corrupted else attacks[0])
	sword_sfx.play()

func _on_animation_player_animation_finished(anim_name):
	var attacks_name = attacks_corrupted if is_corrupted else attacks
	if anim_name in attacks_name:
		if is_next_attack :
			is_next_attack = false
			attack_melee_interval = 0
			if anim_name ==	attacks_name[0]:
					anim_player.play(attacks_name[1])
			elif anim_name ==	attacks_name[1]:
					anim_player.play(attacks_name[2])
			elif anim_name ==	attacks_name[2]:
					anim_player.play(attacks_name[3])
		else:
			restart_attack()
	elif anim_name == "hit":
		$Area2D.set_deferred("monitoring", false)
		is_hurt = false
		if self.is_attacking:
			restart_attack()
	elif anim_name in ["heavy_attack", "heavy_attack_corrupted"]:
		self.is_attacking = false
		self.is_heavy_running = false
		
		
func restart_attack():
	melee_attack_cooldown.start()
	self.is_attacking = false
	self.attack_count = 0
	self.attack_melee_interval = 0
		
func Knockback():
	Global.CanCharMove = false
	velocity = Global.knockback_direction * knockback_raw_pow * Global.knocback_pow
	Global.knocback_pow = 0
	
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(self):
			return
		Global.CanCharMove = true)

func Movement():
	var direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if direction.x != 0:
		anim_sprite.flip_h = true if direction.x == -1 else false

	if dash_cooldown.is_stopped() and Input.is_action_just_pressed("dash"):
		Dash(direction)
		anim_sprite.play("walk" if not is_corrupted else "walk_corrupted")
	else:
		if direction != Vector2.ZERO:
			direction = direction.normalized()
			anim_sprite.play("walk" if not is_corrupted else "walk_corrupted")
		else:
			anim_sprite.play("idle" if not is_corrupted else "idle_corrupted")
		
	velocity = direction * Speed * Global.slow_mov + Global.mov_push * Speed

func Dash(direction: Vector2):
	self.is_dashing = true
	dash_cooldown.start()
	if direction == Vector2.ZERO:
		direction.x = -1 if anim_sprite.flip_h else 1
	self.dash = direction*dash_power
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(self):
			return
		self.is_dashing = false)
	
func give_damage(body: CharacterBody2D):
	if body == Global.Enemy:
		if body.has_method("take_damage"):
			body.take_damage(melee_attack_damage)
			if sword_hit_sfx:
				sword_hit_sfx.play()
		else:
			print("Alert! Give Enemey Take Damage Method")

func play_hitted():
	if attack_count>0: restart_attack()
	if hurt_sfx:
		hurt_sfx.play()
	anim_player.play("hit")
	is_hurt = true
	#Global.is_invincible = true
	#var flag = 6
	#await  get_tree().create_timer(0.5).timeout.connect(func():
		#if not is_instance_valid(self):
			#return
		#Global.is_invincible = false)

func play_footstep_sfx():
	if footstep_sfx:
		footstep_sfx.pitch_scale = randf_range(1.0, 1.1)
		footstep_sfx.play()
