class_name MainTimeSlipManager
extends Node2D

## Manages 2096 vs 2146 timeline state, portal triggers, and audio-visual warp feedback.

enum TimelineState {
	OPERATIONAL_2096,
	DECAYED_RUINS_2146
}

enum CombatPhase {
	IDLE,
	OPENING_PAIR,
	SINGLE_DRONES,
	CHRONO_WARDEN,
	CLEARED
}

const TEMPORAL_DRONE_SCENE: PackedScene = preload("res://Scenes/Enemies/temporal_drone.tscn")
const SINGLE_DRONE_SPAWNS: Array[Vector2] = [Vector2(520.0, 260.0), Vector2(560.0, 220.0)]

signal timeline_changed(label: String)

@export var current_timeline: TimelineState = TimelineState.OPERATIONAL_2096

@onready var world_2096: TileMapLayer = $World_2096
@onready var world_2096_props: TileMapLayer = $World_2096_Props
@onready var world_2146: TileMapLayer = $World_2146
@onready var player: CharacterBody2D = $Player
@onready var nexus_portal: Area2D = $NexusPortal
@onready var last_door_trigger: Area2D = $LastDoorTrigger
@onready var door_cutscene: CanvasLayer = $DoorTransitionCutscene
@onready var jungle_sector: Node2D = $Room_Jungle_Waterfall
@onready var quest_manager: QuestManager = $QuestItems

var _is_transitioning: bool = false
var _has_won: bool = false
var _future_enemies_defeated: int = 0
var future_enemies_cleared: bool = false
var victory_complete: bool = false
var _combat_phase: CombatPhase = CombatPhase.IDLE
var _combat_waves_started: bool = false
var _remaining_in_wave: int = 0
var _single_drone_spawns: int = 0
var _current_wave_enemies: Array[TemporalDrone] = []

@onready var opening_drone_a: TemporalDrone = $TemporalDroneA
@onready var opening_drone_b: TemporalDrone = $TemporalDroneB
@onready var chrono_warden: TemporalDrone = $ChronoWarden

func _ready() -> void:
	# Every new run begins in the lab's present timeline, regardless of editor preview state.
	current_timeline = TimelineState.OPERATIONAL_2096
	_apply_timeline_state(current_timeline)
	
	if nexus_portal:
		nexus_portal.body_entered.connect(_on_portal_entered)
	if jungle_sector:
		var jungle_portal := jungle_sector.get_node_or_null("NexusPortal") as Area2D
		if jungle_portal and not jungle_portal.body_entered.is_connected(_on_jungle_portal_entered):
			jungle_portal.body_entered.connect(_on_jungle_portal_entered)
	if player and player.has_signal("phase_slip_requested"):
		player.phase_slip_requested.connect(_on_player_phase_slip)
	if quest_manager:
		quest_manager.all_stabilizers_assembled.connect(_on_all_stabilizers_assembled)
	for enemy_node in get_tree().get_nodes_in_group("temporal_drones"):
		var enemy := enemy_node as Node
		if enemy and enemy.has_signal("defeated"):
			enemy.connect("defeated", _on_future_enemy_defeated)


func _on_all_stabilizers_assembled() -> void:
	trigger_timeline_switch(TimelineState.DECAYED_RUINS_2146)

func on_player_respawned() -> void:
	_future_enemies_defeated = 0
	future_enemies_cleared = false
	_combat_phase = CombatPhase.IDLE
	_combat_waves_started = false
	_remaining_in_wave = 0
	_single_drone_spawns = 0
	_current_wave_enemies.clear()
	for enemy_node in get_tree().get_nodes_in_group("temporal_drones"):
		var enemy := enemy_node as TemporalDrone
		if not enemy:
			continue
		enemy.set_timeline_active(false)
		if enemy == opening_drone_a or enemy == opening_drone_b or enemy == chrono_warden:
			enemy.reset_for_encounter()
		else:
			enemy.queue_free()

func _start_opening_pair() -> void:
	_combat_waves_started = true
	_combat_phase = CombatPhase.OPENING_PAIR
	_future_enemies_defeated = 0
	_single_drone_spawns = 0
	_remaining_in_wave = 2
	_current_wave_enemies.clear()
	_current_wave_enemies.append(opening_drone_a)
	_current_wave_enemies.append(opening_drone_b)
	_activate_current_wave()

