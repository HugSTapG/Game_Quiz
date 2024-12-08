extends Node

var logged_in_users = {}
var current_logged_in_username = ""

func login(username: String, password: String) -> bool:
	var valid_users = {
		"Green": "GreenP",
		"Purple": "PurpleP"
	}
	
	if username in valid_users and valid_users[username] == password:
		if username in logged_in_users:
			print("User " + username + " is already logged in!")
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
		print("User " + username + " logged out.")

func is_user_logged_in(username: String) -> bool:
	return username in logged_in_users

func reset_logins() -> void:
	logged_in_users.clear()
	current_logged_in_username = ""

func get_logged_in_username() -> String:
	return current_logged_in_username
