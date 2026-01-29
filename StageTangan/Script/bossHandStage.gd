class_name HandBoss extends CharacterBody2D

const FIREBALL_SCENE = preload("res://StageTangan/fireball.tscn")
const SHOCKWAVE_SCENE = preload("res://StageTangan/shockwave.tscn")
const PUNCH_HITBOX_SCENE = preload("res://StageTangan/punch_hitbox.tscn")
const SWEEP_HITBOX_SCENE = preload("res://StageTangan/sweep_hitbox.tscn")
const SMALL_FIREBALL_SCENE = preload("res://StageTangan/small_fireball.tscn")
const FIREWALL_SHIELD_SCENE = preload("res://StageTangan/firewall_shield.tscn")

@export var max_health: int = 500
@export var base_speed: float = 80.0
@export var base_damage_contact: int = 10
@export var knockback_power: float = 300.0
@export var attack_cooldown_time: float = 1.0

@export var fireball_config: Vector3 = Vector3(4.0, 70.0, 9999.0)
@export var shockwave_config: Vector3 = Vector3(6.0, 30.0, 500.0)
@export var punch_config: Vector3 = Vector3(3.0, 30.0, 100.0)
@export var sweep_config: Vector3 = Vector3(5.0, 60.0, 120.0)
@export var projectile_config: Vector3 = Vector3(6.0, 150.0, 9999.0)
@export var firewall_config: Vector3 = Vector3(18.0, 80.0, 250.0)

@export var projectile_count: int = 5
@export var projectile_spread: float = 45.0

enum SkillState { NONE, FIREBALL, SHOCKWAVE, PUNCH, SWEEP, PROJECTILE, FIREWALL }
enum HandAnim { CLOSE, OPEN }
enum BossPhase { PHASE_1, PHASE_2, PHASE_3 }

const PHASE_STATS = {
	BossPhase.PHASE_1: {"damage": 1.0, "cooldown": 1.0, "speed": 1.0, "proj_add": 0},
	BossPhase.PHASE_2: {"damage": 1.3, "cooldown": 0.8, "speed": 1.2, "proj_add": 2},
	BossPhase.PHASE_3: {"damage": 1.6, "cooldown": 0.6, "speed": 1.4, "proj_add": 4}
}

const PHASE_COLORS = {
	BossPhase.PHASE_1: Color(1.0, 1.0, 1.0),
	BossPhase.PHASE_2: Color(0.85, 0.75, 0.75),
	BossPhase.PHASE_3: Color(0.7, 0.5, 0.5)
}

var current_health: int
var can_attack: bool = true
var is_bouncing: bool = false
var current_skill: SkillState = SkillState.NONE
var current_phase: BossPhase = BossPhase.PHASE_1
var original_scale: Vector2 = Vector2.ONE
var is_shrunk: bool = false

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
	original_scale = scale
	
	skill_configs = {
		SkillState.FIREBALL: fireball_config,
		SkillState.SHOCKWAVE: shockwave_config,
		SkillState.PUNCH: punch_config,
		SkillState.SWEEP: sweep_config,
		SkillState.PROJECTILE: projectile_config,
		SkillState.FIREWALL: firewall_config
	}
	
	_play_hand_anim(HandAnim.CLOSE)
	_apply_phase_effects()
	Global.boss_debuff = Global.BossDebuff.
	Global.reset()

func _physics_process(delta: float) -> void:
	if Global.McHealth <= 0:
		_stop_all_actions()
		return
	
	_check_phase_transition()
	_update_skill_timers(delta)
	
	if is_instance_valid(Global.Player):
		_move_towards_player()
	
	move_and_slide()

func _check_phase_transition() -> void:
	var hp_percent = float(current_health) / float(max_health)
	var new_phase = current_phase
	
	if hp_percent > 0.66:
		new_phase = BossPhase.PHASE_1
	elif hp_percent > 0.33:
		new_phase = BossPhase.PHASE_2
	else:
		new_phase = BossPhase.PHASE_3
	
	if new_phase != current_phase:
		current_phase = new_phase
		_on_phase_change()

