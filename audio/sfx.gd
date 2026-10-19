class_name Sfx
extends RefCounted
## One-shot sound effects (Kenney CC0 sounds for now). `play` puts a positional sound in the
## caller's 3D world, `play_ui` a flat one; each picks a random variant and a slight pitch change so
## repeats do not grate, and each sound is capped at a few voices so a crowd of 300 does not roar.

const DIR := "res://assets/audio/"
## name -> [files under DIR, volume dB, max voices]
const SOUNDS := {
	&"swing": [["kenney/rpg-audio/drawKnife1", "kenney/rpg-audio/drawKnife2", "kenney/rpg-audio/drawKnife3"], -8.0, 4],
	&"hit": [["kenney/impact-sounds/impactPunch_medium_000", "kenney/impact-sounds/impactPunch_medium_001", "kenney/impact-sounds/impactPunch_medium_002"], -6.0, 5],
	&"enemy_die": [["kenney/impact-sounds/impactPunch_heavy_000", "oga/creature/hurt_01", "oga/creature/hurt_02", "oga/creature/hurt_03"], -5.0, 4],
	&"chop": [["kenney/rpg-audio/chop", "oga/woodmetal/wood_hit_01", "oga/woodmetal/wood_hit_02", "oga/woodmetal/wood_hit_03"], -4.0, 3],
	&"mine": [["kenney/impact-sounds/impactMining_000", "kenney/impact-sounds/impactMining_001", "kenney/impact-sounds/impactMining_002"], -4.0, 3],
	&"tree_fall": [["oga/woodmetal/wood_cracking_01", "oga/woodmetal/wood_falling_01", "oga/woodmetal/wood_falling_02"], -2.0, 2],
	&"shoot": [["kenney/impact-sounds/impactGeneric_light_000", "kenney/impact-sounds/impactGeneric_light_001", "kenney/rpg-audio/metalLatch"], -10.0, 4],
	&"throw": [["oga/sfx100v2/sfx100v2_air_01", "oga/sfx100v2/sfx100v2_air_02"], -6.0, 3],
	&"magic": [["oga/sfx100v2/sfx100v2_air_02", "kenney/impact-sounds/impactBell_heavy_000"], -10.0, 2],
	&"smash": [["oga/woodmetal/wood_slam_01", "oga/woodmetal/wood_slam_02", "kenney/impact-sounds/impactWood_heavy_000"], -2.0, 2],
	&"boom": [["kenney/impact-sounds/impactPlate_heavy_000", "oga/sfx100v2/sfx100v2_thunder_01"], 0.0, 3],
	&"divine": [["kenney/impact-sounds/impactBell_heavy_000"], 0.0, 1],
	&"coins": [["kenney/rpg-audio/handleCoins", "kenney/rpg-audio/handleCoins2"], -6.0, 2],
	&"build": [["oga/woodmetal/wood_slam_01", "kenney/rpg-audio/creak1"], -4.0, 2],
	&"hammer": [["oga/woodmetal/wood_hammer_01", "oga/woodmetal/wood_hammer_02", "oga/woodmetal/hammer_01", "oga/woodmetal/hammer_02"], -8.0, 3],
	&"break": [["oga/woodmetal/wood_breaking_01", "oga/woodmetal/wood_breaking_02"], -2.0, 2],
	&"fort_hit": [["oga/woodmetal/metal_slam_01", "oga/woodmetal/wood_slam_02", "oga/woodmetal/metal_hit_01"], -8.0, 2],
	&"hurt": [["oga/woodmetal/metal_hit_02", "oga/woodmetal/metal_hit_03", "oga/sfx100v2/sfx100v2_metal_hit_01"], -6.0, 2],
	&"downed": [["oga/woodmetal/metal_sheet_01", "oga/creature/breath"], -4.0, 1],
	&"step": [["oga/sfx100v2/sfx100v2_footstep_wet_01", "oga/sfx100v2/sfx100v2_footstep_wet_02", "oga/sfx100v2/sfx100v2_footstep_wet_03"], -20.0, 3],
	&"groan": [["oga/creature/monster_01", "oga/creature/monster_02", "oga/creature/monster_03", "oga/creature/monster_04",
		"oga/creature/monster_05", "oga/creature/grunt_01", "oga/creature/grunt_02", "oga/creature/grunt_03", "oga/creature/troll_01", "oga/creature/troll_02"], -10.0, 3],
	&"roar": [["oga/creature/roar_01", "oga/creature/roar_02", "oga/creature/roar_03"], -2.0, 1],
	&"howl": [["oga/creature/howl"], -14.0, 1],
	&"thunder": [["oga/sfx100v2/sfx100v2_thunder_01"], -10.0, 1],
	&"war_cry": [["oga/creature/roar_02", "oga/creature/troll_03"], -2.0, 1],
	&"repair": [["oga/woodmetal/tools_01", "oga/woodmetal/tools_02", "oga/woodmetal/tools_03"], -10.0, 1],
	&"click": [["kenney/interface-sounds/click_002"], -8.0, 2],
	&"confirm": [["kenney/interface-sounds/confirmation_002"], -6.0, 1],
	&"error": [["kenney/interface-sounds/error_004"], -8.0, 1],
	&"ping": [["kenney/interface-sounds/drop_002"], -6.0, 2],
	&"revive": [["kenney/interface-sounds/confirmation_002"], -4.0, 1],
	&"stop": [["kenney/music-jingles/jingles_STEEL00"], -6.0, 1],
	&"depart": [["kenney/music-jingles/jingles_STEEL04"], -6.0, 1],
	&"lost": [["kenney/music-jingles/jingles_STEEL09"], -4.0, 1],
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
