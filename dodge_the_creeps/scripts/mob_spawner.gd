extends Node

## Spawns mobs from an object pool and scales difficulty with score.

@export var mob_scene: PackedScene
@export var pool_size := 24
@export var base_spawn_interval := 0.5
@export var min_spawn_interval := 0.2
@export var base_speed_min := 150.0
@export var base_speed_max := 250.0
@export var speed_scale_per_score := 2.5

var _speed_min := 150.0
var _speed_max := 250.0
var _pool: Array[RigidBody2D] = []
var _active: Array[RigidBody2D] = []

@onready var _mob_timer: Timer = $MobTimer
@onready var _spawn_location: PathFollow2D = $MobPath/MobSpawnLocation
@onready var _mob_path: Path2D = $MobPath
@onready var _container: Node = $MobContainer


func _ready() -> void:
	_mob_timer.wait_time = base_spawn_interval
	_rebuild_path(get_viewport().get_visible_rect().size)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_prewarm_pool()


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
	for mob in _active.duplicate():
		_recycle(mob)


func _prewarm_pool() -> void:
	if mob_scene == null:
		return
	for _i in pool_size:
		var mob := _create_mob()
		mob.deactivate_to_pool()
		_pool.append(mob)


func _create_mob() -> RigidBody2D:
	var mob := mob_scene.instantiate() as RigidBody2D
	_container.add_child(mob)
	mob.recycled.connect(_on_mob_recycled)
	return mob


func _acquire() -> RigidBody2D:
	var mob: RigidBody2D
	if _pool.is_empty():
		mob = _create_mob()
	else:
		mob = _pool.pop_back()
	_active.append(mob)
	return mob


func _recycle(mob: RigidBody2D) -> void:
	if mob == null:
		return
	_active.erase(mob)
	if mob.get_parent() != _container:
		_container.add_child(mob)
	mob.deactivate_to_pool()
	if not _pool.has(mob):
		_pool.append(mob)


func _on_mob_recycled(mob: RigidBody2D) -> void:
	_recycle(mob)


func _on_MobTimer_timeout() -> void:
	if mob_scene == null:
		return
	if GameState.instance.state != GameState.State.PLAYING:
		return

	var mob := _acquire()
	_spawn_location.progress_ratio = randf()

	var direction := _spawn_location.rotation + PI / 2.0
	direction += randf_range(-PI / 4.0, PI / 4.0)

	mob.global_position = _spawn_location.global_position
	mob.rotation = direction
	mob.activate_from_pool()

	var velocity := Vector2(randf_range(_speed_min, _speed_max), 0.0)
	mob.linear_velocity = velocity.rotated(direction)


func _on_viewport_size_changed() -> void:
	_rebuild_path(get_viewport().get_visible_rect().size)


func _rebuild_path(size: Vector2) -> void:
	var curve := Curve2D.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(size.x, 0))
	curve.add_point(Vector2(size.x, size.y))
	curve.add_point(Vector2(0, size.y))
	curve.add_point(Vector2(0, 0))
	_mob_path.curve = curve
