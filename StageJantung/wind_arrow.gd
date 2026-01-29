extends Node2D

@export var diameter = 30

var is_travel = false
var max_distance = 1000
var traveled_distance = 0
var direction = Vector2.ZERO
var origin_distance = Vector2.ZERO
var parent_glob_pos = Vector2(0, -20)

func _ready() -> void:
	$Area2D.connect("body_entered", handle_body)
	call_deferred("setup")
func setup():
	self.origin_distance = diameter*direction
	
func _process(delta):
	if Global.Enemy == null:
		return
	if is_travel: 
		var step  = direction * Global.Enemy.arrow_speed * delta
		global_position += step
		traveled_distance += step.length()
		
		if traveled_distance >= max_distance:
			reset()
			
func handle_body(body):
	if body == Global.Player:
		Global.take_damage(Global.Enemy.arrow_damage)
	reset()
	
func reset():
	visible = false
	is_travel = false
	traveled_distance = 0
	$Area2D.set_deferred("monitoring", false)
	
func launch():
	reset_pos()
	visible = true
	is_travel = true
	$Area2D.set_deferred("monitoring", true)
	
func reset_pos():
	self.global_position =  Global.Enemy.global_position + self.origin_distance
