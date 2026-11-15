class_name BounceBackIntro
extends CanvasLayer

## Handles the initial cinematic "BOUNCE BACK" title screen with Play and Exit controls.

signal game_started

@onready var root_control: Control = $Root
@onready var play_button: Button = $Root/CenterBox/Buttons/PlayButton
@onready var exit_button: Button = $Root/CenterBox/Buttons/ExitButton
@onready var glitch_glow: ColorRect = $Root/GlitchGlow

var _started: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		play_button.grab_focus()
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if _started:
		return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event := event as InputEventKey
		var kc: Key = key_event.keycode
		var pkc: Key = key_event.physical_keycode
		if kc == KEY_SPACE or kc == KEY_ENTER or kc == KEY_KP_ENTER or pkc == KEY_SPACE or pkc == KEY_ENTER or pkc == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_on_play_pressed()
		elif kc == KEY_ESCAPE or pkc == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_exit_pressed()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_play_pressed()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_exit_pressed()

func _on_play_pressed() -> void:
	if _started:
		return
	_started = true
	if SoundManager:
		SoundManager.play_button_click()
	print("[BounceBackIntro] Play pressed - starting game")

	var tween := create_tween()
	if root_control:
		tween.tween_property(root_control, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		visible = false
		game_started.emit()
		queue_free()
	)

func _on_exit_pressed() -> void:
	if SoundManager:
		SoundManager.play_button_click()
	print("[BounceBackIntro] Exit pressed - quitting game")
	get_tree().quit()
