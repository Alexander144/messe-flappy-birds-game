extends Line2D

# Lightning settings
@export var bolt_color: Color = Color(1.0, 0.7, 0.0, 1.0)  # Orange-yellow
@export var glow_color: Color = Color(1.0, 0.3, 0.0, 0.7)  # Orange glow
@export var bolt_width: float = 3.0  # Thicker to be more visible

@export var segment_length: float = 10.0  # Distance between lightning points
@export var jaggedness: float = 5.0  # How much the lightning zigzags
@export var flash_duration: float = 0.15  # How long each bolt lasts
@export var flash_interval_min: float = 0.3  # Minimum time between flashes
@export var flash_interval_max: float = 0.8  # Maximum time between flashes
@export var num_bolts: int = 5  # Number of simultaneous lightning bolts
@export var bolt_spread: float = 20.0  # Horizontal spread of bolts

var timer: float = 0.0
var next_flash_time: float = 0.0
var is_flashing: bool = false
var flash_timer: float = 0.0
var cable_start: Vector2
var cable_end: Vector2
var is_top_pipe: bool = false
var x_offset: float = 0.0

# Multiple bolt nodes
var bolt_lines: Array = []

#func _ready():
#	width = bolt_width
#	default_color = bolt_color
	
#	visible = false
	
	# Create additional Line2D nodes for multiple bolts
#	for i in range(num_bolts - 1):  # -1 because main Line2D is one bolt
#		var new_bolt = Line2D.new()
#		new_bolt.width = bolt_width
#		new_bolt.default_color = bolt_color
#		new_bolt.visible = false
#		add_child(new_bolt)
#		bolt_lines.append(new_bolt)
	
#	schedule_next_flash()
	
	# Add glow shader
#	if ResourceLoader.exists("res://lightning_glow.gdshader"):
#		var shader_material = ShaderMaterial.new()
#		shader_material.shader = load("res://lightning_glow.gdshader")
#		material = shader_material
		
#		# Apply to all bolt lines
#		for bolt in bolt_lines:
#			var bolt_material = shader_material.duplicate()
#			bolt.material = bolt_material

func setup_cable(start_pos: Vector2, end_pos: Vector2, is_top: bool = false):
	cable_start = start_pos
	cable_end = end_pos
	is_top_pipe = is_top

func update_x_position(new_x: float):
	x_offset = new_x
	
	# Update main Line2D
	if get_point_count() > 0:
		for i in range(get_point_count()):
			var point = get_point_position(i)
			point.x = new_x
			set_point_position(i, point)
	
	# Update all additional bolt lines
	for bolt in bolt_lines:
		if bolt.get_point_count() > 0:
			for i in range(bolt.get_point_count()):
				var point = bolt.get_point_position(i)
				point.x = new_x
				bolt.set_point_position(i, point)

func _process(delta: float):
	timer += delta
	
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			visible = false
			for bolt in bolt_lines:
				bolt.visible = false
			is_flashing = false
			schedule_next_flash()
	else:
		if timer >= next_flash_time:
			create_multiple_lightning_bolts()
			visible = true
			for bolt in bolt_lines:
				bolt.visible = true
			is_flashing = true
			flash_timer = flash_duration
			timer = 0.0

func schedule_next_flash():
	next_flash_time = randf_range(flash_interval_min, flash_interval_max)

func create_multiple_lightning_bolts():
	# Create main bolt (this Line2D)
	var offset_x = randf_range(-bolt_spread, bolt_spread)
	create_single_lightning_bolt(self, offset_x)
	
	# Create additional bolts
	for bolt in bolt_lines:
		offset_x = randf_range(-bolt_spread, bolt_spread)
		create_single_lightning_bolt(bolt, offset_x)

func create_single_lightning_bolt(line: Line2D, offset_x: float):
	line.clear_points()
	
	var start = cable_start + Vector2(offset_x, 0)
	var end = cable_end + Vector2(offset_x, 0)
	
	var direction = (end - start).normalized()
	var distance = start.distance_to(end)
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Start point
	line.add_point(start)
	
	# Generate jagged segments
	var num_segments = int(distance / segment_length)
	for i in range(1, num_segments):
		var progress = float(i) / float(num_segments)
		var base_point = start.lerp(end, progress)
		
		# Add random offset perpendicular to the cable direction
		var offset = perpendicular * randf_range(-jaggedness, jaggedness)
		var point = base_point + offset
		
		line.add_point(point)
	
	# End point
	line.add_point(end)
