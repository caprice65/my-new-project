extends CanvasLayer

signal start_game
signal pause_pressed
signal resume_pressed

## Bumped to cancel in-flight show_game_over awaits when a new game starts.
var _sequence_token := 0

@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var message_label: Label = $MessageLabel
@onready var start_button: Button = $StartButton
@onready var message_timer: Timer = $MessageTimer
@onready var pause_button: Button = $PauseButton
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/ResumeButton
@onready var joystick: Control = $VirtualJoystick


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	message_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	set_paused_visible(false)
	pause_button.hide()
	joystick.visible = true


func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	message_timer.start()


func show_game_over() -> void:
	_sequence_token += 1
	var token := _sequence_token
	pause_button.hide()

	show_message("Game Over")
	await message_timer.timeout
	if token != _sequence_token:
		return

	message_label.text = "Dodge the\nCreeps"
	message_label.show()
	await get_tree().create_timer(1.0).timeout
	if token != _sequence_token:
		return

	start_button.show()


func cancel_game_over_sequence() -> void:
	_sequence_token += 1
	message_timer.stop()
	start_button.hide()


func update_score(score: int) -> void:
	score_label.text = str(score)


func update_high_score(high_score: int) -> void:
	high_score_label.text = "Best %s" % high_score


func set_paused_visible(is_paused: bool) -> void:
	pause_overlay.visible = is_paused


func set_controls_for_state(state: GameState.State) -> void:
	var playing := state == GameState.State.PLAYING or state == GameState.State.PAUSED
	pause_button.visible = playing
	joystick.visible = playing or state == GameState.State.READY


func _on_StartButton_pressed() -> void:
	start_button.hide()
	start_game.emit()


func _on_MessageTimer_timeout() -> void:
	message_label.hide()


func _on_PauseButton_pressed() -> void:
	pause_pressed.emit()


func _on_ResumeButton_pressed() -> void:
	resume_pressed.emit()
