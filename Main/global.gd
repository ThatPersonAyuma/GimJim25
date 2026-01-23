extends Node

var McHealth: int = 100
var CanCharMove :bool = true
var Player: CharacterBody2D
var TotalEnemy: int = 0
   
func _ready() -> void:
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
func _on_timeline_ended():
	await get_tree().create_timer(0.5).timeout
	CanCharMove = true

func change_scene(path: String):
	get_tree().change_scene_to_file.call_deferred(path)
