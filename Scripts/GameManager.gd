extends Node

var green_player = null
var purple_player = null
var quiz_ui = null

var is_game_active = false
var current_username = ""

func set_green_player(player):
	green_player = player
	print("Green player set: ", player)

func set_purple_player(player):
	purple_player = player
	print("Purple player set: ", player)

func set_quiz_ui(ui):
	quiz_ui = ui
	print("Quiz UI set: ", ui)

func get_player_for_username(username: String):
	match username:
		"Green": return green_player
		"Purple": return purple_player
		_: 
			print("No player found for username: ", username)
			return null

func show_quiz_for_current_player() -> void:
	print("Attempting to show quiz for: ", current_username)
	if quiz_ui:
		var current_player = get_player_for_username(current_username)
		if current_player:
			print("Current player found, showing quiz UI")
			quiz_ui.visible = true
			print("Quiz UI visibility set to: ", quiz_ui.visible)

func pause_all_players():
	print("Pausing all players")
	
	if green_player:
		green_player.is_paused = true
		if current_username == "Green":
			green_player.external_pause()
			if quiz_ui:
				quiz_ui.update_quiz_visibility(true)
	
	if purple_player:
		purple_player.is_paused = true
		if current_username == "Purple":
			purple_player.external_pause()
			if quiz_ui:
				quiz_ui.update_quiz_visibility(true)

func resume_all_players():
	print("Attempting to resume players")
	var current_player = get_player_for_username(current_username)
	if current_player:
		current_player.is_paused = false
		current_player.external_resume()
		print("Player resumed: ", current_username)
	
	if quiz_ui:
		quiz_ui.update_quiz_visibility(false)

func start_game(username: String):
	is_game_active = true
	current_username = username
	print("Game started for: ", username)
	
	if quiz_ui:
		quiz_ui.visible = false

func end_game():
	is_game_active = false
	pause_all_players()
	
	var players_node = get_tree().get_root().find_child("Players", true, false)
	if players_node:
		players_node.visible = true
	
	print("Game ended")
