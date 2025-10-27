extends CanvasLayer
class_name UIManager

# -------------------- REFERENCES --------------------
var score_label: Label
var high_score_label: Label
var start_container: Control
var game_over_container: Control
var game_manager: Node

# -------------------- VISUAL EFFECTS --------------------
var screen_shake_amount: float = 0.0
var particles_container: Node2D
var combo_multiplier: int = 1
var combo_timer: float = 0.0

# -------------------- SETTINGS --------------------
@export var shake_decay: float = 5.0
@export var max_shake: float = 20.0
@export var combo_timeout: float = 2.0

func _ready():
	setup_ui()
	
func setup_ui():
	# Create main containers
	create_score_ui()
	create_start_screen()
	create_game_over_screen()
	create_particles_container()

# -------------------- SCORE UI --------------------
func create_score_ui():
	# Score label with shadow effect
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "0"
	score_label.position = Vector2(0, 80)
	score_label.size = Vector2(get_viewport().get_visible_rect().size.x, 120)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	# Create custom font settings
	var font_size = 72
	score_label.add_theme_font_size_override("font_size", font_size)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	score_label.add_theme_constant_override("shadow_offset_x", 4)
	score_label.add_theme_constant_override("shadow_offset_y", 4)
	score_label.add_theme_constant_override("shadow_outline_size", 8)
	
	add_child(score_label)
	score_label.hide()
	
	# High score label (top right)
	high_score_label = Label.new()
	high_score_label.name = "HighScoreLabel"
	high_score_label.text = "Best: 0"
	high_score_label.position = Vector2(get_viewport().get_visible_rect().size.x - 250, 30)
	high_score_label.size = Vector2(230, 50)
	high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	high_score_label.add_theme_font_size_override("font_size", 32)
	high_score_label.add_theme_color_override("font_color", Color.GOLD)
	high_score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	high_score_label.add_theme_constant_override("shadow_offset_x", 2)
	high_score_label.add_theme_constant_override("shadow_offset_y", 2)
	high_score_label.add_theme_constant_override("shadow_outline_size", 4)
	
	add_child(high_score_label)
	high_score_label.hide()

