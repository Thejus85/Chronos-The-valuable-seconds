@tool
extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://Scenes/Rooms/Room_Jungle_Waterfall.tscn")
	var j := scene.instantiate() as Node2D
	root.add_child(j)

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

	var start := Vector2i(200, 260)
	var visited := {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var step := 8

	while queue.size() > 0:
		var curr: Vector2i = queue.pop_front()
		for d in [Vector2i(step, 0), Vector2i(-step, 0), Vector2i(0, step), Vector2i(0, -step)]:
			var nxt: Vector2i = curr + d
			if nxt.x < 16 or nxt.x > 608 or nxt.y < 16 or nxt.y > 464:
				continue
			if visited.has(nxt):
				continue
			query.transform = Transform2D(0.0, Vector2(nxt))
			var res := space.intersect_shape(query)
			if res.size() == 0:
				visited[nxt] = true
				queue.push_back(nxt)

	print("Total walkable 8x8 points in Jungle: ", visited.size())
	var targets := {
		"TemporalSkeleton": Vector2(220, 220),
		"PhaseKey": Vector2(170, 125),
		"SouthExit (200, 455)": Vector2(200, 455),
		"NexusPortal (500, 350)": Vector2(500, 350),
		"Grove (540, 390)": Vector2(540, 390)
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
		print(tname, " target: ", target_pos, " | Closest: ", closest, " (dist: ", min_dist, " px)")

	quit(0)
	return false
