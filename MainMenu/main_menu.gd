extends Control

var music_on := true

@onready var options_popup = $OptionsPopUp

func _on_options_button_pressed() -> void:
	options_popup.popup_centered()

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_close_button_pressed() -> void:
	options_popup.hide()


func _on_new_game_button_pressed() -> void:
	"""
	PLay the game from the start
	"""
	Global.change_scene("res://Cutscenes/Prolog/1.tscn")
	
