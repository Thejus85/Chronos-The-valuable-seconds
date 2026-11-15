class_name JungleWaterfallZone
extends Node2D

## Controls the ancient Jungle Waterfall sector across 2096 and 2146 timelines.

signal return_to_facility_requested

@onready var bg_2096: Sprite2D = $Background2096
@onready var bg_2146: Sprite2D = $Background2146
@onready var waterfall: Node2D = $Waterfall
@onready var return_exit: Area2D = $LastDoorwayExit

var _is_transitioning: bool = false

func _ready() -> void:
	visible = false
	if return_exit:
		return_exit.body_entered.connect(_on_return_exit_entered)
	set_timeline_state(false)

func set_timeline_state(is_ruins: bool) -> void:
	if bg_2096:
		bg_2096.visible = not is_ruins
	if bg_2146:
		bg_2146.visible = is_ruins
	if waterfall and waterfall.has_method("set_timeline_state"):
		waterfall.call("set_timeline_state", is_ruins)

func _on_return_exit_entered(body: Node2D) -> void:
	if _is_transitioning:
		return
	if body.name == "Player":
		_is_transitioning = true
		var main_node := get_parent()
		var player := body as CharacterBody2D
		var cutscene := main_node.get_node_or_null("DoorTransitionCutscene") as CanvasLayer

		if player:
			player.velocity = Vector2.ZERO
			player.set_physics_process(false)

		if cutscene and cutscene.has_method("play_transition"):
			cutscene.call(
				"play_transition",
				"⚡ QUANTUM TETHER : RETURNING TO SECTOR 4 ⚡",
				"NARRATOR: Chronal stabilization sequence complete.\nRe-anchoring timeline coordinates to Chronos Facility Sector 4...",
				func() -> void:
					visible = false
					if SoundManager:
						SoundManager.stop_jungle_ambient()
						SoundManager.stop_waterfall()
					if player:
						player.global_position = Vector2(616, 160)
						player.velocity = Vector2.ZERO,
				func() -> void:
					if player:
						player.set_physics_process(true)
					_is_transitioning = false
					return_to_facility_requested.emit()
			)
		else:
			visible = false
			if SoundManager:
				SoundManager.play_teleport()
				SoundManager.stop_jungle_ambient()
				SoundManager.stop_waterfall()
			if player:
				player.global_position = Vector2(616, 160)
				player.set_physics_process(true)
			_is_transitioning = false
			return_to_facility_requested.emit()

