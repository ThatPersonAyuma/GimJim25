extends Node2D

var is_walking = false
var direction = Vector2.ZERO
var just_walk = false
var time = 0

func _ready() -> void:
	Global.Player.anim_sprite.play("idle" if not Global.Player.is_corrupted else "idle_corrupted")
	$Area2D.connect("body_entered", handle_exploration)
	$Area2D2.connect("body_entered", handle_fight)
	Global.CanCharMove = false
	Dialogic.signal_event.connect(handle_signal)
	Dialogic.start("Explorasi/Coba")
	
func handle_exploration(body):
	play_fade()
	await get_tree().create_timer(1).timeout
	Global.CanCharMove = true
	Global.change_scene("res://Explorasi/ExploreDoor.tscn")
	
func handle_fight(body):
	play_fade()
	await get_tree().create_timer(1).timeout
	Global.CanCharMove = true
	Global.change_scene("res://Explorasi/BossDoor.tscn")
	
func play_fade():
	is_walking = false
	print("fade checkpoint")
	Global.Player.velocity = Vector2.ZERO
	Global.Player.anim_sprite.play("idle" if not Global.Player.is_corrupted else "idle_corrupted")
	$AnimationPlayer.play("fadeout")
func handle_signal(signal_name: String):
	match signal_name:
		"fight":
			play_fight()
		"explore":
			play_explore()
			
	print("signal name: ", signal_name)
	
func _process(delta: float) -> void:
	if is_walking:
		if Global.CanCharMove:
			Global.CanCharMove = false
		Global.Player.anim_sprite.play("walk" if not Global.Player.is_corrupted else "walk_corrupted")
		Global.Player.velocity = direction * Global.Player.Speed / 2
		
		
func play_explore():
	get_direction($Area2D/CollisionShape2D.global_position)
	
func play_fight():
	get_direction($Area2D2/CollisionShape2D.global_position)
	
func get_direction(target_pos):
	await get_tree().create_timer(0.5).timeout
	is_walking = true
	self.direction = (target_pos - Global.Player.global_position).normalized()