func _on_phase_change() -> void:
	print("Cek fase bos ", BossPhase.keys()[current_phase], " ===")
	_apply_phase_effects()
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(self, "modulate", PHASE_COLORS[current_phase], 0.3)

func _apply_phase_effects() -> void:
	modulate = PHASE_COLORS[current_phase]

func _get_phase_stat(stat_name: String) -> float:
	return PHASE_STATS[current_phase][stat_name]

func _get_current_speed() -> float:
	return base_speed * _get_phase_stat("speed")

func _get_current_damage() -> int:
	return int(base_damage_contact * _get_phase_stat("damage"))

func _get_current_cooldown_mult() -> float:
	return _get_phase_stat("cooldown")

func _get_current_projectile_count() -> int:
	return projectile_count + int(_get_phase_stat("proj_add"))

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

func _shrink_boss(target_scale: float, duration: float) -> void:
	if is_shrunk:
		return
	is_shrunk = true
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * target_scale, duration).set_ease(Tween.EASE_OUT)

func _restore_boss_size(duration: float) -> void:
	if not is_shrunk:
		return
	is_shrunk = false
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale, duration).set_ease(Tween.EASE_OUT)

func _update_skill_timers(delta: float) -> void:
	if _is_casting():
		return
	
	var dist = _get_player_distance()
	var cooldown_mult = _get_current_cooldown_mult()
	
	for skill in skill_timers.keys():
		skill_timers[skill] += delta
		var config = skill_configs[skill]
		var adjusted_cooldown = config.x * cooldown_mult
		
		if skill_timers[skill] >= adjusted_cooldown and _is_in_range(dist, config):
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
	velocity = global_position.direction_to(target_pos) * _get_current_speed()

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
		fireball.damage = int(20 * _get_phase_stat("damage"))
		get_tree().current_scene.add_child(fireball)
		fireball.global_position = global_position
		print("BoSs [Fase ", current_phase + 1, "]: Bola api spawn")
	
	await get_tree().create_timer(0.5).timeout
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _cast_shockwave() -> void:
	current_skill = SkillState.SHOCKWAVE
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.OPEN)
	
	print("Boss [Fase ", current_phase + 1, "]: Tahan shockwave")
	await get_tree().create_timer(1.0 * _get_current_cooldown_mult()).timeout
	
	if Global.McHealth > 0:
		var shockwave = SHOCKWAVE_SCENE.instantiate()
		shockwave.burn_damage = int(5 * _get_phase_stat("damage"))
		get_tree().current_scene.add_child(shockwave)
		shockwave.global_position = global_position
		print("Boss [Fase ", current_phase + 1, "]: Shockwave done")
	
	await get_tree().create_timer(0.5).timeout
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _cast_punch() -> void:
	current_skill = SkillState.PUNCH
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.CLOSE)
	
	print("Boss [Fase ", current_phase + 1, "]: Diem dulu")
	await get_tree().create_timer(0.3).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var dir = global_position.direction_to(Global.Player.global_position)
		var punch = PUNCH_HITBOX_SCENE.instantiate()
		punch.boss_ref = self
		punch.damage = int(25 * _get_phase_stat("damage"))
		punch.phase = current_phase
		get_tree().current_scene.add_child(punch)
		punch.global_position = global_position
		punch.rotation = dir.angle()
		print("Boss [Fase ", current_phase + 1, "]:  baru pukul, done")
	
	var punch_total_time = 2.5 if current_phase == BossPhase.PHASE_3 else 2.0
	await get_tree().create_timer(punch_total_time).timeout
	current_skill = SkillState.NONE

