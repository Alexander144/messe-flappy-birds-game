extends Node

# ============================================
# FLAPPY BIRD - PARALLAX BACKGROUND
# ============================================

# -------------------- NODE REFERENCES --------------------
@export_group("Scene Nodes")
@export var camera: Camera2D
@export var player: Area2D
@export var player_sprite: AnimatedSprite2D
@export var player_collision: CollisionShape2D
@export var ground_container: Node2D
@export var pipe_container: Node2D

# Parallax Background
@export_group("Parallax Background")
@export var parallax_background: ParallaxBackground
@export var parallax_layer: ParallaxLayer
@export var background_sprite: Sprite2D

@export_group("UI Nodes")
@export var ui_layer: CanvasLayer
@export var score_label: Label
@export var high_score_label: Label
@export var start_label: Label
@export var tap_hint: Label
@export var game_over_panel: Panel
@export var game_over_label: Label
@export var final_score_label: Label
@export var restart_button: Button

# -------------------- TEXTURES --------------------
@export_group("Textures")
@export var bird_texture: Texture2D
@export var background_texture: Texture2D

# -------------------- PIPE SCENE --------------------
@export_group("Scenes")
@export var pipe_scene: PackedScene

# -------------------- GAMEPLAY SETTINGS --------------------
@export_group("Player Settings")
@export var gravity: float = 1200.0
@export var jump_force: float = -450.0
@export var player_start_x_ratio: float = 0.3
@export var player_start_y_ratio: float = 0.5
var player_start_position: Vector2
@export var max_fall_speed: float = 800.0
@export var rotation_speed: float = 5.0
@export var max_rotation_down: float = 0.9
@export var max_rotation_up: float = -0.6

@export_group("Pipe Settings")
@export var pipe_gap_base: float = 220.0
@export var pipe_width: float = 80.0
@export var pipe_speed_base: float = 200.0
@export var pipe_spawn_interval_base: float = 2.0
var pipe_spawn_x: float
@export var min_pipe_height_ratio: float = 0.25
@export var max_pipe_height_ratio: float = 0.75

@export_group("Difficulty Settings")
@export var difficulty_increase_rate: float = 0.08
@export var speed_multiplier_max: float = 3.5
@export var spawn_interval_min: float = 0.8
@export var gap_size_min: float = 130.0

# -------------------- SCROLL & VISUAL SETTINGS --------------------
@export_group("Scroll Settings")
#@export var background_scroll_speed_base: float = 50.0
#@export var parallax_scroll_scale: Vector2 = Vector2(0.5, 1.0)  # Parallax effect speed
@export var ground_height_offset: float = 120.0 

@export_group("Visual Settings")
@export var player_idle_bob_speed: float = 200.0
@export var player_idle_bob_amount: float = 10.0
@export var score_pop_scale: float = 1.3
@export var score_pop_duration: float = 0.1

# -------------------- UI SETTINGS --------------------
@export_group("UI Settings")
@export var use_cool_ui: bool = true

# -------------------- COLORS --------------------
@export_group("UI Colors")
@export var score_color: Color = Color.WHITE
@export var high_score_color: Color = Color.YELLOW
@export var game_over_color: Color = Color.RED

# -------------------- DEBUG --------------------
@export_group("Debug")
@export var show_debug_info: bool = false

# -------------------- GAME STATE --------------------
var player_velocity: Vector2 = Vector2.ZERO
var is_game_started: bool = false
var is_game_over: bool = false
var score: int = 0
var high_score: int = 0
var elapsed_time: float = 0.0
var game_time: float = 0.0

# -------------------- DYNAMIC DIFFICULTY --------------------
var current_pipe_speed: float
var current_spawn_interval: float
var current_pipe_gap: float
var current_background_scroll_speed: float

# -------------------- PIPES - SEPARATED --------------------
var pipe_pairs: Array = []
var active_pipes_count: int = 0
var pipe_spawn_timer: float = 0.0

# -------------------- VIEWPORT --------------------
var viewport_size: Vector2

