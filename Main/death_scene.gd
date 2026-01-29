extends Node2D

func _ready() -> void:
	Global.mc_death.connect(play)
func play():
	self.visible = true
	$AnimationPlayer.play("death")


func _on_button_2_button_down() -> void:
	self.visible = false
	Global.change_scene("res://MainMenu/main_menu.tscn")
