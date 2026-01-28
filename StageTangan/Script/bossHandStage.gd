class_name HandBoss extends CharacterBody2D

const FIREBALL_SCENE = preload("res://StageTangan/fireball.tscn")
const SHOCKWAVE_SCENE = preload("res://StageTangan/shockwave.tscn")
const PUNCH_HITBOX_SCENE = preload("res://StageTangan/punch_hitbox.tscn")
const SWEEP_HITBOX_SCENE = preload("res://StageTangan/sweep_hitbox.tscn")
const SMALL_FIREBALL_SCENE = preload("res://StageTangan/small_fireball.tscn")
const FIREWALL_SHIELD_SCENE = preload("res://StageTangan/firewall_shield.tscn")

@export var max_health: int = 500
@export var speed: float = 100.0
@export var damage_contact: int = 15
@export var knockback_power: float = 300.0
@export var attack_cooldown_time: float = 1.0

@export var fireball_config: Vector3 = Vector3(3.0, 70.0, 9999.0)
@export var shockwave_config: Vector3 = Vector3(5.0, 30.0, 500.0)
@export var punch_config: Vector3 = Vector3(2.0, 30.0, 80.0)
@export var sweep_config: Vector3 = Vector3(4.0, 60.0, 120.0)
@export var projectile_config: Vector3 = Vector3(5.0, 150.0, 9999.0)
@export var firewall_config: Vector3 = Vector3(15.0, 80.0, 250.0)

@export var projectile_count: int = 5
@export var projectile_spread: float = 45.0

enum SkillState { NONE, FIREBALL, SHOCKWAVE, PUNCH, SWEEP, PROJECTILE, FIREWALL }
enum HandAnim { CLOSE, OPEN }

var current_health: int
var can_attack: bool = true
var is_bouncing: bool = false
var current_skill: SkillState = SkillState.NONE

var skill_timers: Dictionary = {
	SkillState.FIREBALL: 0.0,
	SkillState.SHOCKWAVE: 0.0,
	SkillState.PUNCH: 0.0,
	SkillState.SWEEP: 0.0,
	SkillState.PROJECTILE: 0.0,
	SkillState.FIREWALL: 0.0
}

var skill_configs: Dictionary

@onready var anim_sprite: AnimatedSprite2D = $BossSprite

func _ready() -> void:
	current_health = max_health
	Global.Enemy = self
	
	skill_configs = {
		SkillState.FIREBALL: fireball_config,
		SkillState.SHOCKWAVE: shockwave_config,
		SkillState.PUNCH: punch_config,
		SkillState.SWEEP: sweep_config,
		SkillState.PROJECTILE: projectile_config,
		SkillState.FIREWALL: firewall_config
	}
	
	_play_hand_anim(HandAnim.CLOSE)

func _physics_process(delta: float) -> void:
	if Global.McHealth <= 0:
		_stop_all_actions()
		return
	
	_update_skill_timers(delta)
	
	if is_instance_valid(Global.Player):
		_move_towards_player()
	
	move_and_slide()

func _is_casting() -> bool:
	return current_skill != SkillState.NONE

func _stop_all_actions() -> void:
	velocity = Vector2.ZERO
	current_skill = SkillState.NONE

func _get_player_distance() -> float:
	if is_instance_valid(Global.Player):
		return global_position.distance_to(Global.Player.global_position)
	return 0.0

func _is_in_range(dist: float, config: Vector3) -> bool:
	return dist >= config.y and dist <= config.z

func _play_hand_anim(hand: HandAnim) -> void:
	if not is_instance_valid(anim_sprite):
		return
	match hand:
		HandAnim.CLOSE:
			anim_sprite.play("Close Hand")
		HandAnim.OPEN:
			anim_sprite.play("Open Hand")

func _update_skill_timers(delta: float) -> void:
	if _is_casting():
		return
	
	var dist = _get_player_distance()
	
	for skill in skill_timers.keys():
		skill_timers[skill] += delta
		var config = skill_configs[skill]
		
		if skill_timers[skill] >= config.x and _is_in_range(dist, config):
			skill_timers[skill] = 0.0
			_execute_skill(skill)
			return

func _execute_skill(skill: SkillState) -> void:
	match skill:
		SkillState.FIREBALL: _cast_fireball()
		SkillState.SHOCKWAVE: _cast_shockwave()
		SkillState.PUNCH: _cast_punch()
		SkillState.SWEEP: _cast_sweep()
		SkillState.PROJECTILE: _cast_projectiles()
		SkillState.FIREWALL: _cast_firewall()

func _move_towards_player() -> void:
	if is_bouncing or _is_casting():
		return

	var target_pos = Global.Player.global_position
	velocity = global_position.direction_to(target_pos) * speed

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		if collision.get_collider() == Global.Player and can_attack:
			_attack_player()

