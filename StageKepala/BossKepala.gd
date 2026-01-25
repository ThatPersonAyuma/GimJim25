extends CharacterBody2D

@export var attack_interval = 4
@export var damage_dealt_na = 100
@export var health = 1000
@export var knockback_pwr: float = 0.4
@export var hurricane_duration = 10
@export var hurricane_push_pwr: float = 0.2

@onready var  na_range = $NA_range
@onready var na = $"Nearby Attack"
@onready var na_col = $"Nearby Attack/CollisionShape2D"

var current_health = self.health
var attack_cooldown = attack_interval
var is_mc_in_range = false