func _spawn_single_drone_wave(spawn_index: int) -> void:
	_combat_phase = CombatPhase.SINGLE_DRONES
	_remaining_in_wave = 1
	_current_wave_enemies.clear()
	var drone := TEMPORAL_DRONE_SCENE.instantiate() as TemporalDrone
	if not drone:
		return
	drone.name = "PursuitDroneWave" + str(spawn_index + 1)
	drone.display_name = "Pursuit Drone"
	drone.max_health = 2
	drone.chase_speed = 48.0
	drone.position = SINGLE_DRONE_SPAWNS[spawn_index]
	drone.defeated.connect(_on_future_enemy_defeated)
	add_child(drone)
	_current_wave_enemies.append(drone)
	_activate_current_wave()
	_show_dialogue("INCOMING SIGNATURE", [
		"Wave %d: one pursuit drone is approaching." % (spawn_index + 2),
		"Aim with the mouse and hold F or left-click to pulse."
	])

func _spawn_chrono_warden() -> void:
	_combat_phase = CombatPhase.CHRONO_WARDEN
	_remaining_in_wave = 1
	_current_wave_enemies.clear()
	chrono_warden.reset_for_encounter()
	chrono_warden.display_name = "Chrono Warden"
	chrono_warden.max_health = 5
	chrono_warden.chase_speed = 34.0
	_current_wave_enemies.append(chrono_warden)
	_activate_current_wave()
	_show_dialogue("CHRONO WARDEN", [
		"The Chrono Warden is entering the field.",
		"Keep your distance, aim with the mouse, and land five pulses."
	])

func _activate_current_wave() -> void:
	var can_fight: bool = current_timeline == TimelineState.DECAYED_RUINS_2146 and quest_manager != null and quest_manager.collected_count >= 4 and not future_enemies_cleared
	for enemy_node in get_tree().get_nodes_in_group("temporal_drones"):
		var enemy := enemy_node as TemporalDrone
		if enemy:
			enemy.set_timeline_active(can_fight and _current_wave_enemies.has(enemy))

func _activate_no_enemies() -> void:
	for enemy_node in get_tree().get_nodes_in_group("temporal_drones"):
		var enemy := enemy_node as TemporalDrone
		if enemy:
			enemy.set_timeline_active(false)

func _show_dialogue(speaker: String, lines: Array[String]) -> void:
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box") as DialogueUI
	if dialogue_box:
		dialogue_box.start_dialogue(speaker, lines)

func _on_future_enemy_defeated(_unit_name: String) -> void:
	_future_enemies_defeated += 1
	_remaining_in_wave = maxi(0, _remaining_in_wave - 1)
	if _remaining_in_wave > 0:
		return
	match _combat_phase:
		CombatPhase.OPENING_PAIR:
			_spawn_single_drone_wave(0)
		CombatPhase.SINGLE_DRONES:
			_single_drone_spawns += 1
			if _single_drone_spawns < 2:
				_spawn_single_drone_wave(_single_drone_spawns)
			else:
				_spawn_chrono_warden()
		CombatPhase.CHRONO_WARDEN:
			_combat_phase = CombatPhase.CLEARED
			future_enemies_cleared = true
			_current_wave_enemies.clear()
			_show_dialogue("REPAIR TASK", [
				"All four pursuit drones and the Chrono Warden are down.",
				"TASK: Speak with Dr. Aris, assemble the Chronos Matrix at the Loom, then activate the Nexus Portal.",
				"This restores the laboratory and secures the surviving timeline branches."
			])

func _on_player_phase_slip() -> void:
	if _is_transitioning or _has_won:
		return
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box") as DialogueUI
	if dialogue_box and dialogue_box.is_active():
		dialogue_box.close_dialogue()
	var new_timeline := TimelineState.DECAYED_RUINS_2146 if current_timeline == TimelineState.OPERATIONAL_2096 else TimelineState.OPERATIONAL_2096
	trigger_timeline_switch(new_timeline)

func return_player_to_lab() -> void:
	if _is_transitioning or not player:
		return
	_is_transitioning = true
	if jungle_sector:
		jungle_sector.visible = false
	if SoundManager:
		SoundManager.play_teleport()
		SoundManager.stop_jungle_ambient()
		SoundManager.stop_waterfall()
	_apply_timeline_state(TimelineState.OPERATIONAL_2096)
	player.global_position = Vector2(80.0, 80.0)
	player.velocity = Vector2.ZERO
	player.call("set_safe_position", player.global_position)
	_is_transitioning = false

func _on_jungle_portal_entered(body: Node2D) -> void:
	if body == player and jungle_sector and jungle_sector.visible:
		return_player_to_lab()

func _on_portal_entered(body: Node2D) -> void:
	if body != player or _has_won:
		return
	var loom_ui := get_node_or_null("LoomTerminalUI") as LoomTerminalUI
	var has_matrix: bool = loom_ui != null and loom_ui.inventory_data.has("ChronosMatrix")
	if has_matrix:
		if future_enemies_cleared:
			_trigger_victory()
		else:
			var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
			if dialogue_box and dialogue_box.has_method("start_dialogue"):
				dialogue_box.call("start_dialogue", "PORTAL LOCKED", [
					"The Chronos Matrix is ready, but the future branch is still under attack.",
					"Finish the four drone waves and defeat the Chrono Warden before securing the timeline branches."
				])
		return
	if not _is_transitioning:
		var new_timeline := TimelineState.DECAYED_RUINS_2146 if current_timeline == TimelineState.OPERATIONAL_2096 else TimelineState.OPERATIONAL_2096
		trigger_timeline_switch(new_timeline)


