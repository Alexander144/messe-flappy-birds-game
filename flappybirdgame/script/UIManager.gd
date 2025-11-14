extends CanvasLayer
class_name UIManager

# -------------------- REFERENCES --------------------
var score_label: Label
var high_score_label: Label
var start_container: Control
var game_over_container: Control
var game_manager: Node
var highest_score: float = 0

# -------------------- VISUAL EFFECTS --------------------
var screen_shake_amount: float = 0.0
var particles_container: Node2D
var combo_multiplier: int = 1
var combo_timer: float = 0.0

# -------------------- SETTINGS --------------------
@export var shake_decay: float = 5.0
@export var max_shake: float = 20.0
@export var combo_timeout: float = 2.0
@export var start_scene_path: String = "res://scenes/start.tscn"  # Adjust path as needed

func _ready():
	setup_ui()
	print('UI Manager ready')
	
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
	score_label.text = "0 poeng"
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
	score_label.pivot_offset = score_label.get_size() / 2
	
	add_child(score_label)
	score_label.hide()
	
	# High score label (top right)
	high_score_label = Label.new()
	high_score_label.name = "HighScoreLabel"
	var l = UserData.get_highest_score()
	high_score_label.text = "Best: " + str(int(l))
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
	
	var bg = ColorRect.new()
	bg.color = Color(0.031, 0.000, 0.267, 0.30)  # Lavender color like in the image
	bg.size = viewport_size
	start_container.add_child(bg)
	
	# DRIFTI branding at top
	var branding = Label.new()
	branding.text = "DRIFTI"
	branding.position = Vector2(30, 30)
	branding.size = Vector2(200, 50)
	branding.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	branding.add_theme_font_size_override("font_size", 32)
	branding.add_theme_color_override("font_color", Color(0.6, 0.4, 0.7))  # Purple

	
	start_container.add_child(branding)
	
	# Create a container to hold the title
	var title_container = CenterContainer.new()
	title_container.size = Vector2(viewport_size.x, 150)
	title_container.position = Vector2(0, viewport_size.y * 0.25)
	start_container.add_child(title_container)
	
	# Create title label
	var title = Label.new()
	title.text = "Flappy Bird"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color(0.2, 0.15, 0.3))
	title.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.3))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.add_theme_constant_override("shadow_outline_size", 4)
	title_container.add_child(title)

	# Animate scale from center
	var title_tween = create_tween().set_loops()
	title_tween.tween_property(title, "scale", Vector2(1.05, 1.05), 0.8).set_ease(Tween.EASE_IN_OUT)
	title_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.8).set_ease(Tween.EASE_IN_OUT)
	# Tap to start with pulsing effect
	var tap_label = Label.new()
	tap_label.text = "Trykk for å starte"
	tap_label.position = Vector2(0, viewport_size.y * 0.55)
	tap_label.size = Vector2(viewport_size.x, 80)
	tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_label.add_theme_font_size_override("font_size", 36)
	tap_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.3))
	start_container.add_child(tap_label)
	
	# Pulsing animation
	var tap_tween = create_tween().set_loops()
	tap_tween.tween_property(tap_label, "modulate:a", 0.4, 0.6).set_ease(Tween.EASE_IN_OUT)
	tap_tween.tween_property(tap_label, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Unngå rørene!"
	instructions.position = Vector2(0, viewport_size.y * 0.7)
	instructions.size = Vector2(viewport_size.x, 60)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 28)
	instructions.add_theme_color_override("font_color", Color(0.3, 0.25, 0.4))
	start_container.add_child(instructions)

