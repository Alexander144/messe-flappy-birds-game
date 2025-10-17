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
@export var ground_scroll_1: Sprite2D
@export var ground_scroll_2: Sprite2D
@export var ground_scroll_3: Sprite2D
@export var ground_body: StaticBody2D
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
@export var pipe_texture: Texture2D
@export var ground_texture: Texture2D
@export var background_texture: Texture2D

# -------------------- GAMEPLAY SETTINGS --------------------
@export_group("Player Settings")
@export var gravity: float = 1200.0
@export var jump_force: float = -450.0
@export var player_start_position: Vector2 = Vector2(200, 300)
@export var max_fall_speed: float = 800.0
@export var rotation_speed: float = 5.0
@export var max_rotation_down: float = 0.9
@export var max_rotation_up: float = -0.6

@export_group("Pipe Settings")
@export var pipe_gap: float = 220.0
@export var pipe_width: float = 80.0
@export var pipe_speed: float = 180.0
@export var pipe_spawn_interval: float = 2.2
@export var pipe_spawn_x: float = 650.0
@export var min_pipe_height: float = 150.0
@export var max_pipe_height: float = 400.0

@export_group("Scroll Settings")
@export var ground_scroll_speed: float = 180.0
@export var background_scroll_speed: float = 50.0

@export_group("Visual Settings")
@export var ground_height: float = 100.0
@export var player_idle_bob_speed: float = 200.0
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

# -------------------- PIPES --------------------
var pipes: Array = []
var pipe_spawn_timer: float = 0.0

# -------------------- VIEWPORT --------------------
var viewport_size: Vector2

# -------------------- INITIALIZATION --------------------
func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	
	# Validate all node references
	if not validate_nodes():
		push_error("GameManager: Missing required node references!")
		return
	
	# Apply textures
	apply_textures()
	
	# Setup initial positions
	setup_positions()
	
	# Setup UI
	setup_ui_properties()
	
	# Connect signals
	connect_signals()
	
	# Start game
	reset_game()

func validate_nodes() -> bool:
	var valid = true
	
	if not player:
		push_error("Player node not assigned!")
		valid = false
	if not player_sprite:
		push_error("PlayerSprite node not assigned!")
		valid = false
	if not pipe_container:
		push_error("PipeContainer node not assigned!")
		valid = false
	if not score_label:
		push_error("ScoreLabel node not assigned!")
		valid = false
	if not game_over_panel:
		push_error("GameOverPanel node not assigned!")
		valid = false
	if not restart_button:
		push_error("RestartButton node not assigned!")
		valid = false
	
	return valid

func apply_textures():
	# Apply bird texture
	if bird_texture and player_sprite:
		player_sprite.texture = bird_texture
	
	# Apply background textures
	if background_texture:
		if bg_sprite_1:
			bg_sprite_1.texture = background_texture
		if bg_sprite_2:
			bg_sprite_2.texture = background_texture
	
	# Apply ground textures
	if ground_texture:
		if ground_scroll_1:
			ground_scroll_1.texture = ground_texture
		if ground_scroll_2:
			ground_scroll_2.texture = ground_texture
		if ground_scroll_3:
			ground_scroll_3.texture = ground_texture

func setup_positions():
	# Center camera
	if camera:
		camera.position = viewport_size / 2
	
	# Position background sprites for seamless scrolling
	if background_texture:
		if bg_sprite_1:
			bg_sprite_1.position = Vector2.ZERO
		if bg_sprite_2:
			bg_sprite_2.position = Vector2(background_texture.get_width(), 0)
	
	# Position ground sprites for seamless scrolling
	if ground_texture:
		var ground_y = viewport_size.y - ground_height
		if ground_scroll_1:
			ground_scroll_1.position = Vector2(0, ground_y)
		if ground_scroll_2:
			ground_scroll_2.position = Vector2(ground_texture.get_width(), ground_y)
		if ground_scroll_3:
			ground_scroll_3.position = Vector2(ground_texture.get_width() * 2, ground_y)
	
	# Set player start position
	if player:
		player.position = player_start_position

