class_name MusicPlayer
extends Node
## Background music and the ambience bed for a match: one looping track at a time with a short
## crossfade between tracks (menu, march, stop), plus night ambience — rain all the time, thunder
## and a far howl now and then. Local to each machine.

const TRACKS := {
	&"menu": ["res://assets/audio/oga/music/menu_the_9th_circle.mp3", -12.0],
	&"battle": ["res://assets/audio/oga/music/battle_zombies_are_coming.ogg", -11.0],
	&"stop": ["res://assets/audio/oga/music/stop_dark_forest_theme.mp3", -12.0],
}
const RAIN := "res://assets/audio/oga/ambience/dark_rainy_night.ogg"
const FADE_SECONDS := 1.5

var current: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _ambience_left: float = 12.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps playing over the paused result screen
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)
	var rain := AudioStreamPlayer.new()
	rain.name = "Rain"
	rain.stream = _looping(RAIN)
	rain.volume_db = -20.0
	add_child(rain)
	rain.play()


## Crossfades to `track` (a TRACKS key); empty fades the music out.
func play(track: StringName) -> void:
	if track == current:
		return
	current = track
	var old := _players[_active]
	_active = 1 - _active
	var new := _players[_active]
	var fade := create_tween().set_parallel()
	fade.tween_property(old, "volume_db", -80.0, FADE_SECONDS)
	if TRACKS.has(track):
		new.stream = _looping(TRACKS[track][0])
		new.volume_db = -40.0
		new.play()
		fade.tween_property(new, "volume_db", TRACKS[track][1], FADE_SECONDS)
	fade.chain().tween_callback(old.stop)


# Now and then, thunder or a howl far away.
func _process(delta: float) -> void:
	_ambience_left -= delta
	if _ambience_left > 0.0:
		return
	_ambience_left = randf_range(14.0, 32.0)
	Sfx.play_ui(self, &"thunder" if randf() < 0.45 else &"howl")


static func _looping(path: String) -> AudioStream:
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	return stream
