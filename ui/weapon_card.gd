class_name WeaponCard
extends Button
## One clickable weapon upgrade card. Layout lives in weapon_card.tscn so it can be restyled in the
## editor; art comes from WeaponUpgrade.art and the frame from UiStyle.card_frame().

@onready var _art: TextureRect = %Art
@onready var _art_placeholder: Control = %ArtPlaceholder
@onready var _title: Label = %Title
@onready var _description: Label = %Description
@onready var _cost: Label = %Cost


func _ready() -> void:
	UiStyle.apply_card(self)
	_art_placeholder.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.WOOD_DARK, UiStyle.MUTED.darkened(0.3), 1, 6))
	_title.add_theme_color_override("font_color", UiStyle.BRONZE_BRIGHT)
	_description.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	_cost.add_theme_color_override("font_color", UiStyle.BRONZE)


func show_upgrade(upgrade: WeaponUpgrade) -> void:
	_title.text = tr(upgrade.display_name)
	_description.text = tr(upgrade.description)
	_cost.text = ResourceTypes.format_amounts(upgrade.cost)
	_art.texture = upgrade.art
	_art.visible = upgrade.art != null
	_art_placeholder.visible = upgrade.art == null


func set_chosen(chosen: bool) -> void:
	if chosen:
		add_theme_stylebox_override("disabled", UiStyle.card_frame(UiStyle.BRONZE_BRIGHT, 4))
