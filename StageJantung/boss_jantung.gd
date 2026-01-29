extends CharacterBody2D

@onready var sfx_ngibas = $NgibasSFX

enum BossStage{
	STATE1,
	STATE2,
	STATE3
}
var state = BossStage.STATE1
@export var attack_interval = 3
@export var damage_dealt_na = 100
@export var health = 1000
@export var knockback_pwr: float = 0.4
@export var hurricane_duration = 10
@export var hurricane_push_pwr: float = 0.2
@export var arrow_speed = 400
@export var arrow_damage = 10 
@export var wind_wall_damage = 10
@export var intro_duration = 2
@export var current_health = self.health
@export var move_speed := 50.0
@export var arrive_distance := 5.0

@onready var  na_range = $NA_range
@onready var na = $"Nearby Attack"
@onready var na_col = $"Nearby Attack/CollisionShape2D"
@onready var arrows_node = $Arrows
var arrow_intervals = [14, 20, 27]
var is_arrow_ready = true

var slash_damage = 10
var wind_slashs = []
var is_slash_ready = true #
var slash_cooldown = 8
var is_slash_available = true
var is_na_ready = false

var attack_cooldown = attack_interval
var is_mc_in_range = false
var current_anim = "stage1"

#tornade
var whirlwinds = []
var whirlwind_available = [true, true]
var whirlwind_duration = 8
var is_whirlwind_ready = true #
var whirlwind_cooldown = 12

#wall
var wind_walls = []
var wind_walls_available = []
var ww_distance = 160
var boolean = [true, false]
var ww_duration = 6
var is_ww_ready = true #
var ww_cooldown = 12

#blizzard
var push_pow: float = 0.4
var is_bliz_ready = true #
var bliz_cooldown = 30
var bliz_duration = 8
var bliz_node = null
var is_active = false

# moving
var area_state = 0
var target_pos = Vector2.ZERO

var is_moving = false
var direction = Vector2.ZERO
var to_center = false

var moving_cooldown = [18, 25, 35]
var is_moving_ready = false

@onready var blizz_effect = $AnimatedSprite2D2

func _ready() -> void:
	na_range.connect("body_entered", body_entered)
	na_range.connect("body_exited", body_exited)
	Global.Enemy = self
	var root = get_tree().root
	var wind_slash = preload("res://StageJantung/wind_slash.tscn")
	var slash = wind_slash.instantiate()
	slash.damage = slash_damage
	root.add_child.call_deferred(slash)
	wind_slashs.push_back(slash)
	var wind_wall = preload("res://StageJantung/WindWall.tscn")
	var ww1 = wind_wall.instantiate()
	ww1.self_index = 0
	root.add_child.call_deferred(ww1)
	wind_walls.push_back(ww1)
	wind_walls_available.push_back(true)
	var ww2 = wind_wall.instantiate()
	ww2.self_index = 1
	root.add_child.call_deferred(ww2)
	wind_walls.push_back(ww2)
	wind_walls_available.push_back(true)
	var whirlwind = preload("res://StageJantung/whirlwind.tscn")
	var whirlwind1 = whirlwind.instantiate()
	whirlwind1.self_index = 0
	var whirlwind2 = whirlwind.instantiate()
	whirlwind2.self_index = 1
	root.add_child.call_deferred(whirlwind1)
	root.add_child.call_deferred(whirlwind2)
	whirlwinds.push_back(whirlwind1)
	whirlwinds.push_back(whirlwind2)
	get_direction()
	root.add_child.call_deferred(blizz_effect)
	self.remove_child(blizz_effect)
	
	get_tree().create_timer(intro_duration).timeout.connect(func():
		is_active = true)
	get_tree().create_timer(slash_cooldown).timeout.connect(func():
		is_slash_ready = true)
	get_tree().create_timer(arrow_intervals[-1]).timeout.connect(func():
		is_arrow_ready = true)
	get_tree().create_timer(moving_cooldown[0]).timeout.connect(func():
		is_moving_ready = true)
	get_tree().create_timer(55).timeout.connect(func():
		if not is_instance_valid(self):return
		area_state = 1
		get_tree().create_timer(55).timeout.connect(func():
			if not is_instance_valid(self):return
			area_state = 2
			)
		)
	#bliz_node.

