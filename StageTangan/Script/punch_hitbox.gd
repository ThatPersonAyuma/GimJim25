class_name BossPunchHitbox extends Area2D

@export var damage: int = 25
@export var knockback_power: float = 400.0
@export var punch_duration: float = 0.25
@export var punch_distance: float = 120.0
@export var hold_time: float = 0.2
@export var return_duration: float = 0.2

var has_hit_right: bool = false
var has_hit_left: bool = false
var boss_ref: Node2D = null
var phase: int = 0

@onready var right_hand: Sprite2D = $Kanan
@onready var left_hand: Sprite2D = $Kiri
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
    print("Punch hitbox spawned!")
    
    body_entered.connect(_on_body_entered)
    
    if right_hand:
        right_hand.visible = false
        right_hand.modulate.a = 0
    if left_hand:
        left_hand.visible = false
        left_hand.modulate.a = 0
    if collision:
        collision.disabled = true
    
    _execute_alternating_punch()

func _execute_alternating_punch():
    if not is_instance_valid(Global.Player):
        queue_free()
        return
    
    var start_pos = global_position
    var dir = Vector2.RIGHT.rotated(rotation)
    var target_pos = start_pos + (dir * punch_distance)
    var return_pos = boss_ref.global_position if is_instance_valid(boss_ref) else start_pos
    
    print("Punch: Right hand appearing...")
    if right_hand:
        right_hand.visible = true
        var appear_tween = create_tween().set_parallel(true)
        appear_tween.tween_property(right_hand, "modulate:a", 1.0, 0.15)
        appear_tween.tween_property(right_hand, "scale", Vector2.ONE, 0.15).from(Vector2.ZERO).set_trans(Tween.TRANS_BACK)
        await appear_tween.finished
    
    await get_tree().create_timer(hold_time).timeout
    
    print("Punch: Right hand attacking!")
    if collision:
        collision.disabled = false
    
    var punch_right = create_tween()
    punch_right.tween_property(self, "global_position", target_pos, punch_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    await punch_right.finished
    
    print("Punch: Right hand returning...")
    if collision:
        collision.disabled = true
    has_hit_right = false
    
    var return_right = create_tween()
    return_right.tween_property(self, "global_position", return_pos, return_duration).set_ease(Tween.EASE_IN)
    await return_right.finished
    
    if right_hand:
        right_hand.visible = false
    
    start_pos = global_position
    
    if is_instance_valid(Global.Player):
        var new_dir = global_position.direction_to(Global.Player.global_position)
        rotation = new_dir.angle()
        dir = Vector2.RIGHT.rotated(rotation)
        target_pos = start_pos + (dir * punch_distance)
    
    print("Punch: Left hand appearing...")
    if left_hand:
        left_hand.visible = true
        var appear_left = create_tween().set_parallel(true)
        appear_left.tween_property(left_hand, "modulate:a", 1.0, 0.15)
        appear_left.tween_property(left_hand, "scale", Vector2.ONE, 0.15).from(Vector2.ZERO).set_trans(Tween.TRANS_BACK)
        await appear_left.finished
    
    await get_tree().create_timer(hold_time).timeout
    
    print("Punch: Left hand attacking!")
    if collision:
        collision.disabled = false
    
    var punch_left = create_tween()
    punch_left.tween_property(self, "global_position", target_pos, punch_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    await punch_left.finished
    
    print("Punch: Left hand returning...")
    if collision:
        collision.disabled = true
    
    var final_return_pos = boss_ref.global_position if is_instance_valid(boss_ref) else start_pos
    var return_left = create_tween().set_parallel(true)
    return_left.tween_property(self, "global_position", final_return_pos, return_duration).set_ease(Tween.EASE_IN)
    return_left.tween_property(self, "modulate:a", 0.0, return_duration)
    await return_left.finished
    
    print("Punch: Complete!")
    queue_free()

func _on_body_entered(body):
    if body == Global.Player:
        print("PUNCH HIT! Dealing ", damage, " damage")
        
        if Global.McHealth > 0:
            Global.take_damage(damage)
            
            var knockback_raw = Global.Player.knockback_raw_pow if Global.Player.knockback_raw_pow != 0 else 1.0
            var kb_multiplier = knockback_power / knockback_raw
            Global.McKnockBack(kb_multiplier, global_position)