func trigger_timeline_switch(target_state: TimelineState) -> void:
	if _has_won or _is_transitioning:
		return
	_is_transitioning = true
	if SoundManager:
		SoundManager.play_phase_slip()

	var tween := create_tween()
	# Chromatic warp flash
	tween.tween_property(self, "modulate", Color(1.8, 1.2, 2.5, 1.0), 0.15)
	tween.tween_callback(func() -> void: _apply_timeline_state(target_state))
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	tween.tween_callback(func() -> void: _is_transitioning = false)

func _apply_timeline_state(state: TimelineState) -> void:
	current_timeline = state
	var is_2096 := (state == TimelineState.OPERATIONAL_2096)

	if world_2096:
		world_2096.visible = is_2096
		world_2096.collision_enabled = is_2096
	if world_2096_props:
		world_2096_props.visible = is_2096
		world_2096_props.collision_enabled = is_2096

	if world_2146:
		world_2146.visible = not is_2096
		world_2146.collision_enabled = not is_2096
		world_2146.modulate = Color(0.78, 0.92, 0.88, 1.0) if not is_2096 else Color.WHITE
	var combat_ready: bool = not is_2096 and quest_manager != null and quest_manager.collected_count >= 4 and not future_enemies_cleared
	if combat_ready and not _combat_waves_started:
		_start_opening_pair()
	elif combat_ready:
		_activate_current_wave()
	else:
		_activate_no_enemies()

	# Update waterfall and jungle sector state
	if jungle_sector and jungle_sector.has_method("set_timeline_state"):
		jungle_sector.call("set_timeline_state", not is_2096)
	elif jungle_sector and jungle_sector.has_node("Waterfall"):
		var wf: Node2D = jungle_sector.get_node("Waterfall")
		if wf.has_method("set_timeline_state"):
			wf.call("set_timeline_state", not is_2096)
	timeline_changed.emit("2096 PRESENT" if is_2096 else "2146 FUTURE")
	call_deferred("_keep_player_inside_playable_map")

func is_position_on_playable_tile(world_position: Vector2) -> bool:
	if jungle_sector and jungle_sector.visible:
		var jungle_local := jungle_sector.to_local(world_position)
		if Rect2(Vector2(16.0, 16.0), Vector2(608.0, 448.0)).has_point(jungle_local):
			return true
	var active_map := world_2096 if current_timeline == TimelineState.OPERATIONAL_2096 else world_2146
	if not active_map:
		return false
	var local_point := active_map.to_local(world_position)
	var cell := active_map.local_to_map(local_point)
	# The authored map cells define the playable boundary; only furniture uses
	# TileSet physics, so wall art remains passable as requested.
	return active_map.get_cell_source_id(cell) >= 0

func _keep_player_inside_playable_map() -> void:
	await get_tree().physics_frame
	if player and not is_position_on_playable_tile(player.global_position):
		var start := player.global_position
		for radius in range(8, 129, 8):
			for direction_index in range(16):
				var candidate := start + Vector2.from_angle(TAU * float(direction_index) / 16.0) * float(radius)
				if is_position_on_playable_tile(candidate):
					player.global_position = candidate
					player.velocity = Vector2.ZERO
					player.call("set_safe_position", candidate)
					return
		player.global_position = Vector2(80.0, 80.0)
		player.velocity = Vector2.ZERO
		player.call("set_safe_position", player.global_position)

func _trigger_victory() -> void:
	if _has_won:
		return
	_has_won = true
	victory_complete = true
	_is_transitioning = true
	if jungle_sector:
		jungle_sector.visible = false
	_apply_timeline_state(TimelineState.OPERATIONAL_2096)
	if player:
		player.velocity = Vector2.ZERO
		player.global_position = Vector2(160.0, 136.0)
		player.call("set_safe_position", player.global_position)
	_is_transitioning = false
	if SoundManager:
		SoundManager.play_victory()
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box and dialogue_box.has_method("start_dialogue"):
		dialogue_box.call("start_dialogue", "DR. ARIS", [
			"Thank you. The laboratory systems are working again, and the drones are offline.",
			"The Chronos Matrix has stabilized the 2146 branch and sealed the temporal rupture.",
			"All surviving timeline branches are safe. You brought everyone home.",
			"The Chronos project is complete."
		])
