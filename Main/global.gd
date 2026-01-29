extends Node

var McMaxHealth: int = 2000
var McHealth: int = McMaxHealth
var CanCharMove: bool = true
var Player: CharacterBody2D
var slow_mov: float = 1
var mov_push: Vector2 = Vector2(0,0)
var knocback_pow: float = 0   
var knockback_direction: Vector2 = Vector2(0,0)
var is_invincible: bool = false
var Enemy: CharacterBody2D
var is_death = false
signal mc_death
var death_scene = null
var boss_scene_path: String = ""
enum BossDebuff {
	Tangan = 0,
	Kepala = 1,
	Badan = 2,
	Jantung = 3,
	Whole = 4
}
var boss_debuff = BossDebuff.Tangan

enum PlayerBuff {
	None,

	GraveStepTalisman,    # 1A
	WandererAnklet,       # 1B

	WillbreakerKnot,      # 2A
	OathboundSigil,       # 2B

	PulseBorrowedLife,    # 3A
	SilentVeinCharm,      # 3B

	BlindseerRelic,       # 4A
	CrownlessThought     # 4B
}
var active_buff : PlayerBuff = PlayerBuff.None


func reset():
	McHealth = 100
	CanCharMove  = true
	slow_mov = 1
	mov_push = Vector2(0,0)
	knocback_pow = 0   
	knockback_direction = Vector2(0,0)
	is_invincible = false
	is_death = false
	apply_debuff()
	apply_buff()
	
func apply_debuff():
	if is_instance_valid(self.Player):
		if boss_debuff >= BossDebuff.Kepala:
			Player.Speed *= 0.85 
			Player.dash_power *= 0.85

		if boss_debuff >= BossDebuff.Jantung:
			Player.heavy_attack_cooldown *=1.4 
			Player.melee_cooldown *=1.25 
			Player.arrow_cooldown *=1.2 
			
		if boss_debuff >= BossDebuff.Badan:
			Player.arrow_cooldown *=1.2
			Player.cam_zoom *= 1.2
			Player.range_attack_radius *= 0.85

		if boss_debuff >= BossDebuff.Whole:
			McHealth *= 0.85
			Player.dash_cooldown *= 1.2

func apply_buff():
	if !is_instance_valid(Player):
		return

	match active_buff:

		PlayerBuff.GraveStepTalisman:
			Player.melee_cooldown *= 0.8
			Player.heavy_attack_cooldown *= 0.8
			Player.melee_attack_damage *= 1.1

		PlayerBuff.WandererAnklet:
			Player.Speed *= 1.1
			Player.dash_power *= 1.25

		PlayerBuff.WillbreakerKnot:
			Player.melee_attack_damage *= 1.2
			Player.melee_cooldown *= 0.9
			Player.heavy_attack_cooldown *= 0.9
			Player.arrow_cooldown *= 0.9

		PlayerBuff.OathboundSigil:
			McHealth *= 1.3
			Player.dash_cooldown *= 0.85

		PlayerBuff.PulseBorrowedLife:
			McHealth *= 1.6

		PlayerBuff.SilentVeinCharm:
			Player.arrow_cooldown *= 0.5

		PlayerBuff.BlindseerRelic:
			Player.dash_cooldown *= 0.7

		PlayerBuff.CrownlessThought:
			Player.melee_attack_damage *= 1.2
			Player.melee_cooldown *= 0.9
			Player.heavy_attack_cooldown *= 0.9
			Player.Speed *= 1.1

		PlayerBuff.None:
			pass
			
	self.active_buff = PlayerBuff.None


# debuff
#func apply_kaki():
	#pass
	#
#func apply_badan():
	#pass
	#
#func apply_kepala():
	#pass
	#
#func apply_jantung():
	#pass


func _ready() -> void:
	death_scene = preload("res://Main/death_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(death_scene)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
func _on_timeline_ended():
	print("Create timer in timeline ended")
	await get_tree().create_timer(0.5).timeout
	print("created")
	if not is_instance_valid(self):
		return
	CanCharMove = true

func change_scene(path: String):
	get_tree().change_scene_to_file.call_deferred(path)

func McDeath():
	if not is_death:
		is_death = true
		CanCharMove = false
		mc_death.emit()
		var cam = get_viewport().get_camera_2d()
		if cam!=null:
			print("is there any cam")
			death_scene.global_position = cam.get_screen_center_position()
			death_scene.scale = Vector2.ONE / Player.cam_zoom
			death_scene.visible = true
	
func char_stun(duration: float):
	self.CanCharMove = false
	await get_tree().create_timer(duration).timeout
	self.CanCharMove = true
	
func MovePush(amounts: Vector2):
	self.mov_push = amounts
	
func take_damage(amount: int, is_absolute:bool=false):
	if is_absolute:
		self.Player.is_dashing = false
	if not self.Player.is_dashing:
		self.McHealth -= amount
		if self.McHealth <= 0:
			self.McDeath()
		self.Player.play_hitted()
		
func McKnockBack(power: float, obj_glob_pstn:Vector2):
	knockback_direction = (Player.global_position - obj_glob_pstn).normalized()
	knocback_pow = power

func McDrag(power: float, obj_glob_pstn: Vector2):
	knockback_direction = (obj_glob_pstn - Player.global_position).normalized()
	knocback_pow = power
