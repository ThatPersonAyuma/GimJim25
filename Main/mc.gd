extends CharacterBody2D

@export var Speed: int = 200
@export var knockback_raw_pow = 500
@onready var hit_anim = $HitAnimation
@onready var anim = $AnimatedSprite2D



func _ready() -> void:
	Global.Player = self

func _physics_process(delta):
	if Global.CanCharMove:
		var direction := Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		if direction.x != 0:
			anim.flip_h = true if direction.x == -1 else false

		if direction != Vector2.ZERO:
			direction = direction.normalized()
			anim.play("walk")
		else:
			anim.play("idle")
			
		
		velocity = direction * Speed * Global.slow_mov + Global.mov_push * Speed
	if Global.knocback_pow > 0:
		Global.CanCharMove = false
		velocity = Global.knockback_direction * knockback_raw_pow * Global.knocback_pow
		Global.knocback_pow = 0
		await get_tree().create_timer(0.5).timeout
		Global.CanCharMove = true
	move_and_slide()

func play_hitted():
	hit_anim.play("hit")
