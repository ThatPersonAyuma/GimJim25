extends Node2D

func _ready() -> void:
	Dialogic.signal_event.connect(handle)
	Dialogic.timeline_ended.connect(boss_fight)
	Dialogic.start("TanganTimurAntaresEnd")
	
func boss_fight():
	Global.boss_scene_path = "res://StageKepala/StageKepala.tscn"
	Global.change_scene("res://Explorasi/BossDoor.tscn")
	
	
func handle(signal_name: String):
	match signal_name:
		"is_4A":
			Dialogic.VAR.Barat.is_4A = true
		"is_4B":
			Dialogic.VAR.Barat.is_4B = true
		"is_ruang_putih":
			Dialogic.VAR.Barat.is_ruang_putih = true
		"is_teks_diudara":
			Dialogic.VAR.Barat.is_teks_diudara = true
		"is_suara_diri":
			Dialogic.VAR.Barat.is_suara_diri = true
		"4A":
			Global.active_buff = Global.PlayerBuff.BlindseerRelic
		"4B":
			Global.active_buff = Global.PlayerBuff.CrownlessThought
