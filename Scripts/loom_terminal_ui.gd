class_name LoomTerminalUI
extends CanvasLayer

## Interactive Crafting and Temporal Loom Terminal inspired by classic 16-bit RPGs.
## Replicates the 3-panel layout: Category Tabs & Inventory, 3x3 Assembly Matrix, and Description Card.

signal item_crafted(item_name: String)
signal terminal_closed

enum TabCategory {
	FORGE,
	ALCHEMY,
	LOOM
}

@export var default_tab: TabCategory = TabCategory.LOOM

# Nodes
@onready var root_control: Control = $Root
@onready var close_button: Button = $Root/WindowFrame/HeaderTab/CloseButton
@onready var tab_forge_btn: Button = $Root/WindowFrame/MainHBox/LeftSection/TabHBox/TabForge
@onready var tab_alchemy_btn: Button = $Root/WindowFrame/MainHBox/LeftSection/TabHBox/TabAlchemy
@onready var tab_loom_btn: Button = $Root/WindowFrame/MainHBox/LeftSection/TabHBox/TabLoom

@onready var inventory_grid: GridContainer = $Root/WindowFrame/MainHBox/LeftSection/InventoryGrid
@onready var craft_grid: GridContainer = $Root/WindowFrame/MainHBox/CenterSection/CraftGrid
@onready var tutorial_label: Label = $Root/WindowFrame/MainHBox/LeftSection/TutorialLabel
@onready var tab_row: HBoxContainer = $Root/WindowFrame/MainHBox/LeftSection/TabHBox
@onready var inventory_nav: HBoxContainer = $Root/WindowFrame/MainHBox/LeftSection/NavRow
@onready var create_button: Button = $Root/WindowFrame/MainHBox/CenterSection/CreateButton
@onready var station_icon: TextureRect = $Root/WindowFrame/MainHBox/CenterSection/StationBox/StationIcon
@onready var result_slot: Button = $Root/WindowFrame/MainHBox/CenterSection/StationBox/ResultSlot

# Right Description Card Nodes
@onready var desc_icon: TextureRect = $Root/WindowFrame/MainHBox/RightSection/DescCard/ItemIcon
@onready var desc_name: Label = $Root/WindowFrame/MainHBox/RightSection/DescCard/ItemName
@onready var desc_lore: Label = $Root/WindowFrame/MainHBox/RightSection/DescCard/ItemLore
@onready var desc_stat1: Label = $Root/WindowFrame/MainHBox/RightSection/DescCard/Stat1
@onready var desc_stat2: Label = $Root/WindowFrame/MainHBox/RightSection/DescCard/Stat2

var current_tab: TabCategory = TabCategory.LOOM
var inventory_data: Dictionary = {}
var matrix_slots: Array[String] = []
var crafted_output: String = ""
var _committed_items: Dictionary = {}
var _restore_player_physics: bool = true
var _timeline_label: String = "2096 PRESENT"
var _collected_total: int = 0

# Textures
var tex_anvil: Texture2D
var tex_mortar: Texture2D
var tex_loom: Texture2D

