extends Node2D

func _ready() -> void:
	Dialogic.signal_event.connect(handle)
	Dialogic.timeline_ended.connect(boss_fight)
	Dialogic.start("UtaraMain")
	
func boss_fight():
	Global.change_scene("res://StageTangan/bossPlayground.tscn")
	
func handle(signal_name: String):
	match signal_name:
		"is_2A":
			Dialogic.VAR.Timur.is_2A = true
		"is_2B":
			Dialogic.VAR.Timur.is_2B = true
		"is_patung":
			Dialogic.VAR.Timur.is_patung = true
		"is_lorong":
			Dialogic.VAR.Timur.is_lorong = true
		"is_tangga":
			Dialogic.VAR.Timur.is_tangga = true
		"2A":
			print("2A goted")
		"2B":
			print("2B goted")
			