func _cast_fireball() -> void:
	current_skill = SkillState.FIREBALL
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.OPEN)
	
	await get_tree().create_timer(0.5).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var dir = global_position.direction_to(Global.Player.global_position)
		var fireball = FIREBALL_SCENE.instantiate()
		fireball.direction = dir
		fireball.rotation = dir.angle()
		get_tree().current_scene.add_child(fireball)
		fireball.global_position = global_position
		print("BOSS: Fireball spawned")
	
	await get_tree().create_timer(0.5).timeout
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _cast_shockwave() -> void:
	current_skill = SkillState.SHOCKWAVE
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.OPEN)
	
	print("BOSS: Charging Shockwave...")
	await get_tree().create_timer(1.0).timeout
	
	if Global.McHealth > 0:
		var shockwave = SHOCKWAVE_SCENE.instantiate()
		get_tree().current_scene.add_child(shockwave)
		shockwave.global_position = global_position
		print("BOSS: Shockwave released")
	
	await get_tree().create_timer(0.5).timeout
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _cast_punch() -> void:
	current_skill = SkillState.PUNCH
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.CLOSE)

	print("BOSS: Charging Punch...")
	await get_tree().create_timer(0.3).timeout

	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var dir = global_position.direction_to(Global.Player.global_position)
		var punch = PUNCH_HITBOX_SCENE.instantiate()
		get_tree().current_scene.add_child(punch)
		punch.global_position = global_position + (dir * 50)
		punch.rotation = dir.angle()
		print("BOSS: Punch released!")
	
	await get_tree().create_timer(0.5).timeout
	current_skill = SkillState.NONE

func _cast_sweep() -> void:
	current_skill = SkillState.SWEEP
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.CLOSE)
	
	print("BOSS: Charging Sweep...")
	await get_tree().create_timer(0.5).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var dir = global_position.direction_to(Global.Player.global_position)
		var sweep = SWEEP_HITBOX_SCENE.instantiate()
		get_tree().current_scene.add_child(sweep)
		sweep.global_position = global_position
		sweep.rotation = dir.angle()
		print("BOSS: Sweep released!")
	
	await get_tree().create_timer(0.6).timeout
	current_skill = SkillState.NONE

func _cast_projectiles() -> void:
	current_skill = SkillState.PROJECTILE
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.OPEN)
	
	print("BOSS: Charging Projectiles...")
	await get_tree().create_timer(0.6).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var base_dir = global_position.direction_to(Global.Player.global_position)
		var base_angle = base_dir.angle()
		var half_spread = deg_to_rad(projectile_spread / 2.0)
		var angle_step = deg_to_rad(projectile_spread) / (projectile_count - 1)
		
		for i in range(projectile_count):
			var final_angle = base_angle - half_spread + (i * angle_step)
			var dir = Vector2(cos(final_angle), sin(final_angle))
			
			var projectile = SMALL_FIREBALL_SCENE.instantiate()
			projectile.direction = dir
			projectile.rotation = final_angle
			get_tree().current_scene.add_child(projectile)
			projectile.global_position = global_position
		
		print("BOSS: Projectiles released! Count: ", projectile_count)
	
	await get_tree().create_timer(0.5).timeout
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _cast_firewall() -> void:
	current_skill = SkillState.FIREWALL
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.OPEN)
	
	print("BOSS: Charging Firewall Shield...")
	await get_tree().create_timer(1.0).timeout
	
	if Global.McHealth > 0:
		var safe_to_spawn = _is_safe_spawn_position()
		
		if safe_to_spawn:
			var firewall = FIREWALL_SHIELD_SCENE.instantiate()
			firewall.boss_ref = self
			get_tree().current_scene.add_child(firewall)
			firewall.global_position = global_position
			print("BOSS: Firewall Shield activated!")
		else:
			print("BOSS: Too close to wall, Firewall cancelled!")
	
	await get_tree().create_timer(0.5).timeout
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _is_safe_spawn_position() -> bool:
	var space_state = get_world_2d().direct_space_state
	var min_distance: float = 100.0  
	
	var directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]
	
	for dir in directions:
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + (dir * min_distance),
			1 
		)
		query.exclude = [self]
		
		var result = space_state.intersect_ray(query)
		if result:
			return false
	
	return true

func _attack_player() -> void:
	if Global.McHealth <= 0 or not can_attack:
		return
		
	if not is_instance_valid(Global.Player):
		return
	
	can_attack = false
	Global.take_damage(damage_contact)
	
	if Global.McHealth <= 0:
		print("Player Mati oleh Boss")
		return
	
	is_bouncing = true
	velocity = global_position.direction_to(Global.Player.global_position) * -300
	
	await get_tree().create_timer(0.2).timeout
	is_bouncing = false
	
	await get_tree().create_timer(attack_cooldown_time - 0.2).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	current_health -= amount
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		_die()

func _die() -> void:
	if Global.Enemy == self:
		Global.Enemy = null
	print("Boss Defeated!")
	modulate = Color.DARK_RED
	await get_tree().create_timer(1.0).timeout
	queue_free()
