class_name BossFirewallShield extends Node2D

@onready var sfx = $SFX

@export var burn_damage_percent: float = 0.10  
@export var burn_interval: float = 0.5
@export var duration: float = 6.0
@export var spawn_delay: float = 0.1
@export var base_scale: float = 3.0  

var boss_ref: Node2D = null
var damage_timer: float = 0.0
var players_inside: int = 0
var boss_scale: float = 1.0 

func _ready():
	print("Firewall spawn")
	sfx.play()
	
	scale = Vector2.ONE * base_scale * boss_scale
	
	_hide_all_units()
	
	_connect_fire_units()
	
	_animate_spawn_sequence()
	
	get_tree().create_timer(duration).timeout.connect(_on_expire)

func _hide_all_units():
	for child in get_children():
		if child is Node2D and child.name != "FirewallArea":
			child.visible = false
			child.scale = Vector2.ZERO 

func _animate_spawn_sequence():
	for child in get_children():
		if child is Node2D and child.name != "FirewallArea":
			child.visible = true
			
			var tween = create_tween()
			tween.tween_property(child, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
			_play_animated_sprites(child)
			
			await get_tree().create_timer(spawn_delay).timeout

func _play_animated_sprites(node: Node):
	for sub in node.get_children():
		if sub is AnimatedSprite2D:
			sub.play("fireballUnit")
		elif sub.get_child_count() > 0:
			_play_animated_sprites(sub)

func _connect_fire_units():
	for child in get_children():
		if not child is Node2D:
			continue
		
		for subchild in child.get_children():
			if subchild is Area2D:
				subchild.body_entered.connect(_on_fire_body_entered)
				subchild.body_exited.connect(_on_fire_body_exited)
				break
	
	var firewall_area = get_node_or_null("FirewallArea")
	if firewall_area and firewall_area is Area2D:
		firewall_area.body_entered.connect(_on_fire_body_entered)
		firewall_area.body_exited.connect(_on_fire_body_exited)

func _physics_process(delta):
	if is_instance_valid(boss_ref):
		global_position = boss_ref.global_position
	
	if players_inside > 0:
		damage_timer += delta
		if damage_timer >= burn_interval:
			damage_timer = 0.0
			_deal_damage_to_player()

func _on_fire_body_entered(body):
	if body == Global.Player:
		players_inside += 1
		if players_inside == 1: 
			print("Player MENYENTUH Firewall Shield!")
			_deal_damage_to_player()

func _on_fire_body_exited(body):
	if body == Global.Player:
		players_inside -= 1
		players_inside = max(0, players_inside)
		if players_inside == 0:
			print("Player MENJAUH dari Firewall Shield!")

func _deal_damage_to_player():
	if Global.McHealth > 0 and is_instance_valid(Global.Player):
		var max_hp: int = Global.McMaxHealth
		var damage = int(max_hp * burn_damage_percent)
		damage = max(damage, 5)
		
		Global.take_damage(damage)
		
		var knockback_power = 200.0
		Global.McKnockBack(knockback_power / Global.Player.knockback_raw_pow, global_position)
		
		print("Firewall BURN! Damage: ", damage)

func _on_expire():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	print("Firewall Shield expired!")
	queue_free()