func _cast_sweep() -> void:
	current_skill = SkillState.SWEEP
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.CLOSE)
	
	print("Boss [Fase ", current_phase + 1, "]: Sweep...")
	await get_tree().create_timer(0.5).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var dir = global_position.direction_to(Global.Player.global_position)
		var sweep = SWEEP_HITBOX_SCENE.instantiate()
		sweep.damage = int(20 * _get_phase_stat("damage"))
		get_tree().current_scene.add_child(sweep)
		sweep.global_position = global_position
		sweep.rotation = dir.angle()
		print("Boss [Fase ", current_phase + 1, "]: Sweep done")
	
	await get_tree().create_timer(0.6).timeout
	current_skill = SkillState.NONE

func _cast_projectiles() -> void:
	current_skill = SkillState.PROJECTILE
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.OPEN)
	
	print("Fase [", current_phase + 1, "]: Projectile")
	await get_tree().create_timer(0.6).timeout
	
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var base_dir = global_position.direction_to(Global.Player.global_position)
		var base_angle = base_dir.angle()
		var count = _get_current_projectile_count()
		var half_spread = deg_to_rad(projectile_spread / 2.0)
		var angle_step = deg_to_rad(projectile_spread) / (count - 1) if count > 1 else 0.0
		
		for i in range(count):
			var final_angle = base_angle - half_spread + (i * angle_step)
			var dir = Vector2(cos(final_angle), sin(final_angle))
			
			var projectile = SMALL_FIREBALL_SCENE.instantiate()
			projectile.direction = dir
			projectile.rotation = final_angle
			projectile.damage = int(10 * _get_phase_stat("damage"))
			get_tree().current_scene.add_child(projectile)
			projectile.global_position = global_position
		
		print("Fase [ ", current_phase + 1, "]: Jumlah projektil", count)
	
	await get_tree().create_timer(0.5).timeout
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _cast_firewall() -> void:
	current_skill = SkillState.FIREWALL
	velocity = Vector2.ZERO
	_play_hand_anim(HandAnim.OPEN)
	
	print("Fase [ ", current_phase + 1, "]: Firewall")
	
	var shrink_scale = 0.7 if current_phase == BossPhase.PHASE_3 else 0.8
	_shrink_boss(shrink_scale, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	
	if Global.McHealth > 0:
		var safe_to_spawn = _is_safe_spawn_position()
		
		if safe_to_spawn:
			var firewall = FIREWALL_SHIELD_SCENE.instantiate()
			firewall.boss_ref = self
			firewall.boss_scale = shrink_scale
			firewall.burn_damage_percent = 0.10 + (0.05 * current_phase)
			get_tree().current_scene.add_child(firewall)
			firewall.global_position = global_position
			print("Fase [", current_phase + 1, "]: Firewall shield clear")
			
			await get_tree().create_timer(firewall.duration - 1.0).timeout
		else:
			print("up to wall, cancel dlu")
			_restore_boss_size(0.3)
	
	await get_tree().create_timer(0.5).timeout
	_restore_boss_size(0.5)
	_play_hand_anim(HandAnim.CLOSE)
	current_skill = SkillState.NONE

func _is_safe_spawn_position() -> bool:
	var space_state = get_world_2d().direct_space_state
	var min_distance: float = 100.0
	
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
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
	Global.take_damage(_get_current_damage())
	
	if Global.McHealth <= 0:
		print("mc mati sm bos")
		return
	
	is_bouncing = true
	velocity = global_position.direction_to(Global.Player.global_position) * -300
	
	await get_tree().create_timer(0.2).timeout
	is_bouncing = false
	
	await get_tree().create_timer(attack_cooldown_time - 0.2).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	current_health -= amount
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.RED, 0.05)
	flash_tween.tween_property(self, "modulate", PHASE_COLORS[current_phase], 0.1)
	
	print("Boss HP: ", current_health, "/", max_health, " (Fase ", current_phase + 1, ")")
	
	if current_health <= 0:
		_die()

func _die() -> void:
	if Global.Enemy == self:
		Global.Enemy = null
	print("bos mati")
	modulate = Color.DARK_RED
	await get_tree().create_timer(1.0).timeout
	queue_free()
