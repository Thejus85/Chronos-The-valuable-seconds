class_name NPCDialogueController
extends CharacterBody2D

## Handles NPC interaction, hovering prompt bubble, and dispatching text to DialogueBox.

@export var npc_name: String = "Dr. Aris"
@export var npc_role: String = "Lead Temporal Physicist"
@export var initial_dialogue: Array[String] = [
	"The Temporal Loom collapsed! The timeline is desynchronizing every minute.",
	"We need all 4 Loom Stabilizers to seal the rupture: Core, Multiplier, Extractor, and the Phase Key.",
	"The Phase Key was moved to the Ancient Jungle Valley beyond the northern blast door!",
	"Head north through Sector 4 Security Gates. Hurry before the next time loop collapses!"
]
@export var completed_dialogue: Array[String] = [
	"All four stabilizers are active. The future branch is exposed.",
	"Use Q to enter the future. Clear two opening drones, two solo drones, then the Chrono Warden.",
	"Aim with the mouse and hold F or left-click to pulse. Press Q to retreat if you need to."
]
@export var patrol_distance: float = 12.0
@export var patrol_speed: float = 14.0

@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_nearby: bool = false
var _is_talking: bool = false
var _home_position: Vector2
var _patrol_direction: float = 1.0
var _patrol_pause: float = 0.0

func _ready() -> void:
	_home_position = global_position
	if prompt_label:
		prompt_label.visible = false
	if interaction_area:
		interaction_area.area_entered.connect(_on_area_entered)
		interaction_area.area_exited.connect(_on_area_exited)
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	_play_anim("idle_down")

func _play_anim(anim_name: String) -> void:
	if not sprite or not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	elif sprite.sprite_frames.has_animation("idle_down") and anim_name.begins_with("idle"):
		sprite.play("idle_down")
	elif sprite.sprite_frames.has_animation("walk_down") and anim_name.begins_with("walk"):
		sprite.play("walk_down")

func _physics_process(delta: float) -> void:
	if _player_nearby or _is_talking:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_anim("idle_down")
		return
	if _patrol_pause > 0.0:
		_patrol_pause = maxf(0.0, _patrol_pause - delta)
		velocity = Vector2.ZERO
		move_and_slide()
		_play_anim("idle_side")
		return
	var target_x: float = _home_position.x + _patrol_direction * patrol_distance
	if absf(global_position.x - target_x) < 2.0:
		_patrol_direction *= -1.0
		_patrol_pause = 0.65
		velocity = Vector2.ZERO
		_play_anim("idle_side")
		return
	velocity = Vector2(signf(target_x - global_position.x) * patrol_speed, 0.0)
	move_and_slide()
	sprite.flip_h = velocity.x < 0.0
	_play_anim("walk_side")


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		_player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func _on_area_entered(area: Area2D) -> void:
	if area.name == "InteractDetector":
		_player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_area_exited(area: Area2D) -> void:
	if area.name == "InteractDetector":
		_player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func interact(_caller: Node2D) -> void:
	if _is_talking:
		return
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
	if not dialogue_box:
		dialogue_box = get_tree().current_scene.get_node_or_null("DialogueBox")

	if dialogue_box and dialogue_box.has_method("start_dialogue"):
		_is_talking = true
		velocity = Vector2.ZERO
		if SoundManager:
			SoundManager.play_dialogue_chirp()
		var quest_manager := get_tree().get_first_node_in_group("quest_manager") as QuestManager
		var time_manager := get_tree().current_scene as MainTimeSlipManager
		var lines: Array[String] = initial_dialogue
		if time_manager and time_manager.victory_complete:
			lines = [
				"Thank you. The laboratory is working again, and all surviving timeline branches are safe.",
				"The Chronos Matrix is holding. You brought everyone home."
			]
		elif quest_manager and quest_manager.collected_count >= QuestManager.REQUIRED_ITEMS:
			if time_manager and time_manager.future_enemies_cleared:
				lines = [
					"Thank you for stopping the temporal attack.",
					"TASK: Open the Loom with C or Tab, assemble the Chronos Matrix, then activate the Nexus Portal.",
					"That will bring the laboratory back online and keep the timeline branches safe."
				]
			else:
				lines = completed_dialogue
		dialogue_box.call("start_dialogue", npc_name + " (" + npc_role + ")", lines)
		if dialogue_box is DialogueUI:
			var dialogue_ui := dialogue_box as DialogueUI
			dialogue_ui.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished() -> void:
	_is_talking = false
