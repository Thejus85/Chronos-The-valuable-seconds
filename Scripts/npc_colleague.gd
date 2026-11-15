extends Area2D

## Lets the time-trapped engineer explain the portal and the repair task.

@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func interact(_caller: Node2D) -> void:
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box") as DialogueUI
	if dialogue_box:
		dialogue_box.start_dialogue("ENGINEER VANCE | TIME TRAPPED", [
			"This portal caught me between the two timelines.",
			"The Chronos Matrix can bring the lab back online and make the surviving branches safe.",
			"Defeat the temporal hostiles, then speak with Dr. Aris about the repair task."
		])

func _on_area_entered(area: Area2D) -> void:
	if area.name == "InteractDetector" and prompt_label:
		prompt_label.visible = true

func _on_area_exited(area: Area2D) -> void:
	if area.name == "InteractDetector" and prompt_label:
		prompt_label.visible = false
