extends Node2D

# Sporewick core loop: plant -> grow -> harvest -> combine at the Wick ->
# discover a hybrid species in the compendium.

const GROW_SECONDS := 60.0
const VERIFY_GROW_SECONDS := 1.0
const PLOT_COUNT := 4

# Real play persists to SAVE_PATH. The headless autopilot uses a separate
# path so verification runs never read or clobber a real player's save.
const SAVE_PATH := "user://savegame.json"
const VERIFY_SAVE_PATH := "user://verify_savegame.json"

const BASE_SPORES := ["Ember Cap", "Moss Puff", "Glimmer Truffle"]

# Cross-type combos discover a brand-new hybrid species. Same-type combos
# (decided this run — see STATE.md known issues) discover a "refined" tier
# of that same base spore instead of falling through to the Mystery Spore
# fallback: this rewards focusing on one spore type as a deliberate
# alternate strategy to cross-breeding variety, rather than punishing it.
const RECIPES := {
	"Ember Cap|Moss Puff": "Cindermoss Bloom",
	"Ember Cap|Glimmer Truffle": "Suncap Ember",
	"Glimmer Truffle|Moss Puff": "Duskmoss Lantern",
	"Ember Cap|Ember Cap": "Radiant Ember Cap",
	"Moss Puff|Moss Puff": "Plush Moss Puff",
	"Glimmer Truffle|Glimmer Truffle": "Gilded Truffle",
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

# Real gameplay uses GROW_SECONDS (a balanced-for-now idle timescale); the
# headless autopilot substitutes VERIFY_GROW_SECONDS so verification runs
# in seconds instead of minutes. Same growth code path either way.
var _active_grow_seconds := GROW_SECONDS
var _save_path := SAVE_PATH


func _ready() -> void:
	randomize()

	var args := OS.get_cmdline_user_args()
	var is_verify := args.has("--verify")
	if is_verify:
		_active_grow_seconds = VERIFY_GROW_SECONDS
		_save_path = VERIFY_SAVE_PATH
		# Start every verification run from a clean slate so it's
		# deterministic regardless of what a prior run left on disk.
		if FileAccess.file_exists(_save_path):
			DirAccess.open("user://").remove(_save_path.get_file())

	for i in range(PLOT_COUNT):
		plots.append({"state": PlotState.EMPTY, "spore_type": "", "timer": 0.0})

	if not is_verify:
		_load_game()

	_build_ui()
	_refresh_ui()

	if is_verify:
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
			if plot.timer >= _active_grow_seconds:
				plot.state = PlotState.READY
				changed = true
	if changed:
		_refresh_ui()


func plant_at(i: int, forced_type: String = "") -> bool:
	if plots[i].state != PlotState.EMPTY:
		return false
	plots[i].state = PlotState.GROWING
	plots[i].spore_type = forced_type if forced_type != "" else BASE_SPORES[randi() % BASE_SPORES.size()]
	plots[i].timer = 0.0
	_refresh_ui()
	_save_game()
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
	_save_game()
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
	_save_game()
	return true


# --- Persistence ---
# Saves after every state-changing action rather than on a timer/on-quit
# hook: simpler, and correct even if the app is killed without a clean exit
# (mobile OSes do this routinely to backgrounded apps).

func _save_game() -> void:
	var plot_data := []
	for plot in plots:
		plot_data.append({
			"state": plot.state,
			"spore_type": plot.spore_type,
			"timer": plot.timer,
		})
	var data := {
		"currency": currency,
		"inventory": inventory,
		"compendium": compendium,
		"plots": plot_data,
		"saved_at": Time.get_unix_time_from_system(),
	}
	var f := FileAccess.open(_save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()


# Reads the save file, restores state, and applies offline-progress
# catch-up for however long it's been since the save was written — so
# growth that finished while the app was closed isn't lost. Returns false
# if there was nothing to load (first run).
func _load_game() -> bool:
	if not FileAccess.file_exists(_save_path):
		return false
	var f := FileAccess.open(_save_path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	currency = parsed.get("currency", 0)
	inventory = parsed.get("inventory", [])
	compendium = parsed.get("compendium", {})

	var saved_plots: Array = parsed.get("plots", [])
	for i in range(min(PLOT_COUNT, saved_plots.size())):
		var sp = saved_plots[i]
		plots[i].state = int(sp.get("state", PlotState.EMPTY))
		plots[i].spore_type = sp.get("spore_type", "")
		plots[i].timer = float(sp.get("timer", 0.0))

	var saved_at: float = float(parsed.get("saved_at", Time.get_unix_time_from_system()))
	var elapsed: float = Time.get_unix_time_from_system() - saved_at
	if elapsed > 0.0:
		_apply_offline_elapsed(elapsed)
	return true


func _apply_offline_elapsed(elapsed: float) -> void:
	for plot in plots:
		if plot.state == PlotState.GROWING:
			plot.timer += elapsed
			if plot.timer >= _active_grow_seconds:
				plot.state = PlotState.READY


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
				var pct := int(100.0 * plot.timer / _active_grow_seconds)
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

	_assert(plant_at(0, "Ember Cap"), "plant plot 0 (Ember Cap)")
	_assert(plant_at(1, "Moss Puff"), "plant plot 1 (Moss Puff)")
	await _screenshot(outdir, "01_planted")

	await get_tree().create_timer(_active_grow_seconds + 0.5).timeout
	_assert(plots[0].state == PlotState.READY, "plot 0 grew to ready")
	_assert(plots[1].state == PlotState.READY, "plot 1 grew to ready")
	await _screenshot(outdir, "02_grown")

	_assert(harvest_at(0), "harvest plot 0")
	_assert(harvest_at(1), "harvest plot 1")
	_assert(inventory.size() == 2, "inventory has 2 harvested spores")
	await _screenshot(outdir, "03_harvested")

	var before := compendium.size()
	_assert(combine_at_wick(), "combine cross-type pair at wick")
	_assert(compendium.has("Cindermoss Bloom"), "cross-type combo discovered the expected hybrid")
	_assert(compendium.size() == before + 1, "compendium gained a new species")
	_assert(currency > 0, "currency increased over the loop")
	await _screenshot(outdir, "04_combined")

	# Exercise the same-type combo path (this run's design decision: it
	# should discover a "refined" spore, never fall through to Mystery Spore).
	_assert(plant_at(2, "Ember Cap"), "plant plot 2 (Ember Cap)")
	_assert(plant_at(3, "Ember Cap"), "plant plot 3 (Ember Cap)")
	await get_tree().create_timer(_active_grow_seconds + 0.5).timeout
	_assert(harvest_at(2), "harvest plot 2")
	_assert(harvest_at(3), "harvest plot 3")
	_assert(combine_at_wick(), "combine same-type pair at wick")
	_assert(compendium.has("Radiant Ember Cap"), "same-type combo discovered the refined spore")
	_assert(not compendium.has("Mystery Spore"), "same-type combo did not fall through to Mystery Spore")
	await _screenshot(outdir, "05_same_type_combined")

	# --- Persistence round-trip: does a fresh load restore exactly what
	# was on disk from the autosave that already fired on every action
	# above? ---
	var expected_currency := currency
	var expected_compendium := compendium.duplicate()
	var expected_inventory_size := inventory.size()
	currency = 0
	inventory = []
	compendium = {}
	for plot in plots:
		plot.state = PlotState.EMPTY
		plot.spore_type = ""
		plot.timer = 0.0
	_assert(_load_game(), "load_game reads the autosaved file back")
	_assert(currency == expected_currency, "loaded currency matches what was saved")
	_assert(compendium.size() == expected_compendium.size(), "loaded compendium matches what was saved")
	_assert(inventory.size() == expected_inventory_size, "loaded inventory matches what was saved")
	_refresh_ui()
	await _screenshot(outdir, "06_reloaded")

	# --- Offline-progress catch-up: growth that would have finished while
	# the app was closed must not be lost on the next load. ---
	_assert(plant_at(0, "Moss Puff"), "plant plot 0 for offline-catchup test")
	_assert(plots[0].state == PlotState.GROWING, "plot 0 is growing before the simulated close")

	# Back-date the autosave's timestamp to simulate the app having been
	# closed for longer than a full growth cycle, then reload.
	var f := FileAccess.open(_save_path, FileAccess.READ)
	var save_data = JSON.parse_string(f.get_as_text())
	f.close()
	save_data.saved_at = Time.get_unix_time_from_system() - (_active_grow_seconds + 5.0)
	var fw := FileAccess.open(_save_path, FileAccess.WRITE)
	fw.store_string(JSON.stringify(save_data))
	fw.close()

	_assert(_load_game(), "load_game re-reads the back-dated save")
	_assert(plots[0].state == PlotState.READY, "offline elapsed time caught the plot up to ready")
	_refresh_ui()
	await _screenshot(outdir, "07_offline_catchup")

	print("Final state: currency=%d compendium=%s inventory=%s" % [currency, JSON.stringify(compendium), inventory])
	print("--- Sporewick headless autopilot ", ("PASS" if autopilot_ok else "FAIL"), " ---")
