@tool
extends SceneTree

func _init() -> void:
	var img := Image.load_from_file("res://Assets/Tilesets/GentleForest/jungle_waterfall_map_2096.png")
	if not img:
		print("Failed to load map image")
		quit(1)
		return
	
	var w := img.get_width()
	var h := img.get_height()
	print("Map size: ", w, "x", h)

	# Print an ASCII representation in 16x16 blocks
	# Water is bluish, cliff/rock is grayish/brownish, grass is green, dirt/sand is yellowish/brown
	for y in range(0, h, 16):
		var line := "%3d: " % y
		for x in range(0, w, 16):
			var c: Color = img.get_pixel(x + 8, y + 8)
			# Classify color
			if c.b > 0.45 and c.b > c.r * 1.3:
				line += "~" # Water
			elif c.g > c.r * 1.05 and c.g > c.b * 1.05:
				line += "." # Grass
			elif c.r > 0.35 and c.g > 0.35 and c.b < 0.35:
				line += "=" # Dirt path / stairs
			elif c.r < 0.2 and c.g < 0.2 and c.b < 0.2:
				line += "O" # Cave / dark void
			else:
				line += "^" # Cliff / rock / tree
		print(line)

	quit(0)
