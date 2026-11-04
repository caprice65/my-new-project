class_name AudioManager
extends Node

## Autoloaded as AudioManagerAutoload. Access via AudioManager.instance.

static var instance: AudioManager

@onready var _music: AudioStreamPlayer = $Music
@onready var _death_sound: AudioStreamPlayer = $DeathSound


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func play_music() -> void:
	if not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()


func play_death() -> void:
	_death_sound.play()