var item_database: Dictionary = {
	"TemporalLoomCore": {
		"name": "TEMPORAL LOOM CORE",
		"category": TabCategory.LOOM,
		"icon_path": "res://Assets/UI/item_loom_core.png",
		"lore": "The pulsating heart of the Chronal Loom. Synchronizes quantum wavefunctions.",
		"stat1": "STABILITY: +25%",
		"stat2": "FLUX: 1.414 THz"
	},
	"ThroughputMultiplier": {
		"name": "THROUGHPUT MULTIPLIER",
		"category": TabCategory.LOOM,
		"icon_path": "res://Assets/UI/item_throughput.png",
		"lore": "Amplifies tachyon transfer rates across timeline fractures.",
		"stat1": "THROUGHPUT: 4.8 GB/s",
		"stat2": "STABILITY: +25%"
	},
	"AuraExtractor": {
		"name": "AURA EXTRACTOR",
		"category": TabCategory.LOOM,
		"icon_path": "res://Assets/UI/item_aura_extractor.png",
		"lore": "Distills temporal radiation into pure coherent phase potential.",
		"stat1": "FILTER EFF.: 99.2%",
		"stat2": "STABILITY: +25%"
	},
	"PhaseKey": {
		"name": "PHASE KEY",
		"category": TabCategory.LOOM,
		"icon_path": "res://Assets/UI/item_phase_key.png",
		"lore": "Ancient harmonic key recovered from the sacred jungle waterfall altar.",
		"stat1": "HARMONICS: 432 Hz",
		"stat2": "STABILITY: +25%"
	},
	"ChronosMatrix": {
		"name": "CHRONOS MASTER MATRIX",
		"category": TabCategory.LOOM,
		"icon_path": "res://Assets/UI/item_chronos_matrix.png",
		"lore": "THE UNIFIED ANCHOR. Restores causal stability and ends the collapse!",
		"stat1": "TIMELINE INTEGRITY: 100%",
		"stat2": "PARADOX RATIO: 0.00%"
	},
	"ChronoSword": {
		"name": "CHRONO BLADE",
		"category": TabCategory.FORGE,
		"icon_path": "res://Assets/UI/item_sword.png",
		"lore": "Tempered alloy folded across two centuries of steel.",
		"stat1": "DAMAGE: 85 DMG",
		"stat2": "PHASE CUT: +40%"
	},
	"BronzeIngot": {
		"name": "BRONZE INGOT",
		"category": TabCategory.FORGE,
		"icon_path": "res://Assets/UI/item_bronze_ingot.png",
		"lore": "Pure copper-tin matrix, conductive to chronal fields.",
		"stat1": "PURITY: 99.9%",
		"stat2": "WEIGHT: 2.4 kg"
	},
	"CobaltIngot": {
		"name": "COBALT ALLOY",
		"category": TabCategory.FORGE,
		"icon_path": "res://Assets/UI/item_cobalt_ingot.png",
		"lore": "Heavy blue metallic ingot used in temporal radiation shielding.",
		"stat1": "HARDNESS: 8.5 MOH",
		"stat2": "SHIELDING: +35"
	},
	"ChronoElixir": {
		"name": "TIMELINE ELIXIR",
		"category": TabCategory.ALCHEMY,
		"icon_path": "res://Assets/UI/item_potion_blue.png",
		"lore": "Sublime distillation of glowing chronal vapor and deep moss.",
		"stat1": "RESTORATION: +100 HP",
		"stat2": "SLIP ENERGY: +50%"
	},
	"BlueCrystal": {
		"name": "TACHYON CRYSTAL",
		"category": TabCategory.ALCHEMY,
		"icon_path": "res://Assets/UI/item_crystal.png",
		"lore": "Resonating mineral formed by the waterfall's continuous time shear.",
		"stat1": "RESONANCE: 98.7%",
		"stat2": "ENERGY: 450 J"
	},
	"ChronoBoots": {
		"name": "PHASE STRIDE BOOTS",
		"category": TabCategory.LOOM,
		"icon_path": "res://Assets/UI/item_boots.png",
		"lore": "Spun from temporal threads to allow swift traverse across rough terrain.",
		"stat1": "MOVE SPEED: +30%",
		"stat2": "CLIFF GRIP: MAX"
	}
}

@onready var hud_button: Button = $HUDButton
@onready var quest_status: Label = $StatusFrame/QuestStatus
@onready var player_controller: CharacterBody2D = get_node_or_null("../Player") as CharacterBody2D

