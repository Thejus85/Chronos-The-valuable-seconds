class_name DoorTransitionCutscene
extends CanvasLayer

## Cinematic teleport transition cutscene with glitch text, black screen, and audio effects.

@onready var sector_label: Label = $CenterContainer/PanelContainer/Margin/VBoxContainer/SectorLabel
@onready var sub_label: Label = $CenterContainer/PanelContainer/Margin/VBoxContainer/SubLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func play_transition(title: String, message: String, on_midpoint: Callable = Callable(), on_finish: Callable = Callable()) -> void:
	if not sector_label:
		sector_label = get_node_or_null("CenterContainer/PanelContainer/Margin/VBoxContainer/SectorLabel") as Label
	if not sub_label:
		sub_label = get_node_or_null("CenterContainer/PanelContainer/Margin/VBoxContainer/SubLabel") as Label
	if not anim_player:
		anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer

	if sector_label:
		sector_label.text = title
	if sub_label:
		sub_label.text = message
	visible = true

	if SoundManager:
		SoundManager.play_teleport()

	if anim_player:
		anim_player.play("transition")

	# Halfway through the animation (screen is 100% black)
	await get_tree().create_timer(1.0).timeout
	if on_midpoint.is_valid():
		on_midpoint.call()

	# Wait for animation to finish
	if anim_player:
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(1.6).timeout
	visible = false
	if on_finish.is_valid():
		on_finish.call()

