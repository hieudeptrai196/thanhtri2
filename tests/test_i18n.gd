extends GameTest


func _msgids() -> PackedStringArray:
	var ids := PackedStringArray()
	for line in FileAccess.get_file_as_string("res://locale/messages.pot").split("\n"):
		if line.begins_with("msgid \"") and line != "msgid \"\"":
			ids.append(line.substr(7, line.length() - 8).c_unescape())
	return ids


func test_every_string_has_an_english_translation() -> void:
	var ids := _msgids()
	check(ids.size() > 50, "the template lists the game's strings (%d)" % ids.size())
	TranslationServer.set_locale("en")
	var untranslated := []
	for id in ids:
		if tr(id) == id and id != "THÀNH TRÌ":  # the title stays as is
			untranslated.append(id)
	check(untranslated.is_empty(), "untranslated in English: %s" % [untranslated])
	check(tr("Chơi") == "Play" and tr("Tốc độ %d%%") % 80 == "Speed 80%", "English texts and placeholders work")
	TranslationServer.set_locale("vi")
	check(tr("Chơi") == "Chơi", "Vietnamese is the source language")


func test_first_launch_asks_for_a_language_then_remembers_it() -> void:
	check(not Locales.has_chosen(), "no language chosen on a fresh save")
	var scene: Node = MAIN_SCENE.instantiate()
	tree.root.add_child(scene)
	await frames(2)
	var menu: StartMenu = scene.get_node("Match/UI/StartMenu")
	check(menu.visible and not menu.get_node("%Play").visible, "first launch shows only the language choice")
	menu._language_buttons["en"].pressed.emit()
	check(Locales.has_chosen() and Locales.current() == "en", "the choice is saved")
	check(TranslationServer.get_locale().begins_with("en"), "and applied")
	check(menu.get_node("%Play").visible and menu.get_node("%Play").text == "Play", "the menu redraws in English")
	menu._language_buttons["vi"].pressed.emit()
	check(menu.get_node("%Play").text == "Chơi", "switching back redraws in Vietnamese")
	tree.paused = false
	scene.free()
	SaveManager.reload()
	Locales.apply_saved()
	check(TranslationServer.get_locale().begins_with("vi"), "the saved language is applied on the next start")
