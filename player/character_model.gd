class_name CharacterModel
extends Node3D
## The look of a rigged character under a gameplay body (KayKit 2.0 "Rig_Medium" models for now):
## loads the model, shares the animation libraries of the KayKit Character Animations pack with it,
## hangs held items on the hand bones, hides unwanted meshes, loops the clips that loop and plays
## clips by name with a short blend. Gameplay never depends on it — bodies keep their collision
## shapes and work without a model.

## Animation sets every humanoid model gets (same Rig_Medium skeleton).
const LIBRARIES: Array[String] = [
	"res://assets/kaykit2/animations/Rig_Medium_General.glb",
	"res://assets/kaykit2/animations/Rig_Medium_MovementBasic.glb",
	"res://assets/kaykit2/animations/Rig_Medium_MovementAdvanced.glb",
	"res://assets/kaykit2/animations/Rig_Medium_CombatMelee.glb",
	"res://assets/kaykit2/animations/Rig_Medium_CombatRanged.glb",
	"res://assets/kaykit2/animations/Rig_Medium_Tools.glb",
	"res://assets/kaykit2/animations/Rig_Medium_Special.glb",
	"res://assets/kaykit2/animations/Rig_Medium_Simulation.glb",
]
## Clips that repeat until something else plays.
const LOOPING: Array[StringName] = [&"Idle_A", &"Idle_B", &"Running_A", &"Running_B", &"Walking_A", &"Walking_B",
	&"Walking_C", &"Running_HoldingRifle", &"Running_HoldingBow", &"Crouching", &"Sneaking", &"Lie_Idle",
	&"Hammering", &"Chopping", &"Pickaxing", &"Digging", &"Sawing", &"Working_A", &"Working_B", &"Working_C",
	&"Holding_A", &"Holding_B", &"Holding_C", &"Melee_2H_Idle", &"Melee_Unarmed_Idle", &"Melee_Blocking",
	&"Ranged_1H_Aiming", &"Ranged_2H_Aiming", &"Ranged_Bow_Idle", &"Ranged_Magic_Spellcasting",
	&"Skeletons_Idle", &"Skeletons_Walking", &"Skeletons_Inactive_Standing_Pose", &"Sit_Floor_Idle"]
## Hand bones held items hang from.
const RIGHT_HAND := "handslot.r"
const LEFT_HAND := "handslot.l"

var animation_player: AnimationPlayer
var current: StringName = &""
var _skeleton: Skeleton3D
## Crowd mode (enemies): animation is stepped by hand, every `stride` frames, and not at all while
## off screen. Hundreds of skinned models animating every frame cost more than the rest of the game.
var _crowd: bool = false
var _stride: int = 1
var _phase: int = 0
var _pending: float = 0.0
var _on_screen: bool = true
# Merged body meshes per model + hidden set (see _merge_body), and the shared animation library.
static var _merged: Dictionary = {}
static var _library: AnimationLibrary


## Loads `scene` at `scale_factor`. Options:
##   hide: mesh names to remove (e.g. a helmet visor), right / left: scene paths held in the hands,
##   tint: colour for meshes whose names contain "Cape" or "Cloak", shadows (default true),
##   merge: merge the body meshes into one draw per material (crowds).
func setup(scene: PackedScene, scale_factor: float, options: Dictionary = {}) -> void:
	for child in get_children():
		child.queue_free()
	current = &""
	var model: Node3D = scene.instantiate()
	add_child(model)
	# KayKit models face +Z; gameplay bodies face -Z.
	model.rotation.y = PI
	model.scale = Vector3.ONE * scale_factor
	_skeleton = model.find_children("*", "Skeleton3D", true, false).front()
	var hidden: PackedStringArray = options.get("hide", PackedStringArray())
	for child in _skeleton.get_children():
		if child is MeshInstance3D and hidden.has(String(child.name)):
			child.free()
	_hold(RIGHT_HAND, options.get("right", ""))
	_hold(LEFT_HAND, options.get("left", ""))
	_light_up_eyes()
	if options.get("merge", false):
		_merge_body(scene.resource_path + str(hidden))
	var shadows: bool = options.get("shadows", true)
	var tint: Color = options.get("tint", Color.WHITE)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mesh_name := String(mesh.name)
		if tint != Color.WHITE and ("Cape" in mesh_name or "Cloak" in mesh_name):
			var material := mesh.get_active_material(0).duplicate() as StandardMaterial3D
			material.albedo_color = tint
			mesh.material_override = material
	animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	model.add_child(animation_player)
	animation_player.add_animation_library(&"", _shared_library())