func _physics_process(delta):
	if is_active:
		if attack_cooldown >= attack_interval:
			attack_cooldown = 0
			attack()
		else:
			if attack_cooldown < attack_interval:
				attack_cooldown+=delta
		if is_slash_ready and is_slash_available:
			slash_attack()
		if is_arrow_ready:
			arrow_attack()
		if is_moving_ready:
			moving()
		if is_moving:
			if global_position.distance_to(target_pos) > arrive_distance:
				global_position += direction * move_speed * delta
			else:
				arrive()
		
		if state == BossStage.STATE1:
			return
		if is_bliz_ready:
			summon_blizzard()
		
			
		if is_whirlwind_ready:
			summon_whirlwind()
		if is_ww_ready:
			if boolean.pick_random():
				wind_wall_def()
			else:
				wind_wall_offense()
		#if state == BossStage.STATE2:
			#return
		#if state == BossStage.STATE3:
			#return
		
func summon_blizzard():
	"""
	First timer for calculate the duration of the blizzard.
	Second is for coldown of the blizz
	"""
	blizz_effect.visible = true
	if not sfx_ngibas.playing:
		sfx_ngibas.play()
	blizz_effect.global_position = Global.Player.global_position
	var direction = (Global.Player.global_position - self.global_position).normalized()
	blizz_effect.rotation = direction.angle()
	Global.mov_push = direction * push_pow
	is_bliz_ready = false
	get_tree().create_timer(bliz_duration).timeout.connect(func():
		if not is_instance_valid(self): return
		Global.mov_push = Vector2.ZERO
		blizz_effect.visible = false)
	get_tree().create_timer(bliz_cooldown).timeout.connect(func():
		if not is_instance_valid(self): return
		is_bliz_ready = true)
		
func summon_whirlwind():
	for i in range(2):
		if whirlwind_available[i]:
			sfx_ngibas.play()
			whirlwinds[i].launch(whirlwind_duration)
			is_whirlwind_ready = false
			get_tree().create_timer(whirlwind_cooldown).timeout.connect(func():
				if not is_instance_valid(self): return
				is_whirlwind_ready = true)
		
func wind_wall_def():
	sfx_ngibas.play()
	var direction = (Global.Player.global_position - self.global_position).normalized()
	var is_horizontal = false
	var distance = Vector2.ZERO
	if boolean.pick_random():
		is_horizontal = false
		if direction.x < 0:
			distance = Vector2(-ww_distance, 0)
		else:
			distance = Vector2(ww_distance, 0)
	else:
		if direction.y < 0:
			distance = Vector2(0, -ww_distance)
		else:
			distance = Vector2(0, ww_distance)
	for i in range(2):
		if wind_walls_available[i]:
			wind_walls_available[i] = false
			wind_walls[i].launch(self.global_position+distance, ww_duration*0.5, is_horizontal)
	
func ww_start_cooldown():
	get_tree().create_timer(ww_cooldown).timeout.connect(func():
		if not is_instance_valid(self):
			return
		is_ww_ready = true)
	
func wind_wall_offense():
	sfx_ngibas.play()
	var is_horizontal = true
	if boolean.pick_random():
		is_horizontal = false
	for i in range(2):
		if wind_walls_available[i]:
			wind_walls_available[i] = false
			wind_walls[i].launch(Global.Player.global_position, ww_duration, is_horizontal)
	
func slash_attack():
	is_slash_ready = false
	sfx_ngibas.play()
	wind_slashs[0].launch()
	get_tree().create_timer(slash_cooldown).timeout.connect(func():
		if not is_instance_valid(self): return
		is_slash_ready = true)
		
func arrow_attack():
	is_arrow_ready = false
	sfx_ngibas.play()
	arrows_node.launch()
	get_tree().create_timer(arrow_intervals.pick_random()).timeout.connect(func():
		if not is_instance_valid(self): return
		is_arrow_ready = true)

func attack():
	if is_mc_in_range:
		process_attack()

func process_attack():
	na.monitoring = true
	if Global.Player not in na.get_overlapping_bodies():
		na.monitoring = false
		look_at_player()

