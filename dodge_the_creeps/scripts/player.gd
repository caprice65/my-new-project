extends CharacterBody2D

signal hit

@export var speed := 400.0

var screen_size := Vector2.ZERO
var _alive := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_area: Area2D = $HitArea
@onready var hit_shape: CollisionShape2D = $HitArea/CollisionShape2D
@onready var trail: GPUParticles2D = $Trail


func _ready() -> void:
	_refresh_screen_size()
	get_viewport().size_changed.connect(_refresh_screen_size)
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hide()
	# Body does not physically collide with mobs; HitArea detects them.
	collision_layer = 0
	collision_mask = 0
	hit_area.collision_layer = 0
	hit_area.collision_mask = 1
	hit_area.monitoring = true
	hit_area.monitorable = false


func _physics_process(_delta: float) -> void:
	if not _alive or GameState.instance.state != GameState.State.PLAYING:
		velocity = Vector2.ZERO
		return

	var input_vec := Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	input_vec += GameState.instance.touch_input
	input_vec = input_vec.limit_length(1.0)

	if input_vec.length() > 0.0:
		velocity = input_vec * speed
		animated_sprite.play()
	else:
		velocity = Vector2.ZERO
		animated_sprite.stop()

	move_and_slide()
	position = position.clamp(Vector2.ZERO, screen_size)

	rotation = 0.0
	trail.rotation = 0.0
	if input_vec.x != 0.0:
		animated_sprite.animation = &"right"
		animated_sprite.flip_v = false
		animated_sprite.flip_h = input_vec.x < 0.0
	elif input_vec.y != 0.0:
		animated_sprite.animation = &"up"
		animated_sprite.flip_h = false
		animated_sprite.flip_v = input_vec.y > 0.0


func start(pos: Vector2) -> void:
	position = pos
	rotation = 0.0
	velocity = Vector2.ZERO
	_alive = true
	show()
	body_shape.set_deferred(&"disabled", false)
	hit_shape.set_deferred(&"disabled", false)
	hit_area.set_deferred(&"monitoring", true)


func _on_hit_area_body_entered(_body: Node2D) -> void:
	if not _alive:
		return
	_alive = false
	velocity = Vector2.ZERO
	hide()
	hit.emit()
	body_shape.set_deferred(&"disabled", true)
	hit_shape.set_deferred(&"disabled", true)
	hit_area.set_deferred(&"monitoring", false)


func _refresh_screen_size() -> void:
	screen_size = get_viewport_rect().size
