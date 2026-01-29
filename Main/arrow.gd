extends Node2D

var arrow_damage:int = 2000 #coba coba
var direction = Vector2.ZERO
var travel_velocity = 500
var is_travel = false
var max_distance: int = 500
var traveled_distance = 0
var self_index: int = 99

func _ready() -> void:
	$Area2D.connect("body_entered", handle_body)

func launch():
	self.global_position = Global.Player.global_position
	$Area2D.monitoring = true
	self.visible = true
	direction = (Global.Enemy.global_position - global_position).normalized()
	self.rotate(direction.angle())
	is_travel = true

func _process(delta):
	if is_travel: 
		var step  = direction * travel_velocity * delta
		global_position += step
		traveled_distance += step.length()
		
		if traveled_distance >= max_distance:
			reset_pos()
	
func handle_body(enemy):
	print("Enemy name: ", enemy.name)
	if enemy == Global.Enemy:
		if enemy.has_method("take_damage"):
			enemy.take_damage(arrow_damage)
		else:
			print("Alert! Give Enemey Take Damage Method")
	reset_pos()
	
func reset_pos():
	self.rotate(-direction.angle())
	Global.Player.travel_arrow_count -= 1
	traveled_distance = 0
	self.visible = false
	$Area2D.set_deferred("monitoring", false)
	is_travel = false
	Global.Player.available_arrows[self_index] = true
