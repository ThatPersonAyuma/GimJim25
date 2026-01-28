extends Node

var McMaxHealth: int = 2000
var McHealth: int = McMaxHealth
var CanCharMove: bool = true
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
	await get_tree().create_timer(0.5).timeout
	CanCharMove = true

func change_scene(path: String):
	get_tree().change_scene_to_file.call_deferred(path)

func McDeath():
	print("Death")
	pass
	#var node = load("res://Main/Camera.tscn")
	#get_tree().current_scene.add_child(node)
func char_stun(duration: float):
	self.CanCharMove = false
	await get_tree().create_timer(duration).timeout
	self.CanCharMove = true
	
func MovePush(amounts: Vector2):
	self.mov_push = amounts
	
func take_damage(amount: int):
	if not self.Player.is_dashing:
		self.McHealth -= amount
		if self.McHealth <= 0:
			self.McDeath()
		self.Player.play_hitted()
		
func McKnockBack(power: float, obj_glob_pstn:Vector2):
	var direction = self.Player.global_position - obj_glob_pstn
	self.knockback_direction = Vector2(1 if direction.x >= 0 else -1, 1 if direction.y >= 0 else -1)
	self.knocback_pow = power