# -------------------- GAME OVER SCREEN --------------------
func create_game_over_screen():
	var viewport_size = get_viewport().get_visible_rect().size
	
	game_over_container = Control.new()
	game_over_container.name = "GameOverContainer"
	game_over_container.size = viewport_size
	game_over_container.hide()
	add_child(game_over_container)
	

	var overlay = ColorRect.new()
	overlay.color = Color(0.031, 0.000, 0.267, 0.30)  
	overlay.size = viewport_size
	game_over_container.add_child(overlay)
	
	# DRIFTI branding at top
	var branding = Label.new()
	branding.text = "DRIFTI"
	branding.position = Vector2(30, 30)
	branding.size = Vector2(200, 50)
	branding.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	branding.add_theme_font_size_override("font_size", 32)
	branding.add_theme_color_override("font_color", Color(0.6, 0.4, 0.7))  # Purple
	game_over_container.add_child(branding)
	
	# White content panel
	var panel = Panel.new()
	panel.name = "GameOverPanel"
	panel.position = Vector2(viewport_size.x * 0.5 - 300, viewport_size.y * 0.5 - 280)
	panel.size = Vector2(600, 560)
	panel.clip_contents = true  # Allow mascot to overflow
	
	# White rounded background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1, 1, 1, 1)  # White
	style_box.corner_radius_top_left = 20
	style_box.corner_radius_top_right = 20
	style_box.corner_radius_bottom_left = 20
	style_box.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style_box)
	
	game_over_container.add_child(panel)
	
	# Mascot image - positioned at bottom-right, anchored to panel size
	var mascot = TextureRect.new()
	mascot.name = "Mascot"
	var mascot_size = 180
	mascot.position = Vector2(panel.size.x - mascot_size, panel.size.y - 100 - mascot_size)  # Bottom-right with overflow
	mascot.size = Vector2(mascot_size, mascot_size)
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.texture = load("res://assets/maskot3.png")
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
	panel.add_child(mascot)
	
	# Score at top
	var score_top = Label.new()
	score_top.name = "ScoreTop"
	score_top.text = "202 poeng"
	score_top.position = Vector2(0, 30)
	score_top.size = Vector2(600, 60)
	score_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_top.add_theme_font_size_override("font_size", 42)
	score_top.add_theme_color_override("font_color", Color(0.15, 0.1, 0.25))  # Dark purple/navy
	panel.add_child(score_top)
	
	# "Å nei!" text
	var oh_no = Label.new()
	oh_no.name = "OhNoLabel"
	oh_no.text = "Å nei!"
	oh_no.position = Vector2(0, 100)
	oh_no.size = Vector2(600, 40)
	oh_no.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oh_no.add_theme_font_size_override("font_size", 24)
	oh_no.add_theme_color_override("font_color", Color(0.3, 0.25, 0.35))
	panel.add_child(oh_no)
	
	# "Kortslutning!" title
	var title = Label.new()
	title.name = "MainTitle"
	title.text = "Kortslutning!"
	title.position = Vector2(0, 135)
	title.size = Vector2(600, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.15, 0.1, 0.25))  # Dark purple/navy
	panel.add_child(title)
	
	# Description text
	var desc = RichTextLabel.new()
	desc.name = "DescriptionLabel"
	desc.bbcode_enabled = true
	desc.text = "[center]Du fikk [b]27 poeng[/b] for å sikringsrøk,\nbara [b]3 poeng[/b] fra toppen![/center]"
	desc.position = Vector2(50, 220)
	desc.size = Vector2(500, 80)
	desc.add_theme_font_size_override("normal_font_size", 18)
	desc.add_theme_font_size_override("bold_font_size", 18)
	desc.add_theme_color_override("default_color", Color(0.3, 0.25, 0.35))
	desc.fit_content = true
	panel.add_child(desc)
	
	# "Er du klar for å prøve igjen?" text
	var ready_text = Label.new()
	ready_text.text = "Er du klar for å prøve igjen?"
	ready_text.position = Vector2(0, 320)
	ready_text.size = Vector2(600, 40)
	ready_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ready_text.add_theme_font_size_override("font_size", 20)
	ready_text.add_theme_color_override("font_color", Color(0.3, 0.25, 0.35))
	panel.add_child(ready_text)
	
	# "Prøv igjen" button (purple)
	var restart_btn = Button.new()
	restart_btn.name = "RestartButton"
	restart_btn.text = "Prøv igjen"
	restart_btn.position = Vector2(150, 375)
	restart_btn.size = Vector2(300, 60)
	
	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(0.5, 0.3, 0.7)  # Purple
	btn_style_normal.corner_radius_top_left = 30
	btn_style_normal.corner_radius_top_right = 30
	btn_style_normal.corner_radius_bottom_left = 30
	btn_style_normal.corner_radius_bottom_right = 30
	
	var btn_style_hover = StyleBoxFlat.new()
	btn_style_hover.bg_color = Color(0.6, 0.4, 0.8)  # Lighter purple
	btn_style_hover.corner_radius_top_left = 30
	btn_style_hover.corner_radius_top_right = 30
	btn_style_hover.corner_radius_bottom_left = 30
	btn_style_hover.corner_radius_bottom_right = 30
	
	var btn_style_pressed = StyleBoxFlat.new()
	btn_style_pressed.bg_color = Color(0.4, 0.2, 0.6)  # Darker purple
	btn_style_pressed.corner_radius_top_left = 30
	btn_style_pressed.corner_radius_top_right = 30
	btn_style_pressed.corner_radius_bottom_left = 30
	btn_style_pressed.corner_radius_bottom_right = 30
	
	restart_btn.add_theme_stylebox_override("normal", btn_style_normal)
	restart_btn.add_theme_stylebox_override("hover", btn_style_hover)
	restart_btn.add_theme_stylebox_override("pressed", btn_style_pressed)
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.add_theme_color_override("font_color", Color.WHITE)
	restart_btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.95, 0.95))
	restart_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	
	panel.add_child(restart_btn)
	
	# "Ny spiller" link button
	var new_game_btn = Button.new()
	new_game_btn.name = "NewGameButton"
	new_game_btn.text = "Ny spiller"
	new_game_btn.position = Vector2(220, 450)
	new_game_btn.size = Vector2(160, 40)
	
	var link_style = StyleBoxFlat.new()
	link_style.bg_color = Color(1, 1, 1, 0)  # Transparent
	
	new_game_btn.add_theme_stylebox_override("normal", link_style)
	new_game_btn.add_theme_stylebox_override("hover", link_style)
	new_game_btn.add_theme_stylebox_override("pressed", link_style)
	new_game_btn.add_theme_font_size_override("font_size", 18)
	new_game_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.7))
	new_game_btn.add_theme_color_override("font_hover_color", Color(0.6, 0.4, 0.8))
	new_game_btn.add_theme_color_override("font_pressed_color", Color(0.4, 0.2, 0.6))
	
	# Connect the button to load start scene
	new_game_btn.pressed.connect(_on_new_game_pressed)
	
	panel.add_child(new_game_btn)



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