func _ready() -> void:
	add_to_group("loom_ui")
	layer = 80
	if root_control:
		root_control.visible = false
	if tab_row:
		tab_row.visible = false
	if inventory_grid:
		inventory_grid.visible = false
	if inventory_nav:
		inventory_nav.visible = false
	if craft_grid:
		craft_grid.columns = 2
	
	tex_anvil = load("res://Assets/UI/station_anvil.png")
	tex_mortar = load("res://Assets/UI/station_mortar.png")
	tex_loom = load("res://Assets/UI/station_loom.png")

	_init_matrix_slots()
	_init_inventory()

	if hud_button:
		hud_button.pressed.connect(toggle)
	if close_button:
		close_button.pressed.connect(close)
	if tab_forge_btn:
		tab_forge_btn.pressed.connect(func() -> void: select_tab(TabCategory.FORGE))
	if tab_alchemy_btn:
		tab_alchemy_btn.pressed.connect(func() -> void: select_tab(TabCategory.ALCHEMY))
	if tab_loom_btn:
		tab_loom_btn.pressed.connect(func() -> void: select_tab(TabCategory.LOOM))
	if create_button:
		create_button.pressed.connect(_on_create_pressed)

	if SoundManager:
		SoundManager.hook_buttons(self)
	call_deferred("_connect_quest_manager")
	select_tab(default_tab)
	_update_tutorial()

func _connect_quest_manager() -> void:
	var quest_manager := get_tree().get_first_node_in_group("quest_manager") as QuestManager
	if quest_manager:
		if not quest_manager.item_collected.is_connected(_on_quest_item_collected):
			quest_manager.item_collected.connect(_on_quest_item_collected)
		_on_quest_item_collected("", quest_manager.collected_count)
	var time_manager := get_parent() as MainTimeSlipManager
	if time_manager:
		if not time_manager.timeline_changed.is_connected(_on_timeline_changed):
			time_manager.timeline_changed.connect(_on_timeline_changed)
		_on_timeline_changed("2096 PRESENT" if time_manager.current_timeline == MainTimeSlipManager.TimelineState.OPERATIONAL_2096 else "2146 FUTURE")

func _on_quest_item_collected(_item_name: String, total_collected: int) -> void:
	_collected_total = total_collected
	_update_status_label()
	_update_tutorial()
	if _item_name != "" and not _committed_items.has(_item_name):
		inventory_data[_item_name] = 1
		if root_control and root_control.visible:
			_refresh_craft_grid()
			_refresh_inventory_grid()

func _on_timeline_changed(label: String) -> void:
	_timeline_label = label
	_update_status_label()

func _update_status_label() -> void:
	var shield := 3
	var controller := player_controller as PlayerController
	if controller:
		shield = controller.health
	if quest_status:
		quest_status.text = "STABILIZERS  %d / %d\nTIME  %s\nSHIELD  %d / 3" % [_collected_total, QuestManager.REQUIRED_ITEMS, _timeline_label, shield]

func _update_tutorial() -> void:
	if not tutorial_label:
		return
	var quest_manager := get_tree().get_first_node_in_group("quest_manager") as QuestManager
	var lines: Array[String] = ["LOOM GUIDE", "Collect these four parts:"]
	var items: Array[String] = ["TemporalLoomCore", "ThroughputMultiplier", "AuraExtractor", "PhaseKey"]
	var names: Array[String] = ["Loom Core", "Throughput", "Aura Extractor", "Phase Key"]
	var found := 0
	for index in range(items.size()):
		var has_item := quest_manager != null and bool(quest_manager.collected_items.get(items[index], false))
		if has_item:
			found += 1
		lines.append("[x] " + names[index] if has_item else "[ ] " + names[index])
	lines.append("")
	if inventory_data.has("ChronosMatrix"):
		lines.append("Matrix built. Enter the Nexus to finish.")
	elif found >= QuestManager.REQUIRED_ITEMS:
		lines.append("Press BUILD MATRIX once, then enter the Nexus.")
	else:
		lines.append("Parts found: %d / 4" % found)
		lines.append("Open the Loom with C or Tab when all four are collected.")
	tutorial_label.text = "\n".join(lines)

func refresh_status() -> void:
	_update_status_label()

func _init_matrix_slots() -> void:
	matrix_slots.clear()
	for i in range(4):
		matrix_slots.append("")

