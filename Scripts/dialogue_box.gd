class_name DialogueUI
extends CanvasLayer

## Sci-fi terminal dialogue overlay with typewriter text effect and pagination.

signal dialogue_finished

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $Panel/DialogueText
@onready var prompt_label: Label = $Panel/PromptLabel

var _current_lines: Array = []
var _line_index: int = 0
var _is_typing: bool = false
var _active_tween: Tween

func _ready() -> void:
	add_to_group("dialogue_box")
	if panel:
		panel.visible = false

func _input(event: InputEvent) -> void:
	if not panel or not panel.visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _is_typing:
			_skip_typewriter()
		else:
			_next_line()

func start_dialogue(speaker: String, lines: Array) -> void:
	if not panel:
		return
	speaker_label.text = speaker
	_current_lines = lines
	_line_index = 0
	panel.visible = true
	_show_current_line()

func is_active() -> bool:
	return panel != null and panel.visible

func _show_current_line() -> void:
	if _line_index >= _current_lines.size():
		_close_dialogue()
		return

	dialogue_text.text = _current_lines[_line_index]
	dialogue_text.visible_ratio = 0.0
	_is_typing = true
	prompt_label.text = "Press [E] to skip..."

	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	var duration := float(_current_lines[_line_index].length()) * 0.03
	_active_tween = create_tween()
	_active_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	_active_tween.tween_callback(func() -> void:
		_is_typing = false
		prompt_label.text = "Press [E] to continue >>"
	)

func _skip_typewriter() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	dialogue_text.visible_ratio = 1.0
	_is_typing = false
	prompt_label.text = "Press [E] to continue >>"

func _next_line() -> void:
	if SoundManager:
		SoundManager.play_button_click()
	_line_index += 1
	_show_current_line()

func close_dialogue() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_is_typing = false
	_close_dialogue()

func _close_dialogue() -> void:
	if panel:
		panel.visible = false
	dialogue_finished.emit()
