class_name BossShockwave extends Node2D

@export var expand_speed: float = 2.0     
@export var max_scale: float = 5.0        
@export var burn_damage: int = 5        
@export var burn_interval: float = 0.5     
@export var duration: float = 3.0          

var current_scale: float = 0.5
var is_expanding: bool = true
var players_inside: Array = []

@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $ShockwaveHitbox
@onready var damage_timer = $DamageTimer

func _ready():
	print("Shockwave spawned BOSSSH!")
	
	scale = Vector2(current_scale, current_scale)
	
	animated_sprite.play("expand")
	
	damage_timer.wait_time = burn_interval
	damage_timer.timeout.connect(_on_damage_tick)
	damage_timer.start()
	
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.body_exited.connect(_on_body_exited)
	
	get_tree().create_timer(duration).timeout.connect(_on_expire)

func _physics_process(delta):
	if is_expanding and current_scale < max_scale:
		current_scale += expand_speed * delta
		current_scale = min(current_scale, max_scale)
		scale = Vector2(current_scale, current_scale)
	elif current_scale >= max_scale:
		is_expanding = false

func _on_body_entered(body):
	if body == Global.Player:
		print("Player MASUK area shockwave!")
		if body not in players_inside:
			players_inside.append(body)
			_deal_damage_to_player()

func _on_body_exited(body):
	if body == Global.Player:
		print("Player KELUAR area shockwave!")
		if body in players_inside:
			players_inside.erase(body)

func _on_damage_tick():
	if players_inside.size() > 0:
		_deal_damage_to_player()

func _deal_damage_to_player():
	if Global.McHealth > 0:
		Global.take_damage(burn_damage)
		print("Shockwave BURN! Player HP: ", Global.McHealth)

func _on_expire():
	print("Shockwave expired!")
	queue_free()
