extends Node

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var mob_spawner: Node = $MobSpawner
@onready var score_timer: Timer = $ScoreTimer
@onready var start_timer: Timer = $StartTimer
@onready var start_position: Marker2D = $StartPosition


func _ready() -> void:
	hud.update_high_score(GameState.instance.high_score)
	GameState.instance.high_score_changed.connect(hud.update_high_score)
	GameState.instance.score_changed.connect(hud.update_score)
	GameState.instance.state_changed.connect(_on_game_state_changed)
	hud.set_paused_visible(false)
	hud.set_controls_for_state(GameState.instance.state)


func game_over() -> void:
	if (
		GameState.instance.state != GameState.State.PLAYING
		and GameState.instance.state != GameState.State.PAUSED
	):
		return

	score_timer.stop()
	mob_spawner.stop()
	GameState.instance.begin_game_over()
	hud.show_game_over()
	AudioManager.instance.stop_music()
	AudioManager.instance.play_death()


func new_game() -> void:
	if not GameState.instance.can_start_new_game():
		return

	mob_spawner.recycle_all()
	mob_spawner.reset_difficulty()
	hud.cancel_game_over_sequence()
	hud.set_paused_visible(false)
	GameState.instance.begin_ready()
	hud.show_message("Get Ready")
	player.start(start_position.position)
	start_timer.start()
	AudioManager.instance.play_music()


func _on_ScoreTimer_timeout() -> void:
	if GameState.instance.state != GameState.State.PLAYING:
		return
	GameState.instance.score += 1
	mob_spawner.update_difficulty(GameState.instance.score)


func _on_StartTimer_timeout() -> void:
	if GameState.instance.state != GameState.State.READY:
		return
	GameState.instance.begin_playing()
	mob_spawner.start()
	score_timer.start()


func _on_game_state_changed(new_state: GameState.State) -> void:
	hud.set_paused_visible(new_state == GameState.State.PAUSED)
	hud.set_controls_for_state(new_state)


func _on_HUD_pause_pressed() -> void:
	GameState.instance.toggle_pause()


func _on_HUD_resume_pressed() -> void:
	if GameState.instance.state == GameState.State.PAUSED:
		GameState.instance.toggle_pause()
