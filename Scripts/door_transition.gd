class_name DoorTransitionTrigger
extends Area2D

## Triggers cinematic cutscene and teleports player through Sector 4 Blast Door into the Jungle Waterfall Valley.

@export var target_marker_position: Vector2 = Vector2(1050, 260)

@onready var cutscene_player: AnimationPlayer = $"../DoorTransitionCutscene/AnimationPlayer"
@onready var player: CharacterBody2D = $"../Player"
@onready var jungle_sector: Node2D = $"../Room_Jungle_Waterfall"

var _has_triggered: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _has_triggered:
		return
	if body == player or body.name == "Player":
		_has_triggered = true
		_play_door_transition(body as CharacterBody2D)

func _play_door_transition(target_player: CharacterBody2D) -> void:
	var active_player := target_player if target_player else player
	if active_player:
		active_player.velocity = Vector2.ZERO
		active_player.set_physics_process(false)

	var cutscene_layer := get_node_or_null("../DoorTransitionCutscene") as CanvasLayer
	if cutscene_layer and cutscene_layer.has_method("play_transition"):
		cutscene_layer.call(
			"play_transition",
			"⚠ TELEPORTING : SOME ERROR IS OCCURED ⚠",
			"NARRATOR: Chronal jump anomaly! The coordinate matrix has collapsed.\nEmergency failsafe is routing the subject to the Ancient Forest.",
			func() -> void:
				if jungle_sector:
					jungle_sector.visible = true
				if active_player:
					active_player.global_position = target_marker_position
					active_player.velocity = Vector2.ZERO
				if SoundManager:
					SoundManager.start_jungle_ambient()
					SoundManager.start_waterfall(),
			func() -> void:
				if active_player:
					active_player.set_physics_process(true)
				_has_triggered = false
		)
	else:
		if SoundManager:
			SoundManager.play_teleport()
			SoundManager.start_jungle_ambient()
			SoundManager.start_waterfall()
		if jungle_sector:
			jungle_sector.visible = true
		if active_player:
			active_player.global_position = target_marker_position
			active_player.set_physics_process(true)
		_has_triggered = false

