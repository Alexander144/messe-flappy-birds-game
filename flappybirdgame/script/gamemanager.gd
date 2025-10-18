extends Node

# ============================================
# FLAPPY BIRD - FULL INSPECTOR SETUP
# ============================================

# -------------------- NODE REFERENCES --------------------
@export_group("Scene Nodes")
@export var camera: Camera2D
@export var player: Area2D
@export var player_sprite: Sprite2D
@export var player_collision: CollisionShape2D
@export var background_container: Node2D
@export var bg_sprite_1: Sprite2D
@export var bg_sprite_2: Sprite2D
@export var ground_container: Node2D
@export var pipe_container: Node2D

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
@export var pipe_gap: float = 220.0
@export var pipe_width: float = 80.0
@export var pipe_speed: float = 180.0
@export var pipe_spawn_interval: float = 2.2
var pipe_spawn_x: float
@export var min_pipe_height_ratio: float = 0.25
@export var max_pipe_height_ratio: float = 0.75

# -------------------- SCROLL & VISUAL SETTINGS --------------------
@export_group("Scroll Settings")
@export var background_scroll_speed: float = 50.0

@export_group("Visual Settings")
@export var player_idle_bob_speed: float = 200.0 # Time scale for bobbing
@export var player_idle_bob_amount: float = 10.0
@export var score_pop_scale: float = 1.3
@export var score_pop_duration: float = 0.1

# -------------------- COLORS --------------------
@export_group("UI Colors")
@export var score_color: Color = Color.WHITE
@export var high_score_color: Color = Color.YELLOW
@export var game_over_color: Color = Color.RED

# -------------------- GAME STATE --------------------
var player_velocity: Vector2 = Vector2.ZERO
var is_game_started: bool = false
var is_game_over: bool = false
var score: int = 0
var high_score: int = 0
var elapsed_time: float = 0.0

# -------------------- PIPES --------------------
var pipes: Array = []
var pipe_spawn_timer: float = 0.0

# -------------------- VIEWPORT --------------------
var viewport_size: Vector2

var http_request: HTTPRequest

# -------------------- INITIALIZATION --------------------
func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	player_start_position = Vector2(viewport_size.x * player_start_x_ratio, viewport_size.y * player_start_y_ratio)
	pipe_spawn_x = viewport_size.x + 50.0
	
	if not validate_nodes():
		push_error("GameManager: Missing required node references!")
		return
	
	apply_textures()
	setup_positions()
	setup_ui_properties()
	connect_signals()
	reset_game()
	
		# Create and setup HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		var new_viewport_size = get_viewport().get_visible_rect().size
		if new_viewport_size != viewport_size:
			viewport_size = new_viewport_size
			player_start_position = Vector2(viewport_size.x * player_start_x_ratio, viewport_size.y * player_start_y_ratio)
			pipe_spawn_x = viewport_size.x + 50.0
			setup_positions()

func validate_nodes() -> bool:
	var valid = true
	
	if not player: valid = false; push_error("Player node not assigned!")
	if not player_sprite: valid = false; push_error("PlayerSprite node not assigned!")
	if not pipe_container: valid = false; push_error("PipeContainer node not assigned!")
	if not pipe_scene: valid = false; push_error("PipeScene (PackedScene) not assigned!")
	
	return valid

func apply_textures():
	if bird_texture and player_sprite:
		player_sprite.texture = bird_texture
	
	if background_texture:
		if bg_sprite_1:
			bg_sprite_1.texture = background_texture
			bg_sprite_1.centered = false
		if bg_sprite_2:
			bg_sprite_2.texture = background_texture
			bg_sprite_2.centered = false

func setup_positions():
	if camera:
		camera.position = viewport_size / 2
	
	if background_texture and bg_sprite_1 and bg_sprite_2:
		var bg_target_height = viewport_size.y
		var texture_height = background_texture.get_height()
		var scale_factor = bg_target_height / texture_height
		
		bg_sprite_1.scale = Vector2(scale_factor, scale_factor)
		bg_sprite_2.scale = Vector2(scale_factor, scale_factor)
		bg_sprite_1.position = Vector2.ZERO
		var scaled_bg_width = bg_sprite_1.get_rect().size.x
		bg_sprite_2.position = Vector2(scaled_bg_width, 0)
		
		if background_container:
			background_container.position = Vector2.ZERO

	if player:
		player.position = player_start_position

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
	if restart_button:
		restart_button.pressed.connect(restart_game)

# -------------------- INPUT HANDLING --------------------
func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		handle_tap()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap()

func handle_tap():
	if is_game_over:
		return
	if not is_game_started:
		start_game()
	else:
		player_velocity.y = jump_force

# -------------------- GAME LOOP --------------------
func _process(delta: float):
	if is_game_over:
		return
	
	if not is_game_started:
		elapsed_time += delta
		player.position.y = player_start_position.y + sin(elapsed_time * player_idle_bob_speed / 1000.0) * player_idle_bob_amount
		return
	
	player_velocity.y += gravity * delta
	player_velocity.y = min(player_velocity.y, max_fall_speed)
	player.position += player_velocity * delta
	player.rotation = lerp(player.rotation, clamp(player_velocity.y / 400.0, max_rotation_up, max_rotation_down), delta * rotation_speed)
	
	pipe_spawn_timer += delta
	if pipe_spawn_timer >= pipe_spawn_interval:
		spawn_pipe()
		pipe_spawn_timer = 0.0
	
	update_pipes(delta)
	scroll_background(delta)

	if player.position.y > viewport_size.y or player.position.y < -50:
		game_over()