func _init_inventory() -> void:
	inventory_data.clear()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var kc: Key = (event as InputEventKey).keycode
		var pkc: Key = (event as InputEventKey).physical_keycode
		if kc == KEY_TAB or kc == KEY_C or pkc == KEY_TAB or pkc == KEY_C:
			get_viewport().set_input_as_handled()
			toggle()
		elif kc == KEY_ESCAPE or pkc == KEY_ESCAPE:
			if root_control and root_control.visible:
				get_viewport().set_input_as_handled()
				close()

func open() -> void:
	if player_controller:
		_restore_player_physics = player_controller.is_physics_processing()
		player_controller.set_physics_process(false)
	var qm := get_tree().get_first_node_in_group("quest_manager") as QuestManager
	if qm:
		for item_name: String in qm.collected_items:
			if qm.collected_items[item_name] and not _committed_items.has(item_name) and not inventory_data.has(item_name) and not matrix_slots.has(item_name):
				inventory_data[item_name] = 1
	_check_recipe()
	_update_tutorial()
	if root_control:
		root_control.visible = true
	select_tab(current_tab)

func close() -> void:
	if root_control:
		root_control.visible = false
	if player_controller and _restore_player_physics:
		player_controller.set_physics_process(true)
	terminal_closed.emit()

func toggle() -> void:
	if root_control and root_control.visible:
		close()
	else:
		open()

func select_tab(tab: TabCategory) -> void:
	current_tab = tab
	
	# Update tab buttons appearance
	tab_forge_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == TabCategory.FORGE else Color(0.7, 0.78, 0.82, 0.9)
	tab_alchemy_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == TabCategory.ALCHEMY else Color(0.7, 0.78, 0.82, 0.9)
	tab_loom_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == TabCategory.LOOM else Color(0.7, 0.78, 0.82, 0.9)

	# Update station icon
	match tab:
		TabCategory.FORGE:
			station_icon.texture = tex_anvil
			_show_description("ChronoSword")
		TabCategory.ALCHEMY:
			station_icon.texture = tex_mortar
			_show_description("ChronoElixir")
		TabCategory.LOOM:
			station_icon.texture = tex_loom
			_show_description("ChronosMatrix")

	_refresh_inventory_grid()
	_refresh_craft_grid()

func _refresh_inventory_grid() -> void:
	if not inventory_grid:
		return
	for child in inventory_grid.get_children():
		child.queue_free()

	var visible_item_count: int = 0
	for item_id: String in inventory_data.keys():
		if not item_database.has(item_id):
			continue
		var data: Dictionary = item_database[item_id]
		if data["category"] != current_tab:
			continue
		visible_item_count += 1
		
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(38, 38)
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.focus_mode = Control.FOCUS_NONE

		var icon_tex := load(data["icon_path"]) as Texture2D
		if icon_tex:
			var icon_rect := TextureRect.new()
			icon_rect.texture = icon_tex
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.offset_left = 4
			icon_rect.offset_top = 4
			icon_rect.offset_right = -4
			icon_rect.offset_bottom = -4
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon_rect)

		var captured_id := item_id
		slot.pressed.connect(func() -> void:
			_show_description(captured_id)
			_place_item_in_first_free_slot(captured_id)
		)
		inventory_grid.add_child(slot)
	if visible_item_count == 0:
		var empty_label := Label.new()
		empty_label.custom_minimum_size = Vector2(165, 72)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.modulate = Color(0.28, 0.36, 0.41, 1.0)
		empty_label.text = "No components here yet. Explore the facility and forest to find stabilizers."
		inventory_grid.add_child(empty_label)

func _refresh_craft_grid() -> void:
	if not craft_grid:
		return
	for child in craft_grid.get_children():
		child.queue_free()
	_check_recipe()

	for i in range(4):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(38, 38)

		var item_id := matrix_slots[i]
		if item_id != "" and item_database.has(item_id):
			var data: Dictionary = item_database[item_id]
			var icon_tex := load(data["icon_path"]) as Texture2D
			if icon_tex:
				var icon_rect := TextureRect.new()
				icon_rect.texture = icon_tex
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
				icon_rect.offset_left = 4
				icon_rect.offset_top = 4
				icon_rect.offset_right = -4
				icon_rect.offset_bottom = -4
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(icon_rect)

		craft_grid.add_child(slot)

