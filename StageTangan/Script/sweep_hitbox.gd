class_name BossSweepHitbox extends Area2D

@export var damage: int = 20
@export var knockback_power: float = 350.0
@export var lifetime: float = 0.5
@export var arc_radius: float = 80.0
@export var arc_angle: float = 180.0  
var has_hit: bool = false

@onready var collision_polygon = $CollisionPolygon2D

func _ready():
	print("Sweep hitbox spawned!")
	
	_create_arc_polygon()
	
	body_entered.connect(_on_body_entered)
	
	get_tree().create_timer(lifetime).timeout.connect(_on_expire)

func _create_arc_polygon():
	var points: PackedVector2Array = PackedVector2Array()
	var segments = 12 
	var half_angle = deg_to_rad(arc_angle / 2.0)
	
	points.append(Vector2.ZERO)
	
	for i in range(segments + 1):
		var angle = -half_angle + (i * (half_angle * 2.0) / segments)
		var point = Vector2(cos(angle), sin(angle)) * arc_radius
		points.append(point)
	
	if collision_polygon:
		collision_polygon.polygon = points

func _on_body_entered(body):
	if has_hit:
		return
	
	if body == Global.Player:
		has_hit = true
		print("SWEEP HIT! Dealing ", damage, " damage")
		
		if Global.McHealth > 0:
			Global.take_damage(damage)
			# Knockback power relatif terhadap knockback_raw_pow dari mc.gd
			var kb_multiplier = knockback_power / Global.Player.knockback_raw_pow
			Global.McKnockBack(kb_multiplier, global_position)
		
		queue_free()

func _on_expire():
	print("Sweep hitbox expired")
	queue_free()
