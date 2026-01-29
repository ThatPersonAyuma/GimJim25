extends Node2D

var height = 360
var widht = 640

	
func play(duration):
	self.visible = true
	$AnimationPlayer.play("play")
	get_tree().create_timer(duration).timeout.connect(func():
		if not is_instance_valid(self):return
		$AnimationPlayer.stop()
		self.visible = false)
	
	
	
	
