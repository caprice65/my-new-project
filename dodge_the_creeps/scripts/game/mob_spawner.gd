extends Node

## Spawns mobs along screen edges and scales difficulty with score.
## Uses fresh instances (no RigidBody2D object pool — reuse is unreliable).

@export var mob_scene: PackedScene
@export var base_spawn_interval := 0.5
@export var min_spawn_interval := 0.2
@export var base_speed_min := 150.0
@export var base_speed_max := 250.0
@export var speed_scale_per_score := 2.5
@export var spawn_inset := 24.0

var _speed_min := 150.0
var _speed_max := 250.0
var _playable_size := Vector2(480, 720)

@onready var _mob_timer: Timer = $MobTimer
@onready var _container: Node2D = $MobContainer


func _ready() -> void:
	_mob_timer.wait_time = base_spawn_interval
	_sync_playable_area()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func start() -> void:
	_mob_timer.start()


func stop() -> void:
	_mob_timer.stop()


func reset_difficulty() -> void:
	_speed_min = base_speed_min
	_speed_max = base_speed_max
	_mob_timer.wait_time = base_spawn_interval


func update_difficulty(score: int) -> void:
	_mob_timer.wait_time = maxf(
		min_spawn_interval,
		base_spawn_interval - score * 0.01
	)
	_speed_min = base_speed_min + score * speed_scale_per_score
	_speed_max = base_speed_max + score * speed_scale_per_score * 1.2


func recycle_all() -> void:
	for child in _container.get_children():
		child.queue_free()


func _on_MobTimer_timeout() -> void:
	if mob_scene == null:
		return
	if GameState.instance == null:
		return
	if GameState.instance.state != GameState.State.PLAYING:
		return

	var spawn := _pick_edge_spawn()
	var speed := randf_range(_speed_min, _speed_max)
	var velocity := Vector2.RIGHT.rotated(spawn.direction) * speed

	var mob := mob_scene.instantiate() as RigidBody2D
	_container.add_child(mob)
	mob.setup(spawn.position, spawn.direction, velocity, _playable_size)


func _pick_edge_spawn() -> Dictionary:
	var size := _playable_size
	var side := randi() % 4
	var pos := Vector2.ZERO
	var direction := 0.0

	match side:
		0: # Top → down
			pos = Vector2(randf() * size.x, 0.0)
			direction = PI * 0.5
		1: # Right → left
			pos = Vector2(size.x, randf() * size.y)
			direction = PI
		2: # Bottom → up
			pos = Vector2(randf() * size.x, size.y)
			direction = -PI * 0.5
		_: # Left → right
			pos = Vector2(0.0, randf() * size.y)
			direction = 0.0

	direction += randf_range(-PI / 4.0, PI / 4.0)
	pos += Vector2.RIGHT.rotated(direction) * spawn_inset
	pos = pos.clamp(Vector2.ZERO, size)
	return { "position": pos, "direction": direction }


func _on_viewport_size_changed() -> void:
	_sync_playable_area()


func _sync_playable_area() -> void:
	var settings_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	)
	if settings_size.x > 0.0 and settings_size.y > 0.0:
		_playable_size = settings_size
	else:
		var viewport_size := get_viewport().get_visible_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			_playable_size = viewport_size
	_container.position = Vector2.ZERO