func setup_ui_properties():
	# Apply colors
	if score_label:
		score_label.add_theme_color_override("font_color", score_color)
	
	if high_score_label:
		high_score_label.add_theme_color_override("font_color", high_score_color)
	
	if game_over_label:
		game_over_label.add_theme_color_override("font_color", game_over_color)

func connect_signals():
	# Player collision
	if player:
		player.body_entered.connect(_on_player_collision)
		player.area_entered.connect(_on_player_area_collision)
	
	# Restart button
	if restart_button:
		restart_button.pressed.connect(restart_game)

# -------------------- INPUT HANDLING --------------------
func _input(event):
	# Handle touch and mouse input
	if event is InputEventScreenTouch:
		if event.pressed:
			handle_tap()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
		# Idle bobbing animation
		if player:
			player.position.y = player_start_position.y + sin(Time.get_ticks_msec() / player_idle_bob_speed) * player_idle_bob_amount
		return
	
	# Apply gravity
	player_velocity.y += gravity * delta
	player_velocity.y = min(player_velocity.y, max_fall_speed)
	
	# Move player
	if player:
		player.position += player_velocity * delta
		
		# Rotate player
		var target_rotation = clamp(player_velocity.y / 400.0, max_rotation_up, max_rotation_down)
		player.rotation = lerp(player.rotation, target_rotation, delta * rotation_speed)
	
	# Spawn pipes
	pipe_spawn_timer += delta
	if pipe_spawn_timer >= pipe_spawn_interval:
		spawn_pipe()
		pipe_spawn_timer = 0.0
	
	# Update pipes
	update_pipes(delta)
	
	# Scroll backgrounds
	scroll_background(delta)
	scroll_ground(delta)
	
	# Check bounds
	if player and (player.position.y > viewport_size.y or player.position.y < -50):
		game_over()

func scroll_background(delta: float):
	if not background_texture:
		return
	
	var bg_width = background_texture.get_width()
	
	if bg_sprite_1:
		bg_sprite_1.position.x -= background_scroll_speed * delta
		if bg_sprite_1.position.x <= -bg_width:
			bg_sprite_1.position.x += bg_width * 2
	
	if bg_sprite_2:
		bg_sprite_2.position.x -= background_scroll_speed * delta
		if bg_sprite_2.position.x <= -bg_width:
			bg_sprite_2.position.x += bg_width * 2

func scroll_ground(delta: float):
	if not ground_texture:
		return
	
	var ground_width = ground_texture.get_width()
	
	if ground_scroll_1:
		ground_scroll_1.position.x -= ground_scroll_speed * delta
		if ground_scroll_1.position.x <= -ground_width:
			ground_scroll_1.position.x += ground_width * 3
	
	if ground_scroll_2:
		ground_scroll_2.position.x -= ground_scroll_speed * delta
		if ground_scroll_2.position.x <= -ground_width:
			ground_scroll_2.position.x += ground_width * 3
	
	if ground_scroll_3:
		ground_scroll_3.position.x -= ground_scroll_speed * delta
		if ground_scroll_3.position.x <= -ground_width:
			ground_scroll_3.position.x += ground_width * 3

# -------------------- PIPE MANAGEMENT --------------------
func spawn_pipe():
	if not pipe_container or not pipe_texture:
		return
	
	var pipe_height = randf_range(min_pipe_height, max_pipe_height)
	
	# Create top pipe
	var top_pipe = create_pipe(true, pipe_height)
	pipes.append(top_pipe)
	
	# Create bottom pipe
	var bottom_pipe = create_pipe(false, pipe_height)
	pipes.append(bottom_pipe)
	
	# Create score trigger
	var score_area = Area2D.new()
	score_area.position = Vector2(pipe_spawn_x + pipe_width / 2, viewport_size.y / 2)
	score_area.name = "ScoreArea"
	pipe_container.add_child(score_area)
	
	var score_collision = CollisionShape2D.new()
	var score_shape = RectangleShape2D.new()
	score_shape.size = Vector2(10, viewport_size.y)
	score_collision.shape = score_shape
	score_area.add_child(score_collision)
	
	score_area.area_entered.connect(_on_score_area_entered)
	pipes.append(score_area)

