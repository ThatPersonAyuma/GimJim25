extends Node2D

@export var speed: float = 0.05
@export var damage: int = 10
@export var drag_power = 0.4
var is_running = false
var self_index = 99

func _ready() -> void:
	$Path2D/PathFollow2D/Area2D.connect("body_entered", body_entered)
	$Path2D/PathFollow2D/Area2D.set_deferred("monitoring", false)

func _process(delta: float) -> void:
	if is_running:
		$Path2D/PathFollow2D.progress_ratio += delta * speed
		if $Path2D/PathFollow2D.progress_ratio >= 1.0:
			$Path2D/PathFollow2D.progress_ratio = 0.0

func launch(duration):
	$Path2D/PathFollow2D/Area2D.set_deferred("monitoring", true)
	$ColorRect.set_deferred('visible', true)
	self.global_position = Global.Player.global_position
	await get_tree().create_timer(1).timeout
	if not is_instance_valid(self):return
	$ColorRect.set_deferred('visible', false)
	Global.Enemy.whirlwind_available[self_index] = false
	self.is_running = true
	$Path2D.visible = true
	get_tree().create_timer(duration).timeout.connect(func():
		if not is_instance_valid(self):return
		self.is_running = false
		$Path2D.visible = false
		Global.Enemy.whirlwind_available[self_index] = true
		$Path2D/PathFollow2D/Area2D.set_deferred("monitoring", false))

func body_entered(body):
	if body == Global.Player:
		Global.McDrag(drag_power, $Path2D/PathFollow2D/AnimatedSprite2D.global_position)
		Global.take_damage(damage)