# -------------------- START SCREEN --------------------
func create_start_screen():
	var viewport_size = get_viewport().get_visible_rect().size
	
	start_container = Control.new()
	start_container.name = "StartContainer"
	start_container.size = viewport_size
	add_child(start_container)
	
	# Title with glow effect
	var title = Label.new()
	title.text = "Drifti"
	title.position = Vector2(0, viewport_size.y * 0.25)
	title.size = Vector2(viewport_size.x, 150)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.2))  # Golden yellow
	title.add_theme_color_override("font_shadow_color", Color(1, 0.5, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.add_theme_constant_override("shadow_outline_size", 12)
	start_container.add_child(title)
	
	# Animated title effect
	var title_tween = create_tween().set_loops()
	title_tween.tween_property(title, "scale", Vector2(1.1, 1.1), 0.8).set_ease(Tween.EASE_IN_OUT)
	title_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.8).set_ease(Tween.EASE_IN_OUT)
	
	# Tap to start with pulsing effect
	var tap_label = Label.new()
	tap_label.text = "TAP TO START"
	tap_label.position = Vector2(0, viewport_size.y * 0.55)
	tap_label.size = Vector2(viewport_size.x, 80)
	tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_label.add_theme_font_size_override("font_size", 48)
	tap_label.add_theme_color_override("font_color", Color.WHITE)
	tap_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	tap_label.add_theme_constant_override("shadow_offset_x", 3)
	tap_label.add_theme_constant_override("shadow_offset_y", 3)
	tap_label.add_theme_constant_override("shadow_outline_size", 6)
	start_container.add_child(tap_label)
	
	# Pulsing animation
	var tap_tween = create_tween().set_loops()
	tap_tween.tween_property(tap_label, "modulate:a", 0.3, 0.6).set_ease(Tween.EASE_IN_OUT)
	tap_tween.tween_property(tap_label, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "AVOID THE PIPES!"
	instructions.position = Vector2(0, viewport_size.y * 0.7)
	instructions.size = Vector2(viewport_size.x, 60)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 32)
	instructions.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	instructions.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	instructions.add_theme_constant_override("shadow_offset_x", 2)
	instructions.add_theme_constant_override("shadow_offset_y", 2)
	start_container.add_child(instructions)

# -------------------- GAME OVER SCREEN --------------------
func create_game_over_screen():
	var viewport_size = get_viewport().get_visible_rect().size
	
	game_over_container = Control.new()
	game_over_container.name = "GameOverContainer"
	game_over_container.size = viewport_size
	game_over_container.hide()
	add_child(game_over_container)
	
	# Semi-transparent overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = viewport_size
	game_over_container.add_child(overlay)
	
	# Game Over Panel
	var panel = Panel.new()
	panel.name = "GameOverPanel"
	panel.position = Vector2(viewport_size.x * 0.5 - 300, viewport_size.y * 0.5 - 250)
	panel.size = Vector2(600, 500)
	
	# Add background color to panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style_box.border_color = Color(1, 0.8, 0.2)
	style_box.border_width_left = 4
	style_box.border_width_right = 4
	style_box.border_width_top = 4
	style_box.border_width_bottom = 4
	style_box.corner_radius_top_left = 20
	style_box.corner_radius_top_right = 20
	style_box.corner_radius_bottom_left = 20
	style_box.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style_box)
	
	game_over_container.add_child(panel)
	
	# Game Over title
	var game_over_title = Label.new()
	game_over_title.text = "GAME OVER"
	game_over_title.position = Vector2(0, 40)
	game_over_title.size = Vector2(600, 100)
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_title.add_theme_font_size_override("font_size", 68)
	game_over_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	game_over_title.add_theme_color_override("font_shadow_color", Color(0.5, 0, 0, 0.9))
	game_over_title.add_theme_constant_override("shadow_offset_x", 4)
	game_over_title.add_theme_constant_override("shadow_offset_y", 4)
	game_over_title.add_theme_constant_override("shadow_outline_size", 8)
	panel.add_child(game_over_title)
	
	# Score display
	var score_display = Label.new()
	score_display.name = "ScoreDisplay"
	score_display.text = "SCORE: 0"
	score_display.position = Vector2(0, 160)
	score_display.size = Vector2(600, 80)
	score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_display.add_theme_font_size_override("font_size", 52)
	score_display.add_theme_color_override("font_color", Color.WHITE)
	score_display.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	score_display.add_theme_constant_override("shadow_offset_x", 3)
	score_display.add_theme_constant_override("shadow_offset_y", 3)
	panel.add_child(score_display)
	
	# Best score display
	var best_display = Label.new()
	best_display.name = "BestDisplay"
	best_display.text = "BEST: 0"
	best_display.position = Vector2(0, 250)
	best_display.size = Vector2(600, 60)
	best_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_display.add_theme_font_size_override("font_size", 42)
	best_display.add_theme_color_override("font_color", Color.GOLD)
	best_display.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	best_display.add_theme_constant_override("shadow_offset_x", 2)
	best_display.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(best_display)
	
	# Restart button
	var restart_btn = Button.new()
	restart_btn.name = "RestartButton"
	restart_btn.text = "PLAY AGAIN"
	restart_btn.position = Vector2(150, 360)
	restart_btn.size = Vector2(300, 80)
	
	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(0.2, 0.7, 0.3)
	btn_style_normal.corner_radius_top_left = 15
	btn_style_normal.corner_radius_top_right = 15
	btn_style_normal.corner_radius_bottom_left = 15
	btn_style_normal.corner_radius_bottom_right = 15
	
	var btn_style_hover = StyleBoxFlat.new()
	btn_style_hover.bg_color = Color(0.3, 0.9, 0.4)
	btn_style_hover.corner_radius_top_left = 15
	btn_style_hover.corner_radius_top_right = 15
	btn_style_hover.corner_radius_bottom_left = 15
	btn_style_hover.corner_radius_bottom_right = 15
	
	var btn_style_pressed = StyleBoxFlat.new()
	btn_style_pressed.bg_color = Color(0.15, 0.5, 0.2)
	btn_style_pressed.corner_radius_top_left = 15
	btn_style_pressed.corner_radius_top_right = 15
	btn_style_pressed.corner_radius_bottom_left = 15
	btn_style_pressed.corner_radius_bottom_right = 15
	
	restart_btn.add_theme_stylebox_override("normal", btn_style_normal)
	restart_btn.add_theme_stylebox_override("hover", btn_style_hover)
	restart_btn.add_theme_stylebox_override("pressed", btn_style_pressed)
	restart_btn.add_theme_font_size_override("font_size", 38)
	restart_btn.add_theme_color_override("font_color", Color.WHITE)
	restart_btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	restart_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
	panel.add_child(restart_btn)

