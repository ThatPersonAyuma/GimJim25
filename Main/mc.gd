extends CharacterBody2D

@export var Speed: int = 200
@export var knockback_raw_pow: int = 500
@export var dash_power:int = 260
@export var max_arrow:int = 3
@export var range_attack_radius = 500

@onready var anim_player = $Animation
@onready var anim_sprite = $AnimatedSprite2D
@onready var melee_attack_cooldown = $MeeleCooldownTimer
@onready var arrow_cooldown = $RangeCooldownTimer
@onready var dash_cooldown = $DashCooldownTimer

var is_attacking = false
var attacks_max = 5
var attack_count = 0
var attack_running = 0
var attack_melee_interval_count = 0.5
var attack_melee_interval = 0
var is_dashing = false
var melee_attack_damage = 25
var dash: Vector2 = Vector2.ZERO
var arrows: Array[AnimatedSprite2D] = [] 
var available_arrows: Array[bool] = [true, true, true]
var travel_arrow_count = 0


func _ready() -> void:
	Global.Player = self
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

func _physics_process(delta):
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
	if melee_attack_cooldown.is_stopped() and Input.is_action_just_pressed("attack_sword"):
		if attack_count == 0:
			attack_count += 1
			attack_running += 1
			is_attacking = true
			do_melee_attack()
		elif attack_count<attacks_max and attack_melee_interval < attack_melee_interval_count:
			attack_count += 1
			attack_running += 1
	
	elif arrow_cooldown.is_stopped() and Input.is_action_just_pressed("attack_bow") and attack_count == 0:
		if is_range_attack_available(): do_range_attack()
		
func is_range_attack_available() -> bool:
	return (self.global_position - Global.Enemy.global_position).length() <= range_attack_radius

func do_range_attack():
	arrow_cooldown.start()
	self.travel_arrow_count += 1
	for i in range(max_arrow):
		if available_arrows[i]:
			arrows[i].launch()
			available_arrows[i] = false
			break
		
func do_melee_attack():
	attack_running-=1
	attack_melee_interval = 0
	anim_player.play("attack1")

func _on_animation_player_animation_finished(anim_name):
	if anim_name in ["attack1", "attack2"]:
		if attack_running>0 :
			attack_melee_interval = 0
			attack_running-=1
			if anim_name == "attack1":
				anim_player.play("attack2")
			elif anim_name == "attack2":
				anim_player.play("attack1")
		else:
			restart_attack()
		
func restart_attack():
	melee_attack_cooldown.start()
	self.is_attacking = false
	self.attack_count = 0
	self.attack_melee_interval = 0
		
func Knockback():
	Global.CanCharMove = false
	velocity = Global.knockback_direction * knockback_raw_pow * Global.knocback_pow
	Global.knocback_pow = 0
	var flag = 6
	get_tree().create_timer(0.5).timeout.connect(func():
		if flag != 6:
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
		anim_sprite.play("walk")
	else:
		if direction != Vector2.ZERO:
			direction = direction.normalized()
			anim_sprite.play("walk")
		else:
			anim_sprite.play("idle")
		
	velocity = direction * Speed * Global.slow_mov + Global.mov_push * Speed

func Dash(direction: Vector2):
	self.is_dashing = true
	var flag = 6
	dash_cooldown.start()
	if direction == Vector2.ZERO:
		direction.x = -1 if anim_sprite.flip_h else 1
	self.dash = direction*dash_power
	get_tree().create_timer(0.5).timeout.connect(func():
		if flag != 6:
			return
		self.is_dashing = false)
	
func give_damage(body: CharacterBody2D):
	if body.is_in_group("Enemies"):
		if body.has_method("take_damage"):
			body.take_damage(melee_attack_damage)
		else:
			print("Alert! Give Enemey Take Damage Method")

func play_hitted():
	if attack_count>0: restart_attack()
	anim_player.play("hit")
	#Global.is_invincible = true
	#var flag = 6
	#await  get_tree().create_timer(0.5).timeout.connect(func():
		#if flag != 6:
			#return
		#Global.is_invincible = false)