func _place_item_in_first_free_slot(item_id: String) -> void:
	if int(inventory_data.get(item_id, 0)) <= 0:
		return
	for i in range(4):
		if matrix_slots[i] == "":
			matrix_slots[i] = item_id
			inventory_data[item_id] = int(inventory_data[item_id]) - 1
			if int(inventory_data[item_id]) <= 0:
				inventory_data.erase(item_id)
			break
	_refresh_craft_grid()
	_refresh_inventory_grid()

func _show_description(item_id: String) -> void:
	if not item_database.has(item_id):
		return
	var d: Dictionary = item_database[item_id]
	desc_name.text = d["name"]
	desc_lore.text = d["lore"]
	desc_stat1.text = d["stat1"]
	desc_stat2.text = d["stat2"]
	var tex := load(d["icon_path"]) as Texture2D
	if tex:
		desc_icon.texture = tex

func _check_recipe() -> void:
	var ingredients: Array[String] = ["TemporalLoomCore", "ThroughputMultiplier", "AuraExtractor", "PhaseKey"]
	var quest_manager := get_tree().get_first_node_in_group("quest_manager") as QuestManager
	var found := 0
	for index in range(ingredients.size()):
		var ingredient: String = ingredients[index]
		var has_ingredient := int(inventory_data.get(ingredient, 0)) > 0 or matrix_slots.has(ingredient)
		if quest_manager:
			has_ingredient = has_ingredient or bool(quest_manager.collected_items.get(ingredient, false))
		matrix_slots[index] = ingredient if has_ingredient else ""
		if has_ingredient:
			found += 1
	if inventory_data.has("ChronosMatrix"):
		crafted_output = ""
		create_button.text = "MATRIX BUILT"
		create_button.disabled = true
		if tutorial_label:
			tutorial_label.text = "LOOM GUIDE\nMatrix built. Enter the Nexus portal to finish."
		_set_result_icon("res://Assets/UI/item_chronos_matrix.png")
		return
	if found == ingredients.size():
		crafted_output = "ChronosMatrix"
		create_button.text = "BUILD CHRONOS MATRIX"
		create_button.disabled = false
		create_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_set_result_icon("res://Assets/UI/item_chronos_matrix.png")
	else:
		crafted_output = ""
		create_button.text = "COLLECT %d / 4 PARTS" % found
		create_button.disabled = true
		create_button.modulate = Color(0.7, 0.7, 0.7, 0.8)
		_set_result_icon("res://Assets/UI/item_chronos_matrix.png")

func _set_result_icon(path: String) -> void:
	for c in result_slot.get_children():
		c.queue_free()
	var tex := load(path) as Texture2D
	if tex:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_slot.add_child(r)

func _clear_result_icon() -> void:
	for c in result_slot.get_children():
		c.queue_free()

func _on_create_pressed() -> void:
	_check_recipe()
	if crafted_output == "":
		return
	
	if SoundManager:
		SoundManager.play_craft()
	print("[LoomTerminalUI] Successfully crafted: ", crafted_output)
	inventory_data[crafted_output] = 1
	item_crafted.emit(crafted_output)
	_show_description(crafted_output)

	if crafted_output == "ChronosMatrix":
		for ingredient: String in ["TemporalLoomCore", "ThroughputMultiplier", "AuraExtractor", "PhaseKey"]:
			_committed_items[ingredient] = true
			inventory_data.erase(ingredient)
		for i in range(matrix_slots.size()):
			matrix_slots[i] = ""
		crafted_output = ""
		_refresh_craft_grid()
		_refresh_inventory_grid()
		var quest_mgr := get_tree().get_first_node_in_group("quest_manager") as QuestManager
		if quest_mgr:
			quest_mgr.all_stabilizers_assembled.emit()
			quest_mgr.call("_trigger_timeline_stabilization_banner")
		close()
