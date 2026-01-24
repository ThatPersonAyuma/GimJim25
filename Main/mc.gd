extends CharacterBody2D

@export var Speed: int = 100

func _ready() -> void:
	Global.Player = self

func _physics_process(delta):
	if Global.CanCharMove:
		var direction := Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)

		if direction != Vector2.ZERO:
			direction = direction.normalized()

		velocity = direction * Speed * 250 * delta
		move_and_slide()