# -------------------- COOL UI --------------------
var ui_manager: UIManager

var http_request: HTTPRequest

# -------------------- OPTIMIZATION VARIABLES --------------------
var parallax_scroll_offset: float = 0.0
var last_score: int = -1
var difficulty_update_timer: float = 0.0
const DIFFICULTY_UPDATE_INTERVAL: float = 0.5
var cached_half_rotation_speed: float
var deletion_x_threshold: float

# -------------------- INITIALIZATION --------------------
func _ready():
	if not validate_nodes():
		push_error("GameManager: Missing required node references!")
		return
	
	cached_half_rotation_speed = rotation_speed * 0.5
	
	# IMPORTANT: Get viewport size FIRST before setting up anything else
	viewport_size = get_viewport().get_visible_rect().size
	print("Viewport size: ", viewport_size)
	
	# Initialize difficulty values BEFORE setup
	current_pipe_speed = pipe_speed_base
	current_spawn_interval = pipe_spawn_interval_base
	current_pipe_gap = pipe_gap_base
	#current_background_scroll_speed = background_scroll_speed_base
	
	setup_parallax_background()
	setup_game_dimensions()  # Moved before apply_textures
	apply_textures()  # This now has correct viewport_size
	connect_signals()
	
	if use_cool_ui:
		setup_cool_ui()
	else:
		setup_ui_properties()
	
	reset_game()
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)



func setup_parallax_background():
	if not parallax_background:
		# Create ParallaxBackground if not assigned
		parallax_background = ParallaxBackground.new()
		parallax_background.name = "ParallaxBackground"
		# Add it as the FIRST child to render behind everything
		add_child(parallax_background)
		move_child(parallax_background, 0)
		print("Created ParallaxBackground")
	else:
		print("ParallaxBackground found: ", parallax_background.name)
	
	# Configure ParallaxBackground
	parallax_background.scroll_ignore_camera_zoom = true
	
	if not parallax_layer:
		# Create ParallaxLayer if not assigned
		parallax_layer = ParallaxLayer.new()
		parallax_layer.name = "ParallaxLayer"
		parallax_background.add_child(parallax_layer)
		print("Created ParallaxLayer")
	else:
		print("ParallaxLayer found: ", parallax_layer.name)
	
	# Configure ParallaxLayer
	#parallax_layer.motion_scale = parallax_scroll_scale
	#parallax_layer.motion_mirroring = Vector2(1920, 0)  # Will be updated in apply_textures()
	
	if not background_sprite:
		# Create Sprite2D if not assigned
		background_sprite = Sprite2D.new()
		background_sprite.name = "BackgroundSprite"
		parallax_layer.add_child(background_sprite)
		print("Created BackgroundSprite")
	else:
		print("BackgroundSprite found: ", background_sprite.name)
	
	# Configure Sprite2D
	background_sprite.centered = false

func setup_cool_ui():
	ui_manager = UIManager.new()
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	ui_manager.game_manager = self
	
	var restart_btn = ui_manager.get_restart_button()
	if restart_btn:
		restart_btn.pressed.connect(restart_game)
	
	if ui_layer:
		ui_layer.hide()

func setup_game_dimensions():
	# viewport_size already set in _ready()
	print("Setting up game dimensions with viewport: ", viewport_size)
	
	player_start_position = Vector2(viewport_size.x * player_start_x_ratio, viewport_size.y * player_start_y_ratio)
	pipe_spawn_x = viewport_size.x + 50.0
	
	deletion_x_threshold = -200.0
	
	setup_positions()
	
	if not is_game_started:
		player.position = player_start_position

	
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		setup_game_dimensions()

func validate_nodes() -> bool:
	var valid = true
	
	if not camera: valid = false; push_error("Camera2D node not assigned!")
	if not player: valid = false; push_error("Player node not assigned!")
	if not player_sprite: valid = false; push_error("PlayerSprite node not assigned!")
	if not pipe_container: valid = false; push_error("PipeContainer node not assigned!")
	if not pipe_scene: valid = false; push_error("PipeScene (PackedScene) not assigned!")
	
	return valid

