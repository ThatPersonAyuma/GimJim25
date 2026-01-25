extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var  NearbyAttackRange = $NA_range
@onready var NearbyAttackCollision = $NearbyAttack/CollisionShape2D
@onready var WaterBeam = $WaterBeam 
@onready var NearbyAttack = $NearbyAttack

@export var speed = 150.0

var direction = 0
# var ramdomizer = [-1, 1]
var player = null
var state = "idle"
var is_mc_in_range = false

func _ready() -> void:
	NearbyAttackRange.connect("body_entered", body_entered)
	NearbyAttackRange.connect("body_exited", body_exited)
	self.remove_child(WaterBeam)
	self.remove_child(NearbyAttack)
	
	OnIdle()

func _physics_process(delta):
	if state == "move":
		move_and_slide()
		
func OnIdle():
	state = "idle"
	velocity = Vector2.ZERO
	anim.animation = "idle"
	anim.play()
	await get_tree().create_timer(3.0).timeout
	
	print("ini seharusnya jalan abis 3 detik")
	OnMove()
	
func OnMove():
	state = "move"
	anim.animation = "walk"
	anim.play()
	velocity = Vector2.RIGHT * speed

func body_entered(body: Node2D):
	if body == Global.Player:
		self.is_mc_in_range = true
		print("Character In: ", body.name)

func body_exited(body):
	if body == Global.Player:
		print("Character Out: ", body.name)