#func _process(delta: float):

#	if screen_shake_amount > 0:
#		screen_shake_amount = max(screen_shake_amount - shake_decay * delta, 0)
#		offset = Vector2(
#			randf_range(-screen_shake_amount, screen_shake_amount),
#			randf_range(-screen_shake_amount, screen_shake_amount)
#		)
#	else:
#		offset = Vector2.ZERO

# -------------------- BUTTON CALLBACKS --------------------
func _on_new_game_pressed():
	# Change to start scene
	var user_data = UserData.get_user_data()
	
	# Push to Firebase with user data and initial points
	await UserData.push_score_to_firebase(highest_score)
	get_tree().change_scene_to_file(start_scene_path)

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
	if new_score > highest_score:
		highest_score = new_score
	score_label.text = str(new_score) + " poeng"
	
	# Popup animation
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

	
	# Spawn particles at player position
	spawn_score_particles(player_pos)

func update_high_score(new_high_score: int):
	var l = UserData.get_highest_score()
	high_score_label.text = "Best: " + str(int(l))

func show_game_over(final_score: int, best_score: int, player_pos: Vector2, is_new_record: bool):
	# Death particles
	spawn_death_particles(player_pos)
	
	# Show game over screen with delay
	await get_tree().create_timer(0.5).timeout
	
	game_over_container.show()
	game_over_container.modulate.a = 0
	
	var panel = game_over_container.get_node("GameOverPanel")
	if panel == null:
		print("ERROR: GameOverPanel not found!")
		return
		
	panel.scale = Vector2(0.8, 0.8)
	panel.position.y += 50
	
	# Animate in
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(game_over_container, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "position:y", panel.position.y - 50, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Update mascot image based on new record
	var mascot = panel.get_node("Mascot") as TextureRect
	if mascot:
		if is_new_record:
			mascot.texture = load("res://assets/maskot4.png")
		else:
			mascot.texture = load("res://assets/maskot3.png")
	
	# Update score text at top (hide it for new record)
	var score_top = panel.get_node("ScoreTop")
	if score_top:
		if is_new_record:
			score_top.hide()
		else:
			score_top.show()
			score_top.text = str(final_score) + " poeng"
	
	# Update title based on new record
	var title = panel.get_node("MainTitle") as Label
	if title:
		if is_new_record:
			title.text = "Ny rekord!"
		else:
			title.text = "Kortslutning!"
	
	# Update "Å nei!" text (hide it for new record)
	var oh_no = panel.get_node("OhNoLabel") as Label
	if oh_no:
		if is_new_record:
			oh_no.hide()
		else:
			oh_no.show()
	
	# Update description with dynamic values
	var points_from_top = abs(final_score - int(UserData.get_highest_score()))
	var desc = panel.get_node("DescriptionLabel") as RichTextLabel
	if desc:
		if is_new_record:
			desc.text = "[center]Du leder strømmen med hele\n[b]" + str(final_score) + " poeng[/b]![/center]"
		else:
			desc.text = "[center]Du fikk [b]" + str(final_score) + " poeng[/b] før sikringsrøk,\nbara [b]" + str(points_from_top) + " poeng[/b] fra toppen![/center]"

func get_restart_button() -> Button:
	if game_over_container:
		var panel = game_over_container.get_node("GameOverPanel")
		if panel:
			return panel.get_node("RestartButton")
	return null

func get_new_game_button() -> Button:
	if game_over_container:
		var panel = game_over_container.get_node("GameOverPanel")
		if panel:
			return panel.get_node("NewGameButton")
	return null
