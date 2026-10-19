class_name Sfx
extends RefCounted
## One-shot sound effects (Kenney CC0 sounds for now). `play` puts a positional sound in the
## caller's 3D world, `play_ui` a flat one; each picks a random variant and a slight pitch change so
## repeats do not grate, and each sound is capped at a few voices so a crowd of 300 does not roar.

const DIR := "res://assets/audio/kenney/"
## name -> [files, volume dB, max voices]
const SOUNDS := {
	&"swing": [["rpg-audio/drawKnife1", "rpg-audio/drawKnife2", "rpg-audio/drawKnife3"], -8.0, 4],
	&"hit": [["impact-sounds/impactPunch_medium_000", "impact-sounds/impactPunch_medium_001", "impact-sounds/impactPunch_medium_002"], -6.0, 5],
	&"enemy_die": [["impact-sounds/impactPunch_heavy_000", "impact-sounds/impactWood_heavy_000"], -5.0, 4],
	&"chop": [["rpg-audio/chop", "impact-sounds/impactWood_medium_000", "impact-sounds/impactWood_medium_001"], -4.0, 3],
	&"mine": [["impact-sounds/impactMining_000", "impact-sounds/impactMining_001", "impact-sounds/impactMining_002"], -4.0, 3],
	&"shoot": [["impact-sounds/impactGeneric_light_000", "impact-sounds/impactGeneric_light_001", "rpg-audio/metalLatch"], -10.0, 4],
	&"boom": [["impact-sounds/impactPlate_heavy_000", "impact-sounds/impactWood_heavy_000"], 0.0, 3],
	&"divine": [["impact-sounds/impactBell_heavy_000"], 0.0, 1],
	&"coins": [["rpg-audio/handleCoins", "rpg-audio/handleCoins2"], -6.0, 2],
	&"build": [["rpg-audio/creak1", "rpg-audio/dropLeather"], -6.0, 2],
	&"click": [["interface-sounds/click_002"], -8.0, 2],
	&"confirm": [["interface-sounds/confirmation_002"], -6.0, 1],
	&"error": [["interface-sounds/error_004"], -8.0, 1],
	&"stop": [["music-jingles/jingles_STEEL00"], -6.0, 1],
	&"depart": [["music-jingles/jingles_STEEL04"], -6.0, 1],
	&"lost": [["music-jingles/jingles_STEEL09"], -4.0, 1],
}
## Sounds this far beyond the listener's view are not worth a voice.
const MAX_DISTANCE := 45.0

static var _streams: Dictionary = {}
static var _voices: Dictionary = {}


## A positional sound at `at`, in `context`'s world.
static func play(context: Node, sound: StringName, at: Vector3) -> void:
	var stream := _pick(sound)
	if stream == null or context == null or not context.is_inside_tree():
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = SOUNDS[sound][1]
	player.pitch_scale = randf_range(0.92, 1.08)
	player.max_distance = MAX_DISTANCE
	player.unit_size = 12.0
	_start(context.get_viewport(), player, sound)
	player.global_position = at


## A non-positional sound (UI, jingles).
static func play_ui(context: Node, sound: StringName) -> void:
	var stream := _pick(sound)
	if stream == null or context == null or not context.is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = SOUNDS[sound][1]
	_start(context.get_viewport(), player, sound)


static func _pick(sound: StringName) -> AudioStream:
	if not SOUNDS.has(sound) or _voices.get(sound, 0) >= SOUNDS[sound][2]:
		return null
	var files: Array = SOUNDS[sound][0]
	var path: String = DIR + files[randi() % files.size()] + ".ogg"
	if not _streams.has(path):
		_streams[path] = load(path)
	return _streams[path]


static func _start(parent: Node, player: Node, sound: StringName) -> void:
	_voices[sound] = _voices.get(sound, 0) + 1
	player.process_mode = Node.PROCESS_MODE_ALWAYS  # jingles still play over the paused result screen
	# Counted down when the player leaves the tree, so a scene reload mid-sound frees its voice too.
	player.tree_exiting.connect(func() -> void: _voices[sound] = maxi(_voices.get(sound, 1) - 1, 0))
	player.finished.connect(player.queue_free)
	parent.add_child(player)
	player.play()
