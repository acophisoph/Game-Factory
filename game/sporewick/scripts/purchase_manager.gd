extends Node

# --- RevenueCat integration (run #4) ---
#
# Wraps the "GodotxRevenueCat" native plugin (MIT license,
# https://github.com/godot-x/revenuecat — see ASSET_LOG.md) behind a stable
# API so main.gd never has to know whether it's talking to the real native
# SDK or a stand-in.
#
# That native plugin ships as an iOS .xcframework / Android .aar and
# "functions exclusively on iOS and Android exports" (its own docs) — it
# cannot load or run under a desktop/Linux build, which is all this sandbox
# can execute. So the plugin's binaries are deliberately NOT vendored into
# this repo yet (see STATE.md for what a human still needs to do to ship
# with it for real). Until then, and for every headless-verify run, this
# singleton runs in "stub mode": same method names and signals as the real
# plugin's documented API, but purchases resolve locally and instantly
# instead of talking to App Store/Play/RevenueCat's servers. Stub mode is
# also what runs in the Godot editor/desktop during normal development.
#
# When the real addon is installed and exported for iOS/Android, this file
# only needs its `_native` detection to find the singleton — no caller in
# main.gd needs to change.

signal offerings_ready(offering_id: String, packages: Array)
signal purchase_result(package_id: String, success: bool, info: Dictionary)
signal customer_info_changed(info: Dictionary)

const NATIVE_SINGLETON_NAME := "GodotxRevenueCat"

const OFFERING_ID := "default"
const PACKAGE_SUBSCRIPTION := "wicks_blessing_monthly"
const PACKAGE_SPORE_PACK := "spore_pack_small"
const ENTITLEMENT_BLESSING := "wicks_blessing"

var _native = null
var _stub_entitlements := {}

var is_stub_mode: bool:
	get: return _native == null


func _ready() -> void:
	if Engine.has_singleton(NATIVE_SINGLETON_NAME):
		_native = Engine.get_singleton(NATIVE_SINGLETON_NAME)
		_native.connect("customer_info_changed", Callable(self, "_on_native_customer_info_changed"))
		_native.connect("purchase_result", Callable(self, "_on_native_purchase_result"))
		_native.connect("offerings", Callable(self, "_on_native_offerings"))


# api_key comes from a human-managed config, not this repo — see STATE.md.
# In stub mode this is a no-op (nothing to authenticate).
func initialize(api_key: String) -> void:
	if not is_stub_mode:
		_native.initialize(api_key, "", true)


func has_entitlement(entitlement_id: String) -> bool:
	if not is_stub_mode:
		return _native.has_entitlement(entitlement_id)
	return _stub_entitlements.get(entitlement_id, false)


func fetch_offerings() -> void:
	if not is_stub_mode:
		_native.fetch_offerings()
		return
	# Canned offering matching the two products this game actually sells,
	# so UI code and the headless autopilot can exercise the real fetch ->
	# display path without a network call.
	var packages := [
		{"id": PACKAGE_SUBSCRIPTION, "title": "Wick's Blessing", "description": "Doubles spore growth speed while active.", "price": "$2.99/mo"},
		{"id": PACKAGE_SPORE_PACK, "title": "Spore Pack", "description": "Instantly adds 3 spores to your inventory.", "price": "$1.99"},
	]
	# Deferred so a caller that does `await Purchases.offerings_ready` right
	# after calling fetch_offerings() (the natural pattern for a real,
	# genuinely async network call) doesn't miss an emission that already
	# fired earlier in the same call stack.
	call_deferred("_emit_offerings_ready", OFFERING_ID, packages)


# forced_spore_types lets the headless autopilot make the spore-pack grant
# deterministic, the same pattern main.gd's plant_at() already uses for
# forced_type — it still runs the real purchase/grant code path, only the
# RNG pick is bypassed.
func purchase_package(offering_id: String, package_id: String, forced_spore_types: Array = []) -> void:
	if not is_stub_mode:
		_native.purchase_package(offering_id, package_id)
		return

	# Stub purchases always "succeed" — this sandbox can't reach a real
	# store, so failure-path handling (declined card, cancelled sheet,
	# network error) is untested here and flagged in STATE.md for
	# on-device testing once the real plugin is wired in.
	var info := {}
	match package_id:
		PACKAGE_SUBSCRIPTION:
			_stub_entitlements[ENTITLEMENT_BLESSING] = true
			info = {"entitlement": ENTITLEMENT_BLESSING, "active": true}
			call_deferred("_emit_customer_info_changed", info)
		PACKAGE_SPORE_PACK:
			var granted: Array = forced_spore_types.duplicate()
			while granted.size() < 3:
				granted.append(["Ember Cap", "Moss Puff", "Glimmer Truffle"][randi() % 3])
			info = {"granted_spores": granted}
		_:
			call_deferred("_emit_purchase_result", package_id, false, {"error": "unknown package_id"})
			return
	# Deferred for the same reason as offerings_ready above: a caller that
	# calls purchase_package() and then `await`s purchase_result in the
	# next statement (the natural pattern for a real async purchase sheet)
	# must not miss an emission that already happened earlier in the same
	# call stack.
	call_deferred("_emit_purchase_result", package_id, true, info)


func restore_purchases() -> void:
	if not is_stub_mode:
		_native.restore_purchases()
		return
	call_deferred("_emit_customer_info_changed", {"restored": true, "entitlements": _stub_entitlements.duplicate()})


func _on_native_customer_info_changed(info: Dictionary) -> void:
	customer_info_changed.emit(info)


func _on_native_purchase_result(package_id: String, success: bool, info: Dictionary) -> void:
	purchase_result.emit(package_id, success, info)


func _on_native_offerings(offering_id: String, packages: Array) -> void:
	offerings_ready.emit(offering_id, packages)


# --- Deferred-emit helpers (stub mode only) ---
# call_deferred() needs a plain method name to invoke, it can't target a
# Signal's .emit() directly, hence these tiny wrappers.

func _emit_offerings_ready(offering_id: String, packages: Array) -> void:
	offerings_ready.emit(offering_id, packages)


func _emit_purchase_result(package_id: String, success: bool, info: Dictionary) -> void:
	purchase_result.emit(package_id, success, info)


func _emit_customer_info_changed(info: Dictionary) -> void:
	customer_info_changed.emit(info)
