extends Node

var logged_in_users = {}
var current_logged_in_username = ""
var valid_users = {}

func _ready():
	load_users()

func load_users() -> void:
	var file_path = "res://users.json" if OS.has_feature("editor") else "users.json"
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.get_data()
			valid_users = data["users"]

func login(username: String, password: String) -> bool:
	if username in valid_users and valid_users[username] == password:
		if username in logged_in_users:
			return false
		
		logged_in_users[username] = true
		current_logged_in_username = username
		return true
	
	return false

func logout(username: String) -> void:
	if username in logged_in_users:
		logged_in_users.erase(username)
		if current_logged_in_username == username:
			current_logged_in_username = ""

func is_user_logged_in(username: String) -> bool:
	return username in logged_in_users

func reset_logins() -> void:
	logged_in_users.clear()
	current_logged_in_username = ""

func get_logged_in_username() -> String:
	return current_logged_in_username
