extends Button

var http_request: HTTPRequest

func _ready():
	# Create and setup HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# Connect button press signal
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	# Prepare the request
	var url = "http://localhost:3000/api/users"  # Update with your actual URL
	
	# Request body data matching your endpoint
	var body_data = {
		"username": "player123",
		"company": "My Company",
		"email": "player@example.com",
		"points": 0  # Optional, defaults to 0 if not provided
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
