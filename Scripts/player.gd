class_name PlayerController
extends CharacterBody2D

## Player controller handling 8-way movement, directional animations, and E-key interaction.

signal interacted_with(target: Node2D)
signal phase_slip_requested
signal player_died

@export var move_speed: float = 120.0
@export var sprint_speed: float = 175.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_detector: Area2D = $InteractDetector

var _facing_direction: String = "down"
var _facing_vector: Vector2 = Vector2.DOWN
var _nearby_interactables: Array[Area2D] = []
var health: int = 3
var _pulse_cooldown: float = 0.0
var _damage_cooldown: float = 0.0
var _last_safe_position: Vector2 = Vector2(80.0, 80.0)
var _recovery_key_was_down: bool = false

func _ready() -> void:
	add_to_group("player")
	_last_safe_position = global_position
	if interact_detector:
		interact_detector.area_entered.connect(_on_interact_area_entered)
		interact_detector.area_exited.connect(_on_interact_area_exited)

func _physics_process(_delta: float) -> void:
	_pulse_cooldown = maxf(0.0, _pulse_cooldown - _delta)
	_damage_cooldown = maxf(0.0, _damage_cooldown - _delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else move_speed

	if input_vector != Vector2.ZERO:
		_facing_vector = input_vector.normalized()
		velocity = input_vector * speed
		_update_walk_animation(input_vector)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		_update_idle_animation()

	move_and_slide()
	var timeline_manager := get_parent() as MainTimeSlipManager
	if timeline_manager:
		if timeline_manager.is_position_on_playable_tile(global_position):
			_last_safe_position = global_position
		else:
			global_position = _last_safe_position
			velocity = Vector2.ZERO
	if _damage_cooldown <= 0.0:
		for enemy_node in get_tree().get_nodes_in_group("temporal_drones"):
			var enemy := enemy_node as Node2D
			if enemy and enemy.get("active") == true and global_position.distance_to(enemy.global_position) < 24.0:
				take_damage()
				break

	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_box") as DialogueUI
	var dialogue_active: bool = dialogue_ui != null and dialogue_ui.is_active()
	if Input.is_action_just_pressed("interact") and not dialogue_active:
		_handle_interaction()

	if Input.is_action_just_pressed("phase_slip"):
		phase_slip_requested.emit()
	var pulse_requested: bool = Input.is_key_pressed(KEY_F) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if pulse_requested and _pulse_cooldown <= 0.0 and not dialogue_active:
		_fire_temporal_pulse()
	var recovery_key_down := Input.is_key_pressed(KEY_R)
	if recovery_key_down and not _recovery_key_was_down and not dialogue_active:
		_return_to_lab_checkpoint()
	_recovery_key_was_down = recovery_key_down

func set_safe_position(position: Vector2) -> void:
	_last_safe_position = position

func _return_to_lab_checkpoint() -> void:
	velocity = Vector2.ZERO
	var timeline_manager := get_parent() as MainTimeSlipManager
	if timeline_manager:
		timeline_manager.call("return_player_to_lab")
	else:
		global_position = Vector2(80.0, 80.0)
		_last_safe_position = global_position

func take_damage() -> void:
	if _damage_cooldown > 0.0:
		return
	health -= 1
	_refresh_health_hud()
	_damage_cooldown = 0.8
	modulate = Color(1.0, 0.55, 0.45, 1.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_respawn_with_recap()

func _fire_temporal_pulse() -> void:
	_pulse_cooldown = 0.75
	var mouse_offset := get_global_mouse_position() - global_position
	var aim_direction := mouse_offset.normalized() if mouse_offset.length_squared() > 0.001 else _facing_vector
	_facing_vector = aim_direction
	var closest: TemporalDrone
	var closest_forward_distance := 150.0
	for enemy_node in get_tree().get_nodes_in_group("temporal_drones"):
		var enemy := enemy_node as TemporalDrone
		if not enemy or not enemy.active:
			continue
		var offset := enemy.global_position - global_position
		var forward_distance := offset.dot(aim_direction)
		var lateral_distance := absf(aim_direction.cross(offset))
		if forward_distance > 0.0 and forward_distance <= closest_forward_distance and lateral_distance <= 18.0:
			closest = enemy
			closest_forward_distance = forward_distance
	var world := get_parent() as Node2D
	if world:
		var beam := Line2D.new()
		beam.width = 3.0
		beam.default_color = Color(0.67, 0.95, 0.91, 0.95)
		beam.z_index = 20
		beam.add_point(world.to_local(global_position))
		var pulse_target := global_position + aim_direction * 150.0
		if closest:
			pulse_target = closest.global_position
		beam.add_point(world.to_local(pulse_target))
		world.add_child(beam)
		var beam_tween := beam.create_tween()
		beam_tween.tween_property(beam, "modulate:a", 0.0, 0.18)
		beam_tween.tween_callback(beam.queue_free)
	if closest:
		closest.take_pulse()

func _respawn_with_recap() -> void:
	health = 3
	_refresh_health_hud()
	velocity = Vector2.ZERO
	global_position = Vector2(80.0, 80.0)
	var manager := get_parent()
	if manager and manager.has_method("on_player_respawned"):
		manager.call("on_player_respawned")
	if manager and manager.has_method("trigger_timeline_switch"):
		manager.call("trigger_timeline_switch", 0)
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_ui and dialogue_ui.has_method("start_dialogue"):
		dialogue_ui.call("start_dialogue", "TIME RECAP", [
			"Your temporal shield failed. The drone attack has reset to the opening wave.",
			"Your collected stabilizers and crafted items are safe.",
			"Press Q to return to the future. Aim with the mouse and hold F or left-click to pulse."
		])
	player_died.emit()

func _refresh_health_hud() -> void:
	var loom_ui := get_tree().get_first_node_in_group("loom_ui")
	if loom_ui and loom_ui.has_method("refresh_status"):
		loom_ui.call("refresh_status")

func _update_walk_animation(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		_facing_direction = "side"
		sprite.flip_h = dir.x < 0.0
		sprite.play("walk_side")
	elif dir.y > 0.0:
		_facing_direction = "down"
		sprite.flip_h = false
		sprite.play("walk_down")
	else:
		_facing_direction = "up"
		sprite.flip_h = false
		sprite.play("walk_up")

func _update_idle_animation() -> void:
	match _facing_direction:
		"side":
			sprite.play("idle_side")
		"up":
			sprite.play("idle_up")
		_:
			sprite.play("idle_down")

func _handle_interaction() -> void:
	if _nearby_interactables.is_empty():
		return
	var target := _nearby_interactables[0]
	var interactable: Node = target
	if not interactable.has_method("interact"):
		interactable = target.get_parent()
	if interactable and interactable.has_method("interact"):
		interactable.call("interact", self)
		if interactable is Node2D:
			interacted_with.emit(interactable as Node2D)

func _on_interact_area_entered(area: Area2D) -> void:
	if not _nearby_interactables.has(area):
		_nearby_interactables.append(area)

func _on_interact_area_exited(area: Area2D) -> void:
	_nearby_interactables.erase(area)
