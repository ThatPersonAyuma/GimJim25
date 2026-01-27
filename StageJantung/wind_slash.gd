extends Node2D

var damage = 0

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slash_attack":
		Global.Enemy.is_slash_available = true
		$AnimationPlayer.play("RESET")
	
func launch():
	self.global_position = Vector2(-20,-10)+Global.Player.global_position
	$ColorRect.visible = true 
	print("pos danger: ", $ColorRect.global_position)
	Global.Enemy.is_slash_available = false
	await get_tree().create_timer(1).timeout
	if not is_instance_valid(self):return
	$ColorRect.visible = false 
	$AnimationPlayer.play("slash_attack")
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		Global.take_damage(damage)
	