# Every model shares one library built from the Character Animations pack (looping clips marked).
static func _shared_library() -> AnimationLibrary:
	if _library == null:
		_library = AnimationLibrary.new()
		for path in LIBRARIES:
			var holder: Node = load(path).instantiate()
			var source: AnimationPlayer = holder.find_children("*", "AnimationPlayer", true, false).front()
			for clip in source.get_animation_list():
				if clip == &"T-Pose" or _library.has_animation(clip):
					continue
				var animation := source.get_animation(clip)
				if LOOPING.has(clip):
					animation.loop_mode = Animation.LOOP_LINEAR
				_library.add_animation(clip, animation)
			holder.free()
	return _library


func _hold(bone: String, item_path: String) -> void:
	if item_path == "" or _skeleton.find_bone(bone) == -1:
		return
	var slot := BoneAttachment3D.new()
	slot.name = bone.replace(".", "_")
	slot.bone_name = bone
	_skeleton.add_child(slot)
	slot.add_child(load(item_path).instantiate())


# Eyes glow in the dark (the material is shared by every instance of the model, so this runs once).
func _light_up_eyes() -> void:
	for child in _skeleton.get_children():
		if child is MeshInstance3D and String(child.name).ends_with("_Eyes"):
			var material := child.mesh.surface_get_material(0) as StandardMaterial3D
			if material and not material.emission_enabled:
				material.emission_enabled = true
				material.emission = Color(1.0, 0.75, 0.25)
				material.emission_energy_multiplier = 3.0


# The body parts of a rig share one skin; merged by material they draw in 2 calls instead of ~9.
# The merged mesh is built once per model (and hidden set) and shared.
func _merge_body(key: String) -> void:
	var parts: Array[MeshInstance3D] = []
	for child in _skeleton.get_children():
		if child is MeshInstance3D and child.skin != null and child.transform == Transform3D.IDENTITY:
			parts.append(child)
	if parts.size() < 2:
		return
	if not _merged.has(key):
		var by_material := {}
		for part in parts:
			for surface in part.mesh.get_surface_count():
				var material := part.mesh.surface_get_material(surface)
				if not by_material.has(material):
					by_material[material] = []
				by_material[material].append([part.mesh, surface])
		var merged := ArrayMesh.new()
		for material: Material in by_material:
			var tool := SurfaceTool.new()
			for entry: Array in by_material[material]:
				tool.append_from(entry[0], entry[1], Transform3D.IDENTITY)
			tool.set_material(material)
			tool.commit(merged)
		_merged[key] = merged
	var body := MeshInstance3D.new()
	body.name = "MergedBody"
	body.mesh = _merged[key]
	body.skin = parts[0].skin
	_skeleton.add_child(body)
	body.skeleton = body.get_path_to(_skeleton)
	for part in parts:
		part.free()


## Crowd mode: step the animation by hand every `stride` frames (offset by `phase` so a crowd
## spreads the work), skipping it while off screen.
func set_crowd(stride: int, phase: int) -> void:
	if not _crowd:
		_crowd = true
		animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var notifier := VisibleOnScreenNotifier3D.new()
		notifier.aabb = AABB(Vector3(-1, 0, -1), Vector3(2, 2.5, 2))
		notifier.screen_entered.connect(func() -> void: _on_screen = true)
		notifier.screen_exited.connect(func() -> void: _on_screen = false)
		add_child(notifier)
		_on_screen = false
	_stride = maxi(stride, 1)
	_phase = phase


func _process(delta: float) -> void:
	if not _crowd or animation_player == null:
		return
	_pending += delta
	if not _on_screen:
		_pending = minf(_pending, 0.5)
		return
	if (Engine.get_process_frames() + _phase) % _stride == 0:
		animation_player.advance(_pending)
		_pending = 0.0


func has_clip(clip: StringName) -> bool:
	return animation_player != null and animation_player.has_animation(clip)


## Plays `clip` (blending from the current one) unless it is already playing; `restart` replays it.
func play(clip: StringName, speed: float = 1.0, blend: float = 0.15, restart: bool = false) -> void:
	if not has_clip(clip):
		return
	animation_player.speed_scale = speed
	if clip == current and not restart and animation_player.is_playing():
		return
	current = clip
	animation_player.play(clip, blend)
	if restart:
		animation_player.seek(0.0, true)


## True while a one-shot clip (attack, dash, cheer…) still has time left.
func is_busy() -> bool:
	if animation_player == null or not animation_player.is_playing() or LOOPING.has(current):
		return false
	return animation_player.current_animation_position < animation_player.current_animation_length - 0.05


func clip_length(clip: StringName) -> float:
	return animation_player.get_animation(clip).length if has_clip(clip) else 0.0
