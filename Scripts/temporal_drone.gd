class_name TemporalDrone
extends CharacterBody2D

signal defeated(unit_name: String)

@export var chase_speed: float = 48.0
@export var max_health: int = 2
@export var display_name: String = "Temporal Drone"
var active: bool = false
var health: int = 2
var _frame_clock: float = 0.0
var _frame_index: int = 0
var _attack_clock: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var warning_label: Label = $WarningLabel

var _timeline_enabled: bool = false
var _arming_time_left: float = 0.0

func _ready() -> void:
	add_to_group("temporal_drones")
	health = max_health
	visible = false
	if warning_label:
		warning_label.visible = false
	set_physics_process(false)

func set_timeline_active(enabled: bool) -> void:
	_timeline_enabled = enabled
	active = false
	visible = enabled
	_arming_time_left = 1.8 if enabled else 0.0
	if warning_label:
		warning_label.visible = enabled
	if sprite and not enabled:
		sprite.modulate = Color.WHITE
	velocity = Vector2.ZERO
	set_physics_process(enabled)

func reset_for_encounter() -> void:
	health = max_health
	_attack_clock = 0.0
	_frame_clock = 0.0
	_frame_index = 0
	_timeline_enabled = false
	_arming_time_left = 0.0
	active = false
	visible = false
	velocity = Vector2.ZERO
	if sprite:
		sprite.region_rect.position.x = 0.0
		sprite.modulate = Color.WHITE
	if warning_label:
		warning_label.visible = false
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	_frame_clock += delta
	_attack_clock = maxf(0.0, _attack_clock - delta)
	if _frame_clock >= 0.14:
		_frame_clock = 0.0
		_frame_index = (_frame_index + 1) % 4
		sprite.region_rect.position.x = float(_frame_index * 32)
	if _arming_time_left > 0.0:
		var dialogue_ui := get_tree().get_first_node_in_group("dialogue_box") as DialogueUI
		if dialogue_ui and dialogue_ui.is_active():
			velocity = Vector2.ZERO
			return
		_arming_time_left = maxf(0.0, _arming_time_left - delta)
		var warning_phase := int(_arming_time_left * 8.0) % 2 == 0
		sprite.modulate = Color(1.55, 1.18, 0.62, 1.0) if warning_phase else Color.WHITE
		if _arming_time_left <= 0.0:
			active = _timeline_enabled
			sprite.modulate = Color.WHITE
			if warning_label:
				warning_label.visible = false
		return
	if not _timeline_enabled:
		return
	active = true
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var offset := player.global_position - global_position
		velocity = offset.normalized() * chase_speed if offset.length() > 20.0 else Vector2.ZERO
		move_and_slide()
		if offset.length() < 27.0 and _attack_clock <= 0.0 and player.has_method("take_damage"):
			_attack_clock = 1.0
			player.call("take_damage")

func take_pulse() -> void:
	health -= 1
	modulate = Color(1.4, 2.0, 2.2, 1.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		set_timeline_active(false)
		defeated.emit(display_name)
