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
@onready var melee_attack_cooldown_timer: Timer = $MeeleCooldownTimer
@onready var arrow_cooldown_timer = $RangeCooldownTimer
@onready var dash_cooldown_timer = $DashCooldownTimer

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
var is_heavy_attack_ready = true
var is_heavy_running = false

var heavy_attack_cooldown = 5
var melee_cooldown = 2
var arrow_cooldown = 5
var dash_cooldown = 8


func _enter_tree():
	Global.Player = self

func _ready() -> void:
	camera.limit_left = max_cam_left
	camera.limit_top = max_cam_top
	camera.limit_right = max_cam_right
	camera.limit_bottom = max_cam_bottom
	camera.zoom = Vector2(cam_zoom, cam_zoom)
	melee_attack_cooldown_timer.wait_time = melee_cooldown
	arrow_cooldown_timer.wait_time = arrow_cooldown
	dash_cooldown_timer.wait_time = dash_cooldown
	$Area2D.connect("body_entered", give_damage)
	anim_player.animation_finished.connect(_on_animation_player_animation_finished)
	var arrow = preload("res://Main/arrow.tscn")
	var parent = get_node("..")
	for i in range(3):
		var temp_arrow = arrow.instantiate()
		parent.add_child.call_deferred(temp_arrow)
		temp_arrow.self_index = i
		temp_arrow.max_distance = self.range_attack_radius
		arrows.push_back(temp_arrow)
		
	

func _physics_process(delta):
	if not Global.is_death:
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
	if not is_heavy_running and melee_attack_cooldown_timer.is_stopped() and Input.is_action_just_pressed("attack_sword"):
		if attack_count == 0:
			attack_count += 1
			is_attacking = true
			do_melee_attack()
		elif not is_next_attack and attack_count<attacks_max and attack_melee_interval < attack_melee_interval_count:
				attack_count += 1
				is_next_attack = true
	
	elif arrow_cooldown_timer.is_stopped() and Input.is_action_just_pressed("attack_bow") and attack_count == 0:
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
	arrow_cooldown_timer.start()
	self.travel_arrow_count += 1
	for i in range(max_arrow):
		if available_arrows[i]:
			arrows[i].launch()
			available_arrows[i] = false
			break
		
func do_melee_attack():
	attack_melee_interval = 0
	anim_player.play(attacks_corrupted[0] if is_corrupted else attacks[0])

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
	melee_attack_cooldown_timer.start()
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

	if dash_cooldown_timer.is_stopped() and Input.is_action_just_pressed("dash"):
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
	dash_cooldown_timer.start()
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
		else:
			print("Alert! Give Enemey Take Damage Method")

func play_hitted():
	if attack_count>0: restart_attack()
	anim_player.play("hit")
	is_hurt = true
