class_name ResultScreen
extends Control
## End-of-run screen over a dimmed world. Reports the restart press; the match does the restart.
## Below the run's numbers: the team summary by role (co-op MVPs), or the player's own share solo.

signal restart_requested
signal menu_requested

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _stats: Label = %Stats
@onready var _restart: Button = %Restart
@onready var _menu: Button = %Menu
@onready var _record: Label = %Record
@onready var _team: GridContainer = %Team


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.panel())
	UiStyle.outline(_title, 8)
	_stats.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	UiStyle.apply_button(_restart, UiStyle.BRONZE_BRIGHT)
	_restart.text = tr("Chơi lại")
	_restart.pressed.connect(restart_requested.emit)
	UiStyle.apply_button(_menu)
	_menu.text = tr("Về menu")
	_menu.pressed.connect(menu_requested.emit)
	_record.add_theme_color_override("font_color", UiStyle.BRONZE_BRIGHT)
	UiStyle.outline(_record, 6)
	hide()


## `daily_date` is empty for a random run.
func show_result(distance: float, seconds: float, kills: int, best: float, is_record: bool, daily_date: String = "") -> void:
	_title.text = tr("Thành trì đã thất thủ")
	_title.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
	_record.text = tr("Kỷ lục mới!") if is_record else ""
	_record.visible = is_record
	var heading := (tr("Thử thách ngày %s") % UiStyle.short_date(daily_date) + "\n") if daily_date != "" else ""
	_stats.text = heading + tr("Quãng đường: %s\nKỷ lục: %s\nThời gian: %d:%02d\nQuái đã hạ: %d") % [
		UiStyle.format_meters(distance), UiStyle.format_meters(best), int(seconds) / 60, int(seconds) % 60, kills]
	show()


## Co-op: the best player of each role (rows for roles nobody did are left out). Solo: one line
## with the player's own numbers. `local_peer` is this machine's player, marked "(bạn)".
func show_team(stats: TeamStats, local_peer: int) -> void:
	for child in _team.get_children():
		child.queue_free()
	var peers := stats.peers()
	if peers.size() <= 1:
		var me: int = peers[0] if peers.size() == 1 else local_peer
		_team.columns = 1
		_add_cell(tr("Bạn đã gõ búa %d giây, mang về %d tài nguyên, tự tay hạ %d quái") % [
			roundi(stats.value(me, &"build")), roundi(stats.value(me, &"haul")), roundi(stats.value(me, &"kills"))], UiStyle.MUTED)
		_team.visible = true
		return
	_team.columns = 2
	var rows := 0
	for category in TeamStats.CATEGORIES:
		var peer := stats.best(category)
		if peer == 0:
			continue
		var who := _player_name(stats, peer, local_peer)
		var amount := roundi(stats.value(peer, category))
		match category:
			&"build":
				_add_row(tr("Thợ xây cừ nhất"), tr("%s — gõ búa %d giây") % [who, amount])
			&"haul":
				_add_row(tr("Khuân vác giỏi nhất"), tr("%s — mang về %d tài nguyên") % [who, amount])
			&"kills":
				_add_row(tr("Diệt quái nhiều nhất"), tr("%s — hạ %d quái") % [who, amount])
			&"revives":
				_add_row(tr("Cứu người nhiều nhất"), tr("%s — đỡ dậy %d lần") % [who, amount])
		rows += 1
	_team.visible = rows > 0


# Players are known by their class (the role is the point of the summary), else by join order.
func _player_name(stats: TeamStats, peer: int, local_peer: int) -> String:
	var index := stats.class_index(peer)
	var name := tr(PlayerClasses.ALL[index].display_name) if index >= 0 and index < PlayerClasses.ALL.size() \
		else tr("Người chơi %d") % stats.order(peer)
	return tr("%s (bạn)") % name if peer == local_peer else name


func _add_row(title: String, detail: String) -> void:
	_add_cell(title, UiStyle.BRONZE_BRIGHT).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_add_cell(detail, UiStyle.PARCHMENT)


func _add_cell(text: String, color: Color) -> Label:
	var cell := UiStyle.label(text, 18, color)
	_team.add_child(cell)
	return cell
