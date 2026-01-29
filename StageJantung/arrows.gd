extends Node2D

var directions = [Vector2(0, -1), Vector2(-0.5, -0.5), Vector2(-1, 0), Vector2(-0.5, 0.5), Vector2(0, 1), Vector2(0.5, 0.5), Vector2(1, 0), Vector2(0.5, -0.5)]
var rotations = [90,45,0,-45,-90,-135,180,135]
var arrows = []

func _ready() -> void:
	var arrow = preload("res://StageJantung/WindArrow.tscn")
	var root = get_tree().root
	
	for i in range(8):
		var temp_arrow = arrow.instantiate()
		temp_arrow.direction = directions[i]
		temp_arrow.position += directions[i]*28 
		temp_arrow.rotate(deg_to_rad(rotations[i]))
		root.add_child.call_deferred(temp_arrow)
		arrows.push_back(temp_arrow)
	
func free_arrows():
	for arrow in arrows:
		if is_instance_valid(arrow) : arrow.queue_free()
	
func launch():
	for arrow in arrows:
		arrow.launch() 