# -------------------- PARTICLES --------------------
func create_particles_container():
	particles_container = Node2D.new()
	particles_container.name = "ParticlesContainer"
	add_child(particles_container)

func spawn_score_particles(position: Vector2):
	for i in range(10):
		var particle = ColorRect.new()
		var size = randf_range(8, 16)
		particle.size = Vector2(size, size)
		particle.color = Color(randf_range(0.8, 1.0), randf_range(0.8, 1.0), randf_range(0.2, 0.5))
		particle.position = position
		particles_container.add_child(particle)
		
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var distance = randf_range(50, 150)
		var duration = randf_range(0.5, 1.0)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", position + direction * distance, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "scale", Vector2.ZERO, duration)
		tween.chain().tween_callback(particle.queue_free)

func spawn_death_particles(position: Vector2):
	for i in range(30):
		var particle = ColorRect.new()
		var size = randf_range(10, 20)
		particle.size = Vector2(size, size)
		particle.color = Color(randf_range(0.9, 1.0), randf_range(0.2, 0.4), randf_range(0.1, 0.3))
		particle.position = position
		particles_container.add_child(particle)
		
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var distance = randf_range(100, 300)
		var duration = randf_range(0.8, 1.5)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", position + direction * distance, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "rotation", randf_range(-PI * 2, PI * 2), duration)
		tween.chain().tween_callback(particle.queue_free)

# -------------------- SCREEN SHAKE --------------------
func add_screen_shake(amount: float):
	screen_shake_amount = min(screen_shake_amount + amount, max_shake)

func _process(delta: float):
	if screen_shake_amount > 0:
		screen_shake_amount = max(screen_shake_amount - shake_decay * delta, 0)
		offset = Vector2(
			randf_range(-screen_shake_amount, screen_shake_amount),
			randf_range(-screen_shake_amount, screen_shake_amount)
		)
	else:
		offset = Vector2.ZERO

# -------------------- PUBLIC FUNCTIONS --------------------
func show_start_screen():
	start_container.show()
	start_container.modulate.a = 1.0
	score_label.hide()
	high_score_label.hide()
	game_over_container.hide()

func hide_start_screen():
	# Animate out
	var tween = create_tween()
	tween.tween_property(start_container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(start_container.hide)
	
	score_label.show()
	high_score_label.show()
	
	# Animate score in
	score_label.modulate.a = 0
	var score_tween = create_tween()
	score_tween.tween_property(score_label, "modulate:a", 1.0, 0.5)

func update_score(new_score: int, player_pos: Vector2):
	score_label.text = str(new_score)
	
	# Popup animation
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.4, 1.4), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Spawn particles at player position
	spawn_score_particles(player_pos)
	
	# Small screen shake
	add_screen_shake(3)

func update_high_score(new_high_score: int):
	high_score_label.text = "Best: " + str(new_high_score)

func show_game_over(final_score: int, best_score: int, player_pos: Vector2, is_new_record: bool):
	# Death particles
	spawn_death_particles(player_pos)
	
	# Big screen shake
	add_screen_shake(15)
	
	# Show game over screen with delay
	await get_tree().create_timer(0.5).timeout
	
	game_over_container.show()
	game_over_container.modulate.a = 0
	
	var panel = game_over_container.get_node("GameOverPanel")
	panel.scale = Vector2(0.5, 0.5)
	
	# Animate in
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(game_over_container, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Update text
	var score_display = panel.get_node("ScoreDisplay")
	var best_display = panel.get_node("BestDisplay")
	
	if is_new_record:
		score_display.text = "NEW RECORD!"
		score_display.add_theme_color_override("font_color", Color.GOLD)
		
		# Celebrate animation
		var celebrate_tween = create_tween().set_loops()
		celebrate_tween.tween_property(score_display, "scale", Vector2(1.1, 1.1), 0.5)
		celebrate_tween.tween_property(score_display, "scale", Vector2(1.0, 1.0), 0.5)
	else:
		score_display.text = "SCORE: " + str(final_score)
		score_display.add_theme_color_override("font_color", Color.WHITE)
	
	best_display.text = "BEST: " + str(best_score)

func get_restart_button() -> Button:
	if game_over_container:
		var panel = game_over_container.get_node("GameOverPanel")
		if panel:
			return panel.get_node("RestartButton")
	return null
