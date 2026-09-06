extends Node2D

# Sporewick core loop: plant -> grow -> harvest -> combine at the Wick ->
# discover a hybrid species in the compendium.

const GROW_SECONDS := 3.0
const PLOT_COUNT := 4

const BASE_SPORES := ["Ember Cap", "Moss Puff", "Glimmer Truffle"]

const RECIPES := {
	"Ember Cap|Moss Puff": "Cindermoss Bloom",
	"Ember Cap|Glimmer Truffle": "Suncap Ember",
	"Glimmer Truffle|Moss Puff": "Duskmoss Lantern",
}

enum PlotState { EMPTY, GROWING, READY }

var plots := []
var inventory := []
var compendium := {}
var currency := 0

var _plot_buttons := []
var _currency_label: Label
var _compendium_label: Label
var _inventory_label: Label
var _status_label: Label
var _wick_button: Button

var autopilot_ok := true


func _ready() -> void:
	randomize()
	for i in range(PLOT_COUNT):
		plots.append({"state": PlotState.EMPTY, "spore_type": "", "timer": 0.0})

	_build_ui()
	_refresh_ui()

	var args := OS.get_cmdline_user_args()
	if args.has("--verify"):
		var outdir := "res://verification_output"
		for a in args:
			if a.begins_with("--outdir="):
				outdir = a.substr(len("--outdir="))
		await _run_autopilot(outdir)
		get_tree().quit(0 if autopilot_ok else 1)


func _process(delta: float) -> void:
	var changed := false
	for plot in plots:
		if plot.state == PlotState.GROWING:
			plot.timer += delta
			if plot.timer >= GROW_SECONDS:
				plot.state = PlotState.READY
				changed = true
	if changed:
		_refresh_ui()


func plant_at(i: int) -> bool:
	if plots[i].state != PlotState.EMPTY:
		return false
	plots[i].state = PlotState.GROWING
	plots[i].spore_type = BASE_SPORES[randi() % BASE_SPORES.size()]
	plots[i].timer = 0.0
	_refresh_ui()
	return true


func harvest_at(i: int) -> bool:
	if plots[i].state != PlotState.READY:
		return false
	inventory.append(plots[i].spore_type)
	plots[i].state = PlotState.EMPTY
	plots[i].spore_type = ""
	plots[i].timer = 0.0
	currency += 1
	_refresh_ui()
	return true


func combine_at_wick() -> bool:
	if inventory.size() < 2:
		return false
	var a: String = inventory.pop_front()
	var b: String = inventory.pop_front()
	var pair: Array[String] = [a, b]
	pair.sort()
	var key: String = pair[0] + "|" + pair[1]
	var result: String = RECIPES.get(key, "Mystery Spore")
	var is_new := not compendium.has(result)
	compendium[result] = compendium.get(result, 0) + 1
	currency += 10 if is_new else 3
	_refresh_ui()
	return true


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	canvas.add_child(root)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 48)
	root.add_child(margin)

	var top_box := VBoxContainer.new()
	margin.add_child(top_box)

	var title := Label.new()
	title.text = "Sporewick"
	title.add_theme_font_size_override("font_size", 32)
	top_box.add_child(title)

	_currency_label = Label.new()
	top_box.add_child(_currency_label)

	_compendium_label = Label.new()
	top_box.add_child(_compendium_label)

	_inventory_label = Label.new()
	top_box.add_child(_inventory_label)

	_status_label = Label.new()
	top_box.add_child(_status_label)

	var plots_box := HBoxContainer.new()
	plots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	plots_box.add_theme_constant_override("separation", 12)
	root.add_child(plots_box)

	for i in range(PLOT_COUNT):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 140)
		btn.pressed.connect(_on_plot_pressed.bind(i))
		plots_box.add_child(btn)
		_plot_buttons.append(btn)

	var wick_margin := MarginContainer.new()
	wick_margin.add_theme_constant_override("margin_left", 24)
	wick_margin.add_theme_constant_override("margin_right", 24)
	root.add_child(wick_margin)

	_wick_button = Button.new()
	_wick_button.custom_minimum_size = Vector2(0, 90)
	_wick_button.text = "Combine at the Wick"
	_wick_button.pressed.connect(_on_wick_pressed)
	wick_margin.add_child(_wick_button)


func _on_plot_pressed(i: int) -> void:
	match plots[i].state:
		PlotState.EMPTY:
			plant_at(i)
		PlotState.READY:
			harvest_at(i)
		_:
			pass # still growing, ignore taps


func _on_wick_pressed() -> void:
	if not combine_at_wick():
		_status_label.text = "Need 2 harvested spores to combine."


func _refresh_ui() -> void:
	_currency_label.text = "Currency: %d" % currency
	_compendium_label.text = "Compendium: %d discovered" % compendium.size()
	_inventory_label.text = "Inventory: %s" % (", ".join(inventory) if inventory.size() > 0 else "empty")

	for i in range(PLOT_COUNT):
		var plot = plots[i]
		var btn: Button = _plot_buttons[i]
		match plot.state:
			PlotState.EMPTY:
				btn.text = "Empty plot\n(tap to plant)"
				btn.modulate = Color(0.55, 0.55, 0.55)
			PlotState.GROWING:
				var pct := int(100.0 * plot.timer / GROW_SECONDS)
				btn.text = "%s\ngrowing %d%%" % [plot.spore_type, pct]
				btn.modulate = Color(0.6, 0.75, 0.5)
			PlotState.READY:
				btn.text = "%s\nready! (tap to harvest)" % plot.spore_type
				btn.modulate = Color(1.0, 0.85, 0.4)


# --- Headless verification autopilot ---
# Drives the real game logic and UI end to end, capturing real rendered
# screenshots at each step so "it works" is checked against actual output.

func _screenshot(dir: String, name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join(name + ".png"))
	print("SCREENSHOT ", name)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		print("FAIL: ", msg)
		autopilot_ok = false


func _run_autopilot(outdir: String) -> void:
	print("--- Sporewick headless autopilot start ---")
	await _screenshot(outdir, "00_start")

	_assert(plant_at(0), "plant plot 0")
	_assert(plant_at(1), "plant plot 1")
	await _screenshot(outdir, "01_planted")

	await get_tree().create_timer(GROW_SECONDS + 0.5).timeout
	_assert(plots[0].state == PlotState.READY, "plot 0 grew to ready")
	_assert(plots[1].state == PlotState.READY, "plot 1 grew to ready")
	await _screenshot(outdir, "02_grown")

	_assert(harvest_at(0), "harvest plot 0")
	_assert(harvest_at(1), "harvest plot 1")
	_assert(inventory.size() == 2, "inventory has 2 harvested spores")
	await _screenshot(outdir, "03_harvested")

	var before := compendium.size()
	_assert(combine_at_wick(), "combine at wick")
	_assert(compendium.size() == before + 1, "compendium gained a new species")
	_assert(currency > 0, "currency increased over the loop")
	await _screenshot(outdir, "04_combined")

	print("Final state: currency=%d compendium=%s inventory=%s" % [currency, JSON.stringify(compendium), inventory])
	print("--- Sporewick headless autopilot ", ("PASS" if autopilot_ok else "FAIL"), " ---")
