extends Node2D

const SOUND_EFFECT = preload("res://Cutscenes/Ending/The Star That Fell Silent_OST(Ending).wav")

func _ready() -> void:
	Dialogic.signal_event.connect(handle)
	Dialogic.timeline_ended.connect(main)
	Dialogic.start("Ending")
	
func main():
	Global.change_scene("res://MainMenu/main_menu.tscn")
	
func handle(signal_name):
	match signal_name:
		"play_ed":
			$AudioStreamPlayer2D.stream = SOUND_EFFECT
			$AudioStreamPlayer2D.play()
