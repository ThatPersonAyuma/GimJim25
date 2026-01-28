class_name BossPunchHitbox extends Area2D

@export var damage: int = 25
@export var knockback_power: float = 400.0
@export var lifetime: float = 0.3  

var has_hit: bool = false  

func _ready():
    print("Punch hitbox spawned huhu!")
    
    body_entered.connect(_on_body_entered)
    
    get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_body_entered(body):
    if has_hit:
        return
    
    if body == Global.Player:
        has_hit = true
        print("PUNCH HIT! Dealing ", damage, " damage")
        
        if Global.McHealth > 0:
            Global.take_damage(damage)
            
            # Knockback power relatif terhadap knockback_raw_pow dari mc.gd
            var kb_multiplier = knockback_power / Global.Player.knockback_raw_pow
            Global.McKnockBack(kb_multiplier, global_position)
        
        queue_free()

func _on_expire():
    print("Punch hitbox expired")
    queue_free()