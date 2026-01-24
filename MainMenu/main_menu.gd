extends Control

var music_on := true

@onready var options_popup = $OptionsPopUp
@onready var music_button = $OptionsPopUp/CenterContainer/VBoxContainer/VBoxContainer/MusicButton

func _on_options_button_pressed() -> void:
	options_popup.popup_centered()

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_close_button_pressed() -> void:
	options_popup.hide()

func _on_music_button_pressed() -> void:
	music_on = !music_on
	
	if music_on:
		music_button.text = "MUSIC : ON"
	else:
		music_button.text = "MUSIC : OFF"
