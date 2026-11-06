class_name GameState
extends Node

## Autoloaded as GameStateAutoload. Access the live singleton via GameState.instance.

enum State { IDLE, READY, PLAYING, GAME_OVER, PAUSED }

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "score"
const SAVE_KEY_HIGH := "high"

signal state_changed(new_state: State)
signal score_changed(score: int)
signal high_score_changed(high_score: int)

static var instance: GameState

var _state: State = State.IDLE
var _score: int = 0
var _high_score: int = 0

var state: State:
	get:
		return _state
	set(value):
		if _state == value:
			return
		_state = value
		state_changed.emit(_state)

var score: int:
	get:
		return _score
	set(value):
		_score = value
		score_changed.emit(_score)

var high_score: int:
	get:
		return _high_score
	set(value):
		_high_score = value
		high_score_changed.emit(_high_score)

## Combined touch/virtual-joystick input in [-1, 1].
var touch_input := Vector2.ZERO


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	high_score = load_high_score()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func can_start_new_game() -> bool:
	return _state == State.IDLE or _state == State.GAME_OVER


func begin_ready() -> void:
	unpause_tree()
	score = 0
	touch_input = Vector2.ZERO
	state = State.READY


func begin_playing() -> void:
	state = State.PLAYING


func begin_game_over() -> void:
	unpause_tree()
	touch_input = Vector2.ZERO
	if _score > _high_score:
		high_score = _score
		save_high_score(_high_score)
	state = State.GAME_OVER


func toggle_pause() -> void:
	if _state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
	elif _state == State.PAUSED:
		unpause_tree()
		state = State.PLAYING


func unpause_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false


func load_high_score() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value(SAVE_SECTION, SAVE_KEY_HIGH, 0))


func save_high_score(value: int) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SAVE_SECTION, SAVE_KEY_HIGH, value)
	config.save(SAVE_PATH)
