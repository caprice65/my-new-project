extends RigidBody2D

signal recycled(mob: RigidBody2D)

var _pooled := false


func _ready() -> void:
	# Mobs live on layer 1 so the player's HitArea (mask 1) can detect them.
	collision_layer = 1
	collision_mask = 0
	gravity_scale = 0.0
	add_to_group(&"mobs")


func activate_from_pool() -> void:
	_pooled = false
	freeze = false
	sleeping = false
	visible = true
	collision_layer = 1
	var mob_types := Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	$AnimatedSprite2D.play()


func deactivate_to_pool() -> void:
	_pooled = true
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	visible = false
	collision_layer = 0
	$AnimatedSprite2D.stop()
	global_position = Vector2(-2048, -2048)


func _on_VisibilityNotifier2D_screen_exited() -> void:
	if _pooled:
		return
	recycled.emit(self)
