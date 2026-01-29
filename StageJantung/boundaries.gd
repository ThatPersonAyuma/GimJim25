extends Area2D

@export var drag_power: float = 0.6
@export var damage_dealt = 10

@onready var wind_sfx = $"../AudioStreamPlayer2D"

func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		if not wind_sfx.playing:
			wind_sfx.play()

func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player:
		Global.McDrag(drag_power, $"..".global_position)
		Global.take_damage(self.damage_dealt, true)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	Global.take_damage(99999999, true) #instan death
