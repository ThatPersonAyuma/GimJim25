extends Node2D

func _ready() -> void:
	Dialogic.timeline_ended.connect(boss_fight)
	Dialogic.start("JantungAntaresEnd")
	
func boss_fight():
	Global.boss_scene_path = "res://StageFinal/StageFinal.tscn"
	Global.change_scene("res://Explorasi/BossDoor.tscn")
