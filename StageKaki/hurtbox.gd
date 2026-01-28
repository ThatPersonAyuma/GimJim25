extends Area2D

var can_take_hit := true
@export var hit_interval := 0.25

var player_inside := false

func _ready():
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	if body == Global.Player:
		player_inside = true

func _on_body_exited(body):
	if body == Global.Player:
		player_inside = false

func _process(_delta):
	if not player_inside or not can_take_hit:
		return

	var player = Global.Player
	if player.is_attacking:
		can_take_hit = false
		get_parent().take_damage(player.melee_attack_damage)
		await get_tree().create_timer(hit_interval).timeout
		can_take_hit = true