func apply_textures():
	player_sprite.play('default')
	
	if background_texture and background_sprite:
		background_sprite.texture = background_texture
		print("Background texture assigned: ", background_texture.get_size())
		
		# Scale background to fit viewport height
		var texture_height = background_texture.get_height()
		if texture_height > 0:
			var scale_factor = viewport_size.y / texture_height
			background_sprite.scale = Vector2(scale_factor, scale_factor)
			print("Background scale: ", background_sprite.scale)
		
		# Update motion_mirroring based on scaled texture width
		if parallax_layer:
			var scaled_width = background_texture.get_width() * background_sprite.scale.x
			parallax_layer.motion_mirroring = Vector2(scaled_width, 0)
			print("Motion mirroring: ", parallax_layer.motion_mirroring)
	else:
		if not background_texture:
			push_error("Background texture not assigned!")
		if not background_sprite:
			push_error("Background sprite not found!")

func setup_positions():
	if camera:
		camera.position = viewport_size / 2
		camera.enabled = true
		print("Camera position: ", camera.position)

func setup_ui_properties():
	if score_label:
		score_label.add_theme_color_override("font_color", score_color)
	if high_score_label:
		high_score_label.add_theme_color_override("font_color", high_score_color)
	if game_over_label:
		game_over_label.add_theme_color_override("font_color", game_over_color)

func connect_signals():
	if player:
		player.body_entered.connect(_on_player_collision)
		player.area_entered.connect(_on_player_area_collision)
	if restart_button and not use_cool_ui:
		restart_button.pressed.connect(restart_game)

# -------------------- DIFFICULTY CALCULATION --------------------
func update_difficulty():
	var difficulty_multiplier = exp(difficulty_increase_rate * game_time)
	
	current_pipe_speed = min(pipe_speed_base * difficulty_multiplier, pipe_speed_base * speed_multiplier_max)
	current_spawn_interval = max(pipe_spawn_interval_base / difficulty_multiplier, spawn_interval_min)
	current_pipe_gap = max(pipe_gap_base / difficulty_multiplier, gap_size_min)
	#current_background_scroll_speed = background_scroll_speed_base * (current_pipe_speed / pipe_speed_base)

func handle_tap():
	if is_game_over:
		return
	if not is_game_started:
		start_game()
	else:
		player_velocity.y = jump_force

func _input(event):
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventMouseButton and event.pressed):
		if event.pressed:
			handle_tap()

# -------------------- GAME LOOP --------------------
func _process(delta: float):
	if is_game_over:
		return
	
	if not is_game_started:
		elapsed_time += delta
		player.position.y = player_start_position.y + sin(elapsed_time * player_idle_bob_speed / 1000.0) * player_idle_bob_amount
		scroll_background(delta * 0.3)  # Slow scroll during idle
		return
	
	game_time += delta
	
	difficulty_update_timer += delta
	if difficulty_update_timer >= DIFFICULTY_UPDATE_INTERVAL:
		update_difficulty()
		difficulty_update_timer = 0.0
	
	# Player physics
	player_velocity.y += gravity * delta
	player_velocity.y = min(player_velocity.y, max_fall_speed)
	player.position += player_velocity * delta
	
	var target_rotation = clamp(player_velocity.y / 400.0, max_rotation_up, max_rotation_down)
	player.rotation = lerp(player.rotation, target_rotation, delta * cached_half_rotation_speed)
	
	# Pipe spawning
	pipe_spawn_timer += delta
	if pipe_spawn_timer >= current_spawn_interval:
		spawn_pipe()
		pipe_spawn_timer = 0.0
	
	update_pipes(delta)
	scroll_background(delta)

	if player.position.y > viewport_size.y or player.position.y < -50:
		game_over()
	
	# Debug info
	if show_debug_info and score_label:
		score_label.text = "Score: %d | Pipes: %d" % [score, active_pipes_count]

