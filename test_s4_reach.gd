@tool
extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	root.add_child(main_node)

func _process(_delta: float) -> bool:
	var space := root.get_world_2d().direct_space_state
	var shape := CapsuleShape2D.new()
	shape.radius = 6.0
	shape.height = 14.0

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 2
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var start := Vector2i(80, 80)
	var visited := {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var step := 8

	while queue.size() > 0:
		var curr: Vector2i = queue.pop_front()
		for d in [Vector2i(step, 0), Vector2i(-step, 0), Vector2i(0, step), Vector2i(0, -step)]:
			var nxt: Vector2i = curr + d
			if nxt.x < 0 or nxt.x > 800 or nxt.y < 0 or nxt.y > 800:
				continue
			if visited.has(nxt):
				continue
			query.transform = Transform2D(1.5708, Vector2(nxt))
			var res := space.intersect_shape(query)
			if res.size() == 0:
				visited[nxt] = true
				queue.push_back(nxt)

	print("Total walkable 8x8 points in Sector 4 from (80, 80): ", visited.size())
	var targets := {
		"Dr_Aris": Vector2(160, 112),
		"TemporalLoomCore": Vector2(592, 304),
		"ThroughputMultiplier": Vector2(288, 656),
		"AuraExtractor": Vector2(352, 96),
		"NexusPortal": Vector2(408, 408),
		"BlastDoor (616, 120)": Vector2(616, 120),
		"Old PhaseKey in S4 (720, 560)": Vector2(720, 560)
	}

	for tname in targets:
		var target_pos: Vector2 = targets[tname]
		var min_dist := 9999.0
		var closest: Vector2i = Vector2i.ZERO
		for pt in visited:
			var d := Vector2(pt).distance_to(target_pos)
			if d < min_dist:
				min_dist = d
				closest = pt
		print(tname, " target: ", target_pos, " | Closest reached: ", closest, " (dist: ", min_dist, " px)")

	quit(0)
	return false
