extends Node

var McHealth: int = 100
var CanCharMove :bool = true
var Player: CharacterBody2D
var TotalEnemy: int = 0
var slow_mov: float = 1
var mov_push: Vector2 = Vector2(0,0)
var knocback_pow: float = 0   
var knockback_direction: Vector2 = Vector2(0,0)
var is_invincible: bool = false
var Enemy: CharacterBody2D


func _ready() -> void:
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
func _on_timeline_ended():
	print("Create timer in timeline ended")
	await get_tree().create_timer(0.5).timeout
	print("created")
	if not is_instance_valid(self):
		return
	CanCharMove = true

func change_scene(path: String):
	get_tree().change_scene_to_file.call_deferred(path)

func McDeath():
	var node = preload("res://Main/death_scene.tscn").instantiate()
	self.Player.add_child(node)
	
func char_stun(duration: float):
	self.CanCharMove = false
	await get_tree().create_timer(duration).timeout
	self.CanCharMove = true
	
func MovePush(amounts: Vector2):
	self.mov_push = amounts
	
func take_damage(amount: int, is_absolute:bool=false):
	if is_absolute:
		self.Player.is_dashing = false
	if not self.Player.is_dashing:
		self.McHealth -= amount
		if self.McHealth <= 0:
			self.McDeath()
		self.Player.play_hitted()
		
func McKnockBack(power: float, obj_glob_pstn:Vector2):
	knockback_direction = (Player.global_position - obj_glob_pstn).normalized()
	knocback_pow = power

func McDrag(power: float, obj_glob_pstn: Vector2):
	knockback_direction = (obj_glob_pstn - Player.global_position).normalized()
	print("direction: ", knockback_direction)
	knocback_pow = power
