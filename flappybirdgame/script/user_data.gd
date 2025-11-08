extends Node


# Store user data globally
var username: String = ""
var email: String = ""
var company: String = ""
var phone: String = ""

var highestScore: float = 0.0

const API_SECRET = "k9mP2xL7nQ4vB8wR6tY3hJ5zF1gK0sD9cX7eN2aM4pU8qW6iO3rT5yH1jV0bL9"

var firebase_config = {
  "apiKey": "AIzaSyAtIfN5IwWv2wGksqp8W8hWQrVK0tbFQB0",
  "authDomain": "messe-flappy-bir.firebaseapp.com",
  "databaseURL": "https://messe-flappy-bir-default-rtdb.europe-west1.firebasedatabase.app",
  "projectId": "messe-flappy-bir",
  "storageBucket": "messe-flappy-bir.firebasestorage.app",
  "messagingSenderId": "339716507471",
  "appId": "1:339716507471:web:fb0734a02440872334273a",
  "measurementId": "G-GF92G9J5X7"
};

var database: RealtimeDatabase
var auth: Authentication

func _init() -> void:
	FirebaseLite.initialize(firebase_config)
	database = FirebaseLite.RealtimeDatabase
	auth = FirebaseLite.Authentication
	
func _ready() -> void:
	await login_right_away()
	set_highest_score()

func login_right_away():
	var result = await FirebaseLite.Authentication.initializeAuth(3, "u1901470576@gmail.com", "driftiMesse")
	FirebaseLite.authToken = result.idToken

func set_user_data(p_username: String, p_email: String, p_company: String, p_phone: String) -> void:
	username = p_username
	email = p_email
	company = p_company
	phone = p_phone
	
func get_highest_score() -> float:
	return highestScore

func get_user_data() -> Dictionary:
	return {
		"username": username,
		"email": email,
		"company": company,
		"phone": phone
	}

func clear_user_data() -> void:
	username = ""
	email = ""
	company = ""
	phone = ""
	
func set_highest_score() -> void:
	# Read all users from database
	var data = await FirebaseLite.RealtimeDatabase.read("/users")
	
	
	var highest_score = 0
	
	# Loop through all users and find highest score
	for user_id in data.keys():
		var user = data[user_id]
		if user.has("points"):
			var points = user["points"]
			if points > highest_score:
				highest_score = points

	highestScore = highest_score

	
func push_score_to_firebase(points: int = 0):
	var ref = await FirebaseLite.RealtimeDatabase.push("/users", {
		"username": username,
		"email": email,
		"company": company,
		"phone": phone,
		"points": points,
	})
	return ref
