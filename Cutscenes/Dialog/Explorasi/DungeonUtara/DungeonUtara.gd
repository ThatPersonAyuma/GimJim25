extends Node2D

func _ready() -> void:
	Dialogic.signal_event.connect(handle)
	Dialogic.timeline_ended.connect(boss_fight)
	Dialogic.start("KepalaAntaresEnd")
	
func boss_fight():
	Global.boss_scene_path = "res://StageKaki/stage_kaki.tscn"
	Global.change_scene("res://Explorasi/BossDoor.tscn")
	
func handle(signal_name: String):
	match signal_name:
		"is_1A":
			Dialogic.VAR.Utara.is_1A = true
			
		"is_1B":
			Dialogic.VAR.Utara.is_1B = true
			
		"is_jejak":
			Dialogic.VAR.Utara.is_jejak = true
			
		"is_lorong":
			Dialogic.VAR.Utara.is_lorong = true
			
		"is_sunyi":
			Dialogic.VAR.Utara.is_sunyi = true
		"1A":
			Global.active_buff = Global.PlayerBuff.GraveStepTalisman
		"1B":
			Global.active_buff = Global.PlayerBuff.WandererAnklet
			