# -------------------- SCROLLING --------------------
func scroll_background(delta: float):
	var sprites = [bg_sprite_1, bg_sprite_2]
	var scaled_bg_width = sprites[0].get_rect().size.x
	var scroll_amount = background_scroll_speed * delta
	
	for sprite in sprites:
		sprite.position.x -= scroll_amount
	
	var max_x = max(sprites[0].position.x, sprites[1].position.x)
	
	for sprite in sprites:
		if sprite.position.x <= -scaled_bg_width:
			sprite.position.x = max_x + scaled_bg_width
			max_x = sprite.position.x

# -------------------- PIPE MANAGEMENT --------------------
func spawn_pipe():
	if not pipe_container or not pipe_scene:
		return
	
	var game_area_height = viewport_size.y
	var min_pipe_height = game_area_height * min_pipe_height_ratio
	var max_pipe_height = game_area_height * max_pipe_height_ratio
	var gap_center_y = randf_range(min_pipe_height, max_pipe_height)

	var top_pipe = create_pipe(true, gap_center_y)
	var bottom_pipe = create_pipe(false, gap_center_y)
	pipes.append(top_pipe)
	pipes.append(bottom_pipe)
	
	# Score Area setup remains correct, centered on the gap
	var score_area = Area2D.new()
	score_area.position = Vector2(pipe_spawn_x - pipe_width / 2.0, gap_center_y)
	score_area.name = "ScoreArea"
	
	var score_collision = CollisionShape2D.new()
	var score_shape = RectangleShape2D.new()
	score_shape.size = Vector2(10, pipe_gap)
	score_collision.shape = score_shape
	score_collision.position = Vector2(pipe_width / 2.0, 0)
	score_area.add_child(score_collision)
	
	score_area.area_entered.connect(_on_score_area_entered.bind(score_area))
	pipe_container.add_child(score_area)
	pipes.append(score_area)

func create_pipe(is_top: bool, gap_center_y: float) -> Node2D:
	if not pipe_scene:
		push_error("pipe_scene is not assigned!")
		return null
	
	var pipe_instance = pipe_scene.instantiate() as Node2D
	pipe_container.add_child(pipe_instance)
	
	# FIX: Rename the pipe instance so it can be distinguished from "ScoreArea"
	pipe_instance.name = "Pipe" 
	
	var pipe_position: Vector2
	# Visual offset to ensure the pipe art doesn't overlap the gap
	var OFFSET_Y: float = 20.0 

	if is_top:
		pipe_position = Vector2(pipe_spawn_x, (gap_center_y - pipe_gap / 2.0) - OFFSET_Y)
		pipe_instance.scale = Vector2(1, -1)
	else:
		pipe_position = Vector2(pipe_spawn_x, (gap_center_y + pipe_gap / 2.0) + OFFSET_Y)
		pipe_instance.scale = Vector2(1, 1)

	pipe_instance.position = pipe_position
	return pipe_instance

func update_pipes(delta: float):
	for i in range(pipes.size() - 1, -1, -1):
		var pipe = pipes[i]
		pipe.position.x -= pipe_speed * delta
		if pipe.position.x < -pipe_width - 100:
			pipe.queue_free()
			pipes.remove_at(i)

# -------------------- COLLISIONS --------------------
func _on_player_collision(body: Node2D):
	if not is_game_over:
		game_over()

func _on_player_area_collision(area: Area2D):
	# FIX: Only trigger game over if the area is named "Pipe". 
	# This prevents old/lingering "ScoreArea" objects from triggering a loss.
	if area.name == "Pipe" and not is_game_over:
		game_over()

func _on_score_area_entered(area: Area2D, score_area: Area2D):
	if area == player:
		score += 1
		if score_label:
			score_label.text = str(score)
			if score_pop_duration > 0:
				var tween = create_tween()
				tween.tween_property(score_label, "scale", Vector2(score_pop_scale, score_pop_scale), score_pop_duration)
				tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), score_pop_duration)
		
		var idx = pipes.find(score_area)
		if idx != -1:
			pipes.remove_at(idx)
			
		# FIX: Ensure the score area is completely non-functional before being freed
		score_area.monitoring = false
		score_area.set_process_mode(Node.PROCESS_MODE_DISABLED) 
		score_area.queue_free()

# -------------------- GAME FLOW --------------------
func start_game():
	is_game_started = true
	start_label.visible = false
	tap_hint.visible = false
	player_velocity = Vector2.ZERO

func game_over():
	is_game_over = true
	game_over_panel.visible = true
	pushToFirebase()
	if score > high_score:
		high_score = score
		high_score_label.text = "Best: " + str(high_score)
		final_score_label.text = "NEW BEST SCORE!\nScore: " + str(score)
	else:
		final_score_label.text = "Score: " + str(score) + "\nBest: " + str(high_score)

func restart_game():
	for pipe in pipes:
		pipe.queue_free()
	pipes.clear()
	reset_game()

func reset_game():
	is_game_started = false
	is_game_over = false
	score = 0
	elapsed_time = 0.0
	player_velocity = Vector2.ZERO
	pipe_spawn_timer = 0.0
	
	player.position = player_start_position
	player.rotation = 0
	
	score_label.text = "0"
	score_label.scale = Vector2(1, 1)
	start_label.visible = true
	tap_hint.visible = true
	game_over_panel.visible = false
	
func pushToFirebase():
	# Prepare the request
	var url = "http://localhost:3000/api/users"  # Update with your actual URL
	
	# Request body data matching your endpoint
	var body_data = {
		"username": "player123",
		"company": "My Company",
		"email": "player@example.com",
		"points": score  # Optional, defaults to 0 if not provided
	}
	
	# Convert to JSON string
	var json_body = JSON.stringify(body_data)
	
	# Headers for JSON content
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	
	# Make the POST request
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
