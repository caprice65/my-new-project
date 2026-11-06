extends RigidBody2D

## One-shot enemy. Spawner creates it; this script frees it when far off-screen.

const BOUNDS_MARGIN := 128.0

var _playable_size := Vector2(480, 720)
var _armed := false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	gravity_scale = 0.0
	lock_rotation = true
	add_to_group(&"mobs")

	var notifier := get_node_or_null("VisibleOnScreenNotifier2D")
	if notifier:
		notifier.process_mode = Node.PROCESS_MODE_DISABLED

	var mob_types := Array(_sprite.sprite_frames.get_animation_names())
	_sprite.animation = mob_types.pick_random()
	_sprite.play()

	# Avoid freeing on the spawn frame.
	set_deferred("_armed", true)


func configure_playable_size(size: Vector2) -> void:
	if size.x > 0.0 and size.y > 0.0:
		_playable_size = size


func setup(spawn_pos: Vector2, spawn_rotation: float, spawn_velocity: Vector2, playable_size: Vector2) -> void:
	configure_playable_size(playable_size)
	position = spawn_pos
	rotation = spawn_rotation
	linear_velocity = spawn_velocity
	reset_physics_interpolation()


func _physics_process(_delta: float) -> void:
	if not _armed:
		return
	var min_v := -BOUNDS_MARGIN
	var max_v := _playable_size + Vector2(BOUNDS_MARGIN, BOUNDS_MARGIN)
	if (
		position.x < min_v
		or position.y < min_v
		or position.x > max_v.x
		or position.y > max_v.y
	):
		queue_free()


# Legacy scene connections (safe no-ops if still wired).
func _on_screen_entered() -> void:
	pass


func _on_VisibilityNotifier2D_screen_exited() -> void:
	pass
