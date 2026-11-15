class_name QuestManager
extends Node2D

## Tracks collection of 4 Temporal Loom stabilizers and resolves 1 winning timeline vs 10 failing loops.

signal item_collected(item_name: String, total_collected: int)
signal all_stabilizers_assembled

const REQUIRED_ITEMS: int = 4

var collected_count: int = 0
var collected_items: Dictionary = {
	"TemporalLoomCore": false,
	"ThroughputMultiplier": false,
	"AuraExtractor": false,
	"PhaseKey": false
}

func _ready() -> void:
	add_to_group("quest_manager")
	# Connect items inside QuestItems
	for child in get_children():
		if child is Area2D:
			child.body_entered.connect(_on_item_body_entered.bind(child))
	
	# Connect PhaseKey in Jungle Waterfall room if present
	var jungle_key := get_node_or_null("../Room_Jungle_Waterfall/PhaseKey") as Area2D
	if jungle_key:
		jungle_key.body_entered.connect(_on_item_body_entered.bind(jungle_key))
	var intro := get_node_or_null("../BounceBackIntro") as BounceBackIntro
	if intro:
		intro.game_started.connect(_show_opening_briefing)
	else:
		call_deferred("_show_opening_briefing")

func _show_opening_briefing() -> void:
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box and dialogue_box.has_method("start_dialogue"):
		dialogue_box.call("start_dialogue", "MISSION BRIEFING", [
			"Move with WASD or the arrow keys. Press E near a person to talk.",
			"Collect the three stabilizers in the facility, then use the northern security door.",
			"The forest holds the Phase Key. Return through the glowing portal.",
			"Press Q to shift timelines. Press C or Tab to open the Loom. If a bad tile traps you, press R to return to the lab; your parts stay collected."
		])

func _on_item_body_entered(body: Node2D, item_node: Area2D) -> void:
	if body.name == "Player":
		var item_name := item_node.name
		if collected_items.has(item_name) and not collected_items[item_name]:
			collected_items[item_name] = true
			collected_count += 1
			item_collected.emit(item_name, collected_count)
			
			# Play pickup chime
			if SoundManager:
				SoundManager.play_pickup()
			
			var tween := create_tween()
			tween.tween_property(item_node, "scale", Vector2(1.5, 1.5), 0.2)
			tween.parallel().tween_property(item_node, "modulate:a", 0.0, 0.2)
			tween.tween_callback(item_node.queue_free)

			# Show item collection notice
			var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
			if dialogue_box and dialogue_box.has_method("start_dialogue"):
				var remaining := REQUIRED_ITEMS - collected_count
				if remaining > 0:
					dialogue_box.call("start_dialogue", "TEMPORAL LOOM OS", [
						"STABILIZER ACQUIRED: [" + item_name.to_upper() + "]! (" + str(collected_count) + "/4)",
						str(remaining) + " more required to stabilize the Chronal Loom."
					])
				else:
					all_stabilizers_assembled.emit()
					_trigger_timeline_stabilization_banner()

func _trigger_timeline_stabilization_banner() -> void:
	if SoundManager:
		SoundManager.play_craft()
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box and dialogue_box.has_method("start_dialogue"):
		dialogue_box.call("start_dialogue", "TEMPORAL LOOM OS", [
			"ALL 4 STABILIZERS SYNCHRONIZED!",
			"Press C or Tab to open the Craft Matrix. Enter the future with Q to begin the fight.",
			"Fight order: two pursuit drones, two single-drone waves, then the Chrono Warden.",
			"Aim with the mouse and hold F or left-click to pulse. After the fight, talk to Dr. Aris, craft the Chronos Matrix, then enter the Nexus Portal to restore the lab and secure the timeline branches."
		])
