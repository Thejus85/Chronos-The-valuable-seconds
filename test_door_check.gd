@tool
extends SceneTree

func _init() -> void:
	print('--- Running test_door_check ---')
	var main_scene: PackedScene = load('res://main.tscn')
	if not main_scene:
		print('FAILED to load main.tscn')
		quit(1)
		return

	var main_node: Node2D = main_scene.instantiate()
	root.add_child(main_node)

	var player := main_node.get_node_or_null('Player') as CharacterBody2D
	var last_door := main_node.get_node_or_null('LastDoorTrigger') as Area2D
	var jungle := main_node.get_node_or_null('Room_Jungle_Waterfall') as Node2D
	var portal := main_node.get_node_or_null('NexusPortal') as Area2D

	print('Player exists: ', player != null)
	if player:
		print('Player collision_layer: ', player.collision_layer, ' mask: ', player.collision_mask)
		var detector := player.get_node_or_null('InteractDetector') as Area2D
		if detector:
			print('InteractDetector layer: ', detector.collision_layer, ' mask: ', detector.collision_mask)

	print('LastDoorTrigger exists: ', last_door != null)
	if last_door:
		print('LastDoorTrigger script: ', last_door.get_script())
		print('LastDoorTrigger layer: ', last_door.collision_layer, ' mask: ', last_door.collision_mask)

	if jungle:
		var exit_door := jungle.get_node_or_null('LastDoorwayExit') as Area2D
		print('LastDoorwayExit exists: ', exit_door != null)
		if exit_door:
			print('LastDoorwayExit layer: ', exit_door.collision_layer, ' mask: ', exit_door.collision_mask)
			print('LastDoorwayExit global_pos: ', exit_door.global_position)

	if portal:
		print('NexusPortal script: ', portal.get_script())
		print('NexusPortal layer: ', portal.collision_layer, ' mask: ', portal.collision_mask)

	quit(0)