func look_at_player():
	var enemy_pos = global_position
	var player_pos = Global.Player.global_position

	var local_point = na_col.polygon[3]
	var point_global = na_col.global_transform * local_point
	
	var dir_current = point_global - enemy_pos
	var angle_current = dir_current.angle()
	
	var dir_target = player_pos - enemy_pos
	var angle_target = dir_target.angle()
	
	var rotation_needed = angle_target - angle_current
	$"Nearby Attack/Polygon2D".visible = true
	$"Nearby Attack/Polygon2D".rotate(rotation_needed)
	await get_tree().create_timer(1).timeout
	if not is_instance_valid(self):
		return
	$"Nearby Attack/Polygon2D".visible = false
	$"Nearby Attack/CollisionShape2D".rotate(rotation_needed)
	$"Nearby Attack/AnimatedSprite2D".rotate(rotation_needed)
	$"Nearby Attack/AnimatedSprite2D".visible = true
	na.monitoring = true
	is_na_ready = true
	await get_tree().create_timer(1).timeout # timer attack
	if not is_instance_valid(self):
		return
	na.monitoring = false
	is_na_ready = false
	$"Nearby Attack/AnimatedSprite2D".visible = false
	
func take_damage(amount: int):
	$AnimationPlayer.play("hitted")
	self.current_health -= amount
	match self.state:
		BossStage.STATE1:
			if self.current_health <= self.health*0.7:
				self.state = BossStage.STATE2
				current_anim = "stage2"
				slash_cooldown -= 2
				arrow_intervals.pop_back()
				moving_cooldown.pop_back()
				get_tree().create_timer(whirlwind_cooldown).timeout.connect(func():
					if not is_instance_valid(self):return
					is_whirlwind_ready = true)
				get_tree().create_timer(ww_cooldown).timeout.connect(func():
					if not is_instance_valid(self):return
					is_ww_ready = true)
				get_tree().create_timer(is_bliz_ready).timeout.connect(func():
					if not is_instance_valid(self):return
					is_bliz_ready = true)
		BossStage.STATE2:
			if self.current_health <= self.health*0.4:
				self.state= BossStage.STATE3
				current_anim = "stage3"
				attack_interval -= 1
				ww_cooldown -= 2
				whirlwind_cooldown -= 3
				bliz_cooldown -= 6
				bliz_duration += 2
	$AnimatedSprite2D.play(current_anim)
	if self.current_health <= 0:
		is_active = false
		free_resource()
		
func free_resource():
	arrows_node.free_Arrows()
	for item in wind_slashs:
		if is_instance_valid(item):
			item.queue_free()

	for item in whirlwinds:
		if is_instance_valid(item):
			item.queue_free()

	for item in wind_walls:
		if is_instance_valid(item):
			item.queue_free()
	

	wind_slashs.clear()
	whirlwinds.clear()
	wind_walls.clear()

	await get_tree().create_timer(1).timeout
	queue_free()


func body_entered(body: CharacterBody2D):
	if body == Global.Player:
		self.is_mc_in_range = true

func body_exited(_body):
	self.is_mc_in_range = false	


func _on_nearby_attack_body_entered(body: Node2D) -> void:
	if is_na_ready:
		Global.McKnockBack(knockback_pwr, self.global_position)
		Global.take_damage(self.damage_dealt_na)

func moving():
	is_moving = true
	is_moving_ready = false
	get_tree().create_timer(moving_cooldown.pick_random()).timeout.connect(func():
		if not is_instance_valid(self):return
		is_moving_ready = true)
	
func arrive():
	is_moving = false
	if target_pos == Vector2.ZERO:
		to_center = false
	else:
		to_center = true
	get_direction()
	
func get_radius():
	if to_center:
		return 0
	match area_state:
		0: # radius 330
			return 132
		1: # radius 230
			return 92
		_:
			return 0
				
func get_direction():
	var angle = randf_range(0, TAU)
	var radius = get_radius()
	var dist = randf_range(radius/2, radius)
	target_pos = Vector2(
		cos(angle) * dist,
		sin(angle) * dist
	)
	self.direction = (target_pos - global_position).normalized()
