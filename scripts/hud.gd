# hud.gd: the top bar, tower palette and game-over screen.
# Every label updates from GameState signals only; the HUD never reads
# gameplay nodes directly. Buttons emit signals that main.gd wires up.
extends CanvasLayer

signal start_pressed
signal tower_pressed(index: int)
signal restart_pressed

const FONT_SIZE := 9

var currency_label: Label
var lives_label: Label
var wave_label: Label
var status_label: Label
var hint_label: Label
var start_button: Button
var speed_button: Button
var palette: Array[TextureButton] = []
var overlay: Control
var overlay_title: Label
var overlay_text: Label


func build(tower_infos: Array) -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(480, 30)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("1a1c2c")
	bg.content_margin_left = 6
	bg.content_margin_right = 6
	bar.add_theme_stylebox_override("panel", bg)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)

	currency_label = _stat(row, "coin", "Coins")
	lives_label = _stat(row, "heart", "Lives")
	wave_label = _stat(row, "flag", "Wave")
	status_label = _label("")
	status_label.custom_minimum_size.x = 70
	row.add_child(status_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	start_button = _button("Start", "Start the next wave now (Space)")
	start_button.pressed.connect(start_pressed.emit)
	row.add_child(start_button)
	speed_button = _button("x1", "Toggle game speed")
	speed_button.pressed.connect(_toggle_speed)
	row.add_child(speed_button)

	for i in tower_infos.size():
		var info: Dictionary = tower_infos[i]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", -2)
		var b := TextureButton.new()
		b.texture_normal = Art.texture(info["sprite"])
		b.tooltip_text = "%s: %d coins, range %d (key %d)" % [info["name"], info["cost"], info["range"], i + 1]
		b.toggle_mode = true
		b.pressed.connect(tower_pressed.emit.bind(i))
		palette.append(b)
		box.add_child(b)
		var price := _label(str(info["cost"]))
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(price)
		row.add_child(box)

	hint_label = _label("Pick a cat (1, 2, 3), click grass to build. Right-click a cat to sell it for 70%.")
	hint_label.position = Vector2(6, 256)
	hint_label.add_theme_color_override("font_shadow_color", Color("1a1c2c"))
	add_child(hint_label)

	_build_overlay()
	GameState.currency_changed.connect(_on_currency)
	GameState.lives_changed.connect(func(v): lives_label.text = str(v))
	GameState.wave_changed.connect(func(w, total): wave_label.text = "%d/%d" % [w, total])
	GameState.countdown_changed.connect(_on_countdown)
	GameState.game_over.connect(_on_game_over)


func set_selected(index: int, info: Dictionary) -> void:
	for i in palette.size():
		palette[i].set_pressed_no_signal(i == index)
		palette[i].modulate = Color.WHITE if i == index or index < 0 else Color(1, 1, 1, 0.55)
	hint_label.text = ("%s selected: %d coins. Click grass to build, right-click to cancel." % [info["name"], info["cost"]]) if index >= 0 \
		else "Pick a cat (1, 2, 3), click grass to build. Right-click a cat to sell it for 70%."


func set_start_enabled(enabled: bool) -> void:
	start_button.disabled = not enabled


func _on_currency(value: int) -> void:
	currency_label.text = str(value)


func _on_countdown(seconds: int) -> void:
	status_label.text = "Next in %ds" % seconds if seconds >= 0 else ""


func _on_game_over(won: bool) -> void:
	Engine.time_scale = 1.0
	overlay_title.text = "Depot saved!" if won else "The depot fell"
	overlay_text.text = ("All %d waves held with %d lives left." % [GameState.total_waves, GameState.lives]) if won \
		else "The mice got through on wave %d of %d." % [GameState.wave, GameState.total_waves]
	overlay.visible = true


func _toggle_speed() -> void:
	Engine.time_scale = 2.0 if Engine.time_scale == 1.0 else 1.0
	speed_button.text = "x%d" % int(Engine.time_scale)


func _stat(row: HBoxContainer, icon: String, tip: String) -> Label:
	var tex := TextureRect.new()
	tex.texture = Art.texture(icon)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tex.tooltip_text = tip
	row.add_child(tex)
	var label := _label("0")
	label.custom_minimum_size.x = 26
	row.add_child(label)
	return label


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _button(text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.1, 0.11, 0.17, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.position = Vector2(140, 95)
	box.custom_minimum_size = Vector2(200, 80)
	overlay.add_child(box)
	overlay_title = _label("")
	overlay_title.add_theme_font_size_override("font_size", 18)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(overlay_title)
	overlay_text = _label("")
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(overlay_text)
	var again := _button("Play again", "Restart from wave 1")
	again.pressed.connect(restart_pressed.emit)
	box.add_child(again)
