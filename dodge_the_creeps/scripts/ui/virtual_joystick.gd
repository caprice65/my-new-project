extends Control

## On-screen stick; writes direction into GameState.touch_input.

@export var deadzone := 0.15
@export var radius := 64.0

var _active := false
var _touch_index := -1
var _knob_offset := Vector2.ZERO

@onready var _base: Panel = $Base
@onready var _knob: Panel = $Base/Knob


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_base.gui_input.connect(_on_base_gui_input)
	_reset_knob()
	# Always available; useful on tablets and for mouse drag testing.
	visible = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_release()


func _on_base_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and not _active:
			_active = true
			_touch_index = st.index
			_update_from_local(st.position)
		elif not st.pressed and st.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _active and sd.index == _touch_index:
			_update_from_local(sd.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and not _active:
				_active = true
				_touch_index = -1
				_update_from_local(mb.position)
			elif not mb.pressed and _active and _touch_index == -1:
				_release()
	elif event is InputEventMouseMotion and _active and _touch_index == -1:
		var mm := event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_update_from_local(mm.position)


func _update_from_local(local_pos: Vector2) -> void:
	var center := _base.size * 0.5
	var offset := local_pos - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_knob_offset = offset
	_knob.position = center - _knob.size * 0.5 + offset

	var dir := offset / radius
	if dir.length() < deadzone:
		dir = Vector2.ZERO
	else:
		# Remap so deadzone maps to 0 and edge to 1.
		dir = dir.normalized() * inverse_lerp(deadzone, 1.0, dir.length())
	GameState.instance.touch_input = dir


func _release() -> void:
	_active = false
	_touch_index = -1
	_reset_knob()
	GameState.instance.touch_input = Vector2.ZERO


func _reset_knob() -> void:
	var center := _base.size * 0.5
	_knob.position = center - _knob.size * 0.5
	_knob_offset = Vector2.ZERO