# -------------------- SCROLLING --------------------

func scroll_background(delta: float):
	if not parallax_background:
		return
	
	var scroll_amount = current_background_scroll_speed * delta
	parallax_scroll_offset += scroll_amount
	
	# Update parallax background scroll base offset (this is the correct property)
	parallax_background.scroll_base_offset.x = -parallax_scroll_offset


# -------------------- PIPE MANAGEMENT (FIXED) --------------------
# -------------------- PIPE MANAGEMENT (FIXED SIZE CABLES) --------------------
func spawn_pipe():
	if not pipe_container or not pipe_scene:
		return
	
	var world_top = 0.0 
	var world_bottom = viewport_size.y - ground_height_offset
	var game_area_height = world_bottom - world_top
	
	var safe_min = world_top + (game_area_height * min_pipe_height_ratio)
	var safe_max = world_top + (game_area_height * max_pipe_height_ratio)
	var gap_center_y = randf_range(safe_min, safe_max)
	var half_gap = current_pipe_gap * 0.5
	
	# Create pipes with fixed size - they extend outside the screen
	var top_pipe = create_fixed_pipe(true, gap_center_y)
	var bottom_pipe = create_fixed_pipe(false, gap_center_y)
	
	# Score Area setup
	var score_area = Area2D.new()
	score_area.position = Vector2(pipe_spawn_x, gap_center_y)
	score_area.name = "ScoreArea"
	
	var score_collision = CollisionShape2D.new()
	var score_shape = RectangleShape2D.new()
	score_shape.size = Vector2(10, current_pipe_gap)
	score_collision.shape = score_shape
	score_area.add_child(score_collision)
	
	score_area.area_entered.connect(_on_score_area_entered.bind(score_area))
	pipe_container.add_child(score_area)
	
	# Store as a group
	var pipe_pair = {
		"top": top_pipe,
		"bottom": bottom_pipe,
		"score_area": score_area,
		"scored": false
	}
	pipe_pairs.append(pipe_pair)
	active_pipes_count = pipe_pairs.size()

func create_fixed_pipe(is_top: bool, gap_center_y: float) -> Node2D:
	if not pipe_scene:
		push_error("pipe_scene is not assigned!")
		return null
	
	var pipe_instance = pipe_scene.instantiate() as Node2D
	if not pipe_instance:
		push_error("Failed to instantiate pipe scene!")
		return null
		
	pipe_container.add_child(pipe_instance)
	pipe_instance.name = "Pipe"
	
	var pipe_sprite = pipe_instance.get_node_or_null("Sprite2D")
	var pipe_collision = pipe_instance.get_node_or_null("CollisionShape2D")
	var lightning = pipe_instance.get_node_or_null("Line2D")
	
	var original_pipe_height = 300.0
	var original_pipe_width = 100.0
	if pipe_sprite and pipe_sprite.texture:
		original_pipe_height = pipe_sprite.texture.get_height()
		original_pipe_width = pipe_sprite.texture.get_width()
	
	if original_pipe_height == 0.0 or original_pipe_width == 0.0:
		push_error("Pipe texture dimensions are zero, cannot scale pipe!")
		return null
	
	var half_gap = current_pipe_gap * 0.5
	var pipe_position: Vector2
	
	var scale_factor_x = pipe_width / original_pipe_width
	var collision_height = viewport_size.y * 2
	
	if pipe_sprite:
		pipe_sprite.centered = true
	
	# Calculate cable endpoints for lightning IN LOCAL COORDINATES
	var cable_start: Vector2
	var cable_end: Vector2
	
	if is_top:
		# Top pipe is flipped (scale.y = -1)
		pipe_position = Vector2(pipe_spawn_x, gap_center_y - half_gap - original_pipe_height * 0.5)
		pipe_instance.scale = Vector2(scale_factor_x, -1.0)
		pipe_instance.position = pipe_position
		
		# For flipped pipe: local positive Y goes UP in world space
		# Lightning from bottom edge of visible pipe upward to top of screen
		cable_start = Vector2(0, -original_pipe_height * 0.01)  # Top edge of pipe (in local coords)
		cable_end = Vector2(0, -original_pipe_height * 0.1)  # Extend to bottom
		
		if pipe_collision and pipe_collision.shape is RectangleShape2D:
			var shape = pipe_collision.shape as RectangleShape2D
			shape.size = Vector2(pipe_width, collision_height)
			pipe_collision.position = Vector2(0, -collision_height * 0.5)
	else:
		# Bottom pipe (normal orientation)
		pipe_position = Vector2(pipe_spawn_x, gap_center_y + half_gap + original_pipe_height * 0.5)
		pipe_instance.scale = Vector2(scale_factor_x, 1.0)
		pipe_instance.position = pipe_position
		
		# Lightning from top edge of pipe downward to bottom of screen
		var world_bottom = viewport_size.y - ground_height_offset
		var distance_to_bottom = world_bottom - pipe_position.y
		
		cable_start = Vector2(0, -original_pipe_height * 0.01)  # Top edge of pipe (in local coords)
		cable_end = Vector2(0, -original_pipe_height * 0.1)  # Extend to bottom
		
		if pipe_collision and pipe_collision.shape is RectangleShape2D:
			var shape = pipe_collision.shape as RectangleShape2D
			shape.size = Vector2(pipe_width, collision_height)
			pipe_collision.position = Vector2(0, collision_height * 0.5)
	
	# Setup lightning cable endpoints
	if lightning and lightning.has_method("setup_cable"):
		lightning.call_deferred("setup_cable", cable_start, cable_end, is_top)
		print("Setting up lightning - IsTop: ", is_top, " Start: ", cable_start, " End: ", cable_end)
	
	return pipe_instance



