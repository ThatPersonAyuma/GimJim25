extends CharacterBody2D

@export var attack_interval = 4
@export var damage_dealt_na = 100
@export var healt = 1000

@onready var  na_range = $NA_range
@onready var na = $"Nearby Attack"
@onready var na_col = $"Nearby Attack/CollisionShape2D"

var is_mc_in_range = false
var attack_cooldown = 0

func _ready() -> void:
	na_range.connect("body_entered", body_entered)
	na_range.connect("body_exited", body_exited)

func _physics_process(delta):
	if attack_cooldown >= attack_interval:
		attack()
		attack_cooldown = 0
	else:
		attack_cooldown+=delta

func attack():
	if is_mc_in_range:
		process_attack()

func process_attack():
	if Global.Player not in na.get_overlapping_bodies():
		look_At_player()
	await get_tree().create_timer(0.5).timeout
	if na.overlaps_body(Global.Player):
		print("Overlap")
		Global.take_damage(self.damage_dealt_na)

func look_At_player():
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

func body_entered(body: CharacterBody2D):
	self.is_mc_in_range = true
	print("Character: ", body.name)
func body_exited(_body):
	print("Status: ", is_mc_in_range)
	self.is_mc_in_range = false
	
