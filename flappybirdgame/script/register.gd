extends Control

@export var navn_field: TextEdit
@export var mail_field: TextEdit
@export var bedrift_navn_field: TextEdit
@export var tlf_field: TextEdit
@export var button: Button

var error_label: Label

func _ready() -> void:
	# Create error label
	error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.add_theme_color_override("font_color", Color.RED)
	error_label.hide()
	
	# Add error label to the parent of the button
	if button and button.get_parent():
		button.get_parent().get_parent().add_child(error_label)
	
	# Connect button
	if button:
		button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	# TextEdit uses .text instead of .text for the content
	var username = navn_field.text.strip_edges()
	var email = mail_field.text.strip_edges()
	var company = bedrift_navn_field.text.strip_edges()
	var phone = tlf_field.text.strip_edges()
	
	# Validate fields
	var missing_fields = []
	
	if username.is_empty():
		missing_fields.append("Navn")
	
	if email.is_empty():
		missing_fields.append("E-post")
	
	if company.is_empty():
		missing_fields.append("Bedriftsnavn")
	
	if phone.is_empty():
		missing_fields.append("Telefon")
	
	# Show error if any fields are missing
	if missing_fields.size() > 0:
		show_error("Vennligst fyll ut: " + ", ".join(missing_fields))
		return
	
	# Validate email format
	if not is_valid_email(email):
		show_error("Vennligst skriv inn en gyldig e-postadresse")
		return
	
	# Store data in UserData singleton
	UserData.set_user_data(username, email, company, phone)
	
	# Change scene
	get_tree().change_scene_to_file("res://scenes/flappyBird.tscn")

func show_error(message: String) -> void:
	if error_label:
		error_label.text = message
		error_label.show()
		
		# Optional: Hide error after 3 seconds
		await get_tree().create_timer(3.0).timeout
		error_label.hide()

func is_valid_email(email: String) -> bool:
	# Simple email validation
	return email.contains("@") and email.contains(".")