func create_pipe(is_top: bool, gap_center_y: float) -> StaticBody2D:
	var pipe = StaticBody2D.new()
	pipe.name = "Pipe"
	pipe_container.add_child(pipe)
	
	var sprite = Sprite2D.new()
	sprite.texture = pipe_texture
	sprite.centered = false  # Important: don't center the sprite
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	if is_top:
		# Top pipe extends from top of screen (y=0) down to gap
		var pipe_height = gap_center_y - pipe_gap / 2
		pipe.position = Vector2(pipe_spawn_x, 0)
		
		# Sprite positioning
		sprite.flip_v = true
		sprite.position = Vector2(-pipe_width / 2, 0)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, pipe_width, pipe_height)
		
		# Collision shape
		shape.size = Vector2(pipe_width, pipe_height)
		collision.position = Vector2(0, pipe_height / 2)
	else:
		# Bottom pipe extends from gap down to ground
		var pipe_start_y = gap_center_y + pipe_gap / 2
		var pipe_height = viewport_size.y - ground_height - pipe_start_y
		pipe.position = Vector2(pipe_spawn_x, pipe_start_y)
		
		# Sprite positioning
		sprite.position = Vector2(-pipe_width / 2, 0)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, pipe_width, pipe_height)
		
		# Collision shape
		shape.size = Vector2(pipe_width, pipe_height)
		collision.position = Vector2(0, pipe_height / 2)
	
	collision.shape = shape
	pipe.add_child(sprite)
	pipe.add_child(collision)
	
	return pipe

func update_pipes(delta: float):
	for i in range(pipes.size() - 1, -1, -1):
		var pipe = pipes[i]
		pipe.position.x -= pipe_speed * delta
		
		if pipe.position.x < -100:
			pipe.queue_free()
			pipes.remove_at(i)

# -------------------- COLLISIONS --------------------
func _on_player_collision(body: Node2D):
	if not is_game_over:
		game_over()

func _on_player_area_collision(area: Area2D):
	if not is_game_over:
		game_over()

func _on_score_area_entered(area: Area2D):
	if area == player:
		score += 1
		if score_label:
			score_label.text = str(score)
			
			# Score pop animation
			if score_pop_duration > 0:
				var tween = create_tween()
				tween.tween_property(score_label, "scale", Vector2(score_pop_scale, score_pop_scale), score_pop_duration)
				tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), score_pop_duration)

# -------------------- GAME FLOW --------------------
func start_game():
	is_game_started = true
	
	if start_label:
		start_label.visible = false
	if tap_hint:
		tap_hint.visible = false
	
	player_velocity = Vector2.ZERO

func game_over():
	is_game_over = true
	
	if game_over_panel:
		game_over_panel.visible = true
	
	# Update high score
	if score > high_score:
		high_score = score
		if high_score_label:
			high_score_label.text = "Best: " + str(high_score)
		if final_score_label:
			final_score_label.text = "NEW BEST!\n" + str(score)
	else:
		if final_score_label:
			final_score_label.text = "Score: " + str(score) + "\nBest: " + str(high_score)

func restart_game():
	# Clear pipes
	for pipe in pipes:
		pipe.queue_free()
	pipes.clear()
	
	reset_game()

func reset_game():
	is_game_started = false
	is_game_over = false
	score = 0
	player_velocity = Vector2.ZERO
	pipe_spawn_timer = 0.0
	
	if player:
		player.position = player_start_position
		player.rotation = 0
	
	if score_label:
		score_label.text = "0"
		score_label.scale = Vector2(1, 1)
	
	if start_label:
		start_label.visible = true
	if tap_hint:
		tap_hint.visible = true
	if game_over_panel:
		game_over_panel.visible = false
