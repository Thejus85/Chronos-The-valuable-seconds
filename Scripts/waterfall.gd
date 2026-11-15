class_name WaterfallController
extends Node2D

## Coordinates 3 parallel streams and splash pool sparkles between 2096 and 2146 timeline palettes.

@onready var stream_left: AnimatedSprite2D = $WaterfallStream_Left
@onready var stream_center: AnimatedSprite2D = $WaterfallStream_Center
@onready var stream_right: AnimatedSprite2D = $WaterfallStream_Right
@onready var sparkles: AnimatedSprite2D = $SplashPoolSparkles

func _ready() -> void:
	set_timeline_state(false)

func set_timeline_state(is_ruined_timeline: bool) -> void:
	var anim_name := "flowing_2146" if is_ruined_timeline else "flowing_2096"
	if stream_left:
		stream_left.play(anim_name)
	if stream_center:
		stream_center.play(anim_name)
	if stream_right:
		stream_right.play(anim_name)
