extends Node2D

func _ready() -> void:
	print("Death")
	$AnimationPlayer.play("death")


func _on_button_2_button_down() -> void:
	Global.change_scene("res://MainMenu/main_menu.tscn")