func update_pipes(delta: float):
	if not is_game_started and not is_game_over:
		return  # Don't process pipes during idle state
		
	var speed_delta = current_pipe_speed * delta
	
	# Iterate backwards to safely remove items
	for i in range(pipe_pairs.size() - 1, -1, -1):
		var pair = pipe_pairs[i]
		
		# Move all components together
		if pair.top and is_instance_valid(pair.top):
			pair.top.position.x -= speed_delta
		if pair.bottom and is_instance_valid(pair.bottom):
			pair.bottom.position.x -= speed_delta
		if pair.score_area and is_instance_valid(pair.score_area):
			pair.score_area.position.x -= speed_delta
		
		# Check if pipes are off-screen
		var check_x = INF
		if pair.score_area and is_instance_valid(pair.score_area):
			check_x = pair.score_area.position.x
		elif pair.top and is_instance_valid(pair.top):
			check_x = pair.top.position.x
		elif pair.bottom and is_instance_valid(pair.bottom):
			check_x = pair.bottom.position.x
		
		if check_x < deletion_x_threshold:
			# Clean up all components
			if pair.top and is_instance_valid(pair.top):
				pair.top.queue_free()
			if pair.bottom and is_instance_valid(pair.bottom):
				pair.bottom.queue_free()
			if pair.score_area and is_instance_valid(pair.score_area):
				pair.score_area.queue_free()
			
			pipe_pairs.remove_at(i)
			active_pipes_count = pipe_pairs.size()

# -------------------- COLLISIONS --------------------
func _on_player_collision(body: Node2D):
	if not is_game_over:
		game_over()

func _on_player_area_collision(area: Area2D):
	if area.get_parent() != null and area.get_parent().name == "Pipe" and not is_game_over:
		game_over()

