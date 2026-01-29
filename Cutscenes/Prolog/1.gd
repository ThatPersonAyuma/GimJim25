extends Node2D


func _ready() -> void:
	Dialogic.signal_event.connect(handle)
	Dialogic.timeline_ended.connect(ended)
	Dialogic.start("prolog1")
	
func ended(): # ke kebangkitan kutukan pertama
	Global.change_scene("res://Explorasi/Timur/TimurNode.tscn")
	
func handle(signal_name):
	match signal_name:
		"first":
			$AnimationPlayer.play("First")
		"1":
			$AnimationPlayer.play("1")
		"2":
			$AnimationPlayer.play("2")
		"3":
			$AnimationPlayer.play("3")
		"last":
			$AnimationPlayer.play("last")
	
