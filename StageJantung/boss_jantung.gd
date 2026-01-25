extends CharacterBody2D

@export var attack_interval = 4
@export var damage_dealt_na = 100
@export var health = 1000
@export var knockback_pwr: float = 0.4
@export var hurricane_duration = 10
@export var hurricane_push_pwr: float = 0.2

@onready var  na_range = $NA_range
@onready var na = $"Nearby Attack"
@onready var na_col = $"Nearby Attack/CollisionShape2D"
@onready var str_wind_node = $Angin

var current_health = self.health
var attack_cooldown = attack_interval
var is_mc_in_range = false

func _ready() -> void:
	self.remove_child(str_wind_node)
	na_range.connect("body_entered", body_entered)
	na_range.connect("body_exited", body_exited)
	summon_strong_wind()
	Global.Enemy = self

func _physics_process(delta):
	if attack_cooldown >= attack_interval:
		attack_cooldown = 0
		attack()
	else:
		if attack_cooldown < attack_interval:
			attack_cooldown+=delta

func attack():
	if is_mc_in_range:
		process_attack()

func process_attack():
	na.monitoring = true
	if Global.Player not in na.get_overlapping_bodies():
		look_at_player()
	var flag = 6
	await get_tree().create_timer(0.5).timeout
	if flag != 6:
		return
	play_attack_anim()
	if na.overlaps_body(Global.Player):
		Global.McKnockBack(knockback_pwr, self.global_position)
		Global.take_damage(self.damage_dealt_na)

func play_attack_anim():
	pass

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

	na.rotate(rotation_needed)

func summon_strong_wind():
	Global.Player.add_child(str_wind_node)
	Global.MovePush(Vector2(-hurricane_push_pwr, 0))
	await get_tree().create_timer(self.hurricane_duration).timeout
	Global.Player.remove_child(str_wind_node)
	Global.MovePush(Vector2(0, 0))
	
func take_damage(amount: int):
	$AnimationPlayer.play("hitted")
	self.current_health -= amount
	if self.current_health <= 0:
		self.queue_free()

func body_entered(body: CharacterBody2D):
	if body == Global.Player:
		self.is_mc_in_range = true
		print("Character: ", body.name)

func body_exited(_body):
	print("Status: ", is_mc_in_range)
	self.is_mc_in_range = false	