func _on_score_area_entered(area: Area2D, score_area: Area2D):
	if area == player:
		score += 1
		
		if use_cool_ui and ui_manager:
			ui_manager.update_score(score, player.position)
		elif score_label and score != last_score:
			if not show_debug_info:
				score_label.text = str(score)
			last_score = score
			
			if score_pop_duration > 0:
				var tween = create_tween()
				tween.tween_property(score_label, "scale", Vector2(score_pop_scale, score_pop_scale), score_pop_duration)
				tween.tween_property(score_label, "scale", Vector2.ONE, score_pop_duration)
		
		# Mark this pair as scored so we don't double-count
		for pair in pipe_pairs:
			if pair.score_area == score_area:
				pair.scored = true
				break
		
		# Disable the score area immediately
		score_area.monitoring = false
		score_area.set_process_mode(Node.PROCESS_MODE_DISABLED)

# -------------------- GAME FLOW --------------------
func start_game():
	is_game_started = true
	player_velocity = Vector2.ZERO
	game_time = 0.0
	difficulty_update_timer = 0.0
	update_difficulty()
	
	if use_cool_ui and ui_manager:
		ui_manager.hide_start_screen()
	else:
		start_label.visible = false
		tap_hint.visible = false

func game_over():
	is_game_over = true
	
	var is_new_record = score > high_score
	if is_new_record:
		high_score = score
	
	if use_cool_ui and ui_manager:
		ui_manager.show_game_over(score, high_score, player.position, is_new_record)
		ui_manager.update_high_score(high_score)
	else:
		game_over_panel.visible = true
		if is_new_record:
			high_score_label.text = "Best: " + str(high_score)
			final_score_label.text = "BEST SCORE!\n " + str(score)
		else:
			final_score_label.text = "Score: " + str(score) + "\nBest: " + str(high_score)

func restart_game():
	# OPTIMIZED CLEANUP - Process in background
	if pipe_container:
		# Get all children at once
		var children = pipe_container.get_children()
		
		# Disable processing immediately to prevent any updates
		for child in children:
			child.set_process(false)
			child.set_physics_process(false)
			child.set_process_input(false)
			child.set_process_unhandled_input(false)
			
		# Now queue them for deletion
		for child in children:
			child.queue_free()
	
	# Clear the tracking arrays immediately
	pipe_pairs.clear()
	active_pipes_count = 0
	
	# Defer the reset to next frame to spread the load
	call_deferred("reset_game")

func reset_game():
	is_game_started = false
	is_game_over = false
	score = 0
	last_score = -1
	elapsed_time = 0.0
	game_time = 0.0
	player_velocity = Vector2.ZERO
	pipe_spawn_timer = 0.0
	difficulty_update_timer = 0.0
	parallax_scroll_offset = 0.0
	
	current_pipe_speed = pipe_speed_base
	current_spawn_interval = pipe_spawn_interval_base
	current_pipe_gap = pipe_gap_base
	#current_background_scroll_speed = background_scroll_speed_base
	
	player.position = player_start_position 
	player.rotation = 0
	
	# Reset parallax scroll
	if parallax_background:
		parallax_background.scroll_offset = Vector2.ZERO
	
	if use_cool_ui and ui_manager:
		ui_manager.show_start_screen()
		ui_manager.update_score(0, player.position)
		ui_manager.update_high_score(high_score)
	else:
		if not show_debug_info:
			score_label.text = "0"
		score_label.scale = Vector2.ONE
		start_label.visible = true
		tap_hint.visible = true
		game_over_panel.visible = false
	
func pushToFirebase():
	var url = "http://localhost:3000/api/users"
	
	var body_data = {
		"username": "player123",
		"company": "My Company",
		"email": "player@example.com",
		"points": score
	}
	
	var json_body = JSON.stringify(body_data)
	
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	
	var error = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if error != OK:
		print("Error making request: ", error)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 201:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var user = json.data
			print("User created successfully!")
			print("ID: ", user.id)
			print("Username: ", user.username)
			print("Company: ", user.company)
			print("Email: ", user.email)
			print("Points: ", user.points)
		else:
			print("Error parsing JSON response")
	elif response_code == 400:
		print("Bad request: Missing required fields")
	elif response_code == 500:
		print("Server error: Failed to create user")
	else:
		print("Request failed with response code: ", response_code)
		print("Response body: ", body.get_string_from_utf8())
