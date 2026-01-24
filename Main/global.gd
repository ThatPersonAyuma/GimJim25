extends Node

var McHealth: int = 100
var CanCharMove :bool = true
var Player: CharacterBody2D
var TotalEnemy: int = 0
var slow_mov: float = 1
var mov_push: Vector2 = Vector2(0,0)
var knocback_pow: float = 0   
var knockback_direction: Vector2 = Vector2(0,0)

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
	self.McHealth -= amount
	if self.McHealth <= 0:
		self.McDeath()
func McKnockBack(power: float, direction:Vector2):
	self.knocback_pow = power
	self.knockback_direction = direction
