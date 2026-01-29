extends Node2D

func _ready() -> void:
	Dialogic.signal_event.connect(handle)
	Dialogic.timeline_ended.connect(boss_fight)
	Dialogic.start("SelatanTL")
	
func boss_fight():
	Global.change_scene("res://StageJantung/HeartBossScene.tscn")
	
func handle(signal_name: String):
	match signal_name:
		"is_3A":
			Dialogic.VAR.Selatan.is_3A = true
			
		"is_3B":
			Dialogic.VAR.Selatan.is_3B = true
			
		"is_koridor":
			Dialogic.VAR.Selatan.is_koridor = true
			
		"is_inti_palsu":
			Dialogic.VAR.Selatan.is_inti_palsu = true
			
		"is_ruang_nadi":
			Dialogic.VAR.Selatan.is_ruang_nadi = true
		"3A":
			print("3A goted")
		"3B":
			print("3B goted")
			
