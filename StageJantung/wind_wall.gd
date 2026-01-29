extends Node2D

var self_index = 99

func _ready() -> void:
	$AreaBody2D.connect("body_entered", push_back)

func launch(target_glob_pos: Vector2, duration: float, is_horizontal: bool):
	$AnimationPlayer.play("danger_horizontal" if is_horizontal else "danger_vertical")
	self.global_position = target_glob_pos
	await get_tree().create_timer(1).timeout
	if not is_instance_valid(self):return
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", false)
	$AreaBody2D.monitoring = true
	$AnimationPlayer.play("horizontal_wall" if is_horizontal else "vertical_wall")
	get_tree().create_timer(duration).timeout.connect(func():
		if not is_instance_valid(self):return
		Global.Enemy.wind_walls_available[self_index] = true
		$AreaBody2D.monitoring = false
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", true))
	

	
func push_back(body):
	if body == Global.Player:
		Global.take_damage(Global.Enemy.wind_wall_damage)
		Global.McKnockBack(Global.Enemy.knockback_pwr, self.global_position)
