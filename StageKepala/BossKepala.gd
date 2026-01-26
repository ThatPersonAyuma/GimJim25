extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var  NearbyAttackRange = $NA_range
@onready var NearbyAttackCollision = $NearbyAttack/CollisionShape2D
@onready var WaterBeam = $WaterBeam 
@onready var NearbyAttack = $NearbyAttack

@export var knockback_dmg: int = 10
@export var speed = 90.0
@export var max_health = 50

var player = null
var HP : int
var is_mc_in_range = false
var can_attack: bool = true
var state = "idle"

func _ready() -> void:
	HP = max_health
	
	NearbyAttackRange.connect("body_entered", body_entered)
	NearbyAttackRange.connect("body_exited", body_exited)
	self.remove_child(WaterBeam)
	self.remove_child(NearbyAttack)
	
	Global.Enemy = self
	OnIdle()

func _physics_process(_delta):
	if Global.McHealth <= 0:
		velocity = Vector2.ZERO
		return

	if state == "move":
		var target_pos = Global.Player.global_position
		velocity = global_position.direction_to(target_pos) * speed
		move_and_slide()

	elif state == "knockback":
		move_and_slide()

func OnIdle():
	state = "idle"
	velocity = Vector2.ZERO
	anim.animation = "idle"
	anim.play()
	
	await get_tree().create_timer(2.0).timeout
	print("ini seharusnya jalan abis 2 detik")
	OnMove()
	
func OnMove():
	state = "move"
	anim.animation = "walk"
	anim.play()
	
	#await get_tree().create_timer(0.2).timeout
	#print("ini seharusnya diam abis 1 detik")
	#OnIdle()

func OnKnockback(player):
	state = "knockback"
	Global.take_damage(knockback_dmg)

	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 100.0

	await get_tree().create_timer(0.8).timeout
	OnMove()

func OnKnockbackAtk(player):
	state = "knockback"
	take_damage(knockback_dmg)

	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 100.0

	await get_tree().create_timer(0.8).timeout
	OnMove()
	
func take_damage(amount: int):
	HP -= amount
	print("current HP: ", HP)
	modulate = Color.RED
	var timer = get_tree().create_timer(0.05)
	await timer.timeout
	modulate = Color.WHITE
	
	if HP <= 0:
		die()

func die():
	if Global.Enemy == self:
		Global.Enemy = null
	print("boss die")
	queue_free()

func body_entered(body: Node2D):
	if body == Global.Player:
		self.is_mc_in_range = true
		print("Knockback from: ", body.name)

		if body.is_attacking:
			OnKnockbackAtk(body)
		else:
			OnKnockback(body) 


func body_exited(body):
	if body == Global.Player:
		print("Character Out: ", body.name)
