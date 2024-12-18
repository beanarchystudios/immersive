## Provides options for blasters.
class_name Blaster extends Resource

## The model for the blaster to use.
@export var model: PackedScene = preload("res://Assets/Models/Blasters/Kenney/blasterA.glb")
## The base offset for the model to be at.
@export var base_offset := Vector3(0.2, -0.2, -0.4)
## The offset for the model while ADS is enabled.
@export var ads_offset := Vector3(0.0, -0.2, -0.4)

## If true, this blaster can be shot. Otherwise, it cannot shoot. Useful for things such as flags.
@export var can_shoot := true

## If true, this blaster can enter aiming down sights. Otherwise, it cannot enter ADS.
@export var can_ads := true

## The time between shots for the blaster.
@export var fire_rate := 0.075
## The amount of recoil when the blaster is shot.
@export var recoil := 0.015
## The amount of damage done to the other player when they are shot.
@export var damage := 20.0

func _init(p_model: PackedScene = preload("res://Assets/Models/Blasters/Kenney/blasterA.glb"), p_base_offset := Vector3(0.2, -0.2, -0.4), p_ads_offset := Vector3(0.0, -0.2, -0.4), p_fire_rate := 0.075, p_recoil := 0.015, p_damage := 20.0) -> void:
	model = p_model
	base_offset = p_base_offset
	ads_offset = p_ads_offset
	fire_rate = p_fire_rate
	recoil = p_recoil
	damage = p_damage
