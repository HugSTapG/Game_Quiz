extends Panel

@onready var Pregunta = $Quiz_Container/Pregunta
@onready var Respuesta_Uno = $Quiz_Container/MargenR1/Respuesta_Uno
@onready var Respuesta_Dos = $Quiz_Container/MargenR2/Respuesta_Dos
@onready var Respuesta_Tres = $Quiz_Container/MargenR3/Respuesta_Tres

var question_bank = []
var user_stats = {}
var total_games = 0

var remaining_questions = []
var available_question_indices = []
var current_question = null
var is_penalty = false
var is_game_over = false
var logged_username = ""
var player_id = 0
var current_question_index = -1
var game_seed = 0
var is_final_question = false

var game_start_time = 0
var question_start_time = 0
var total_answer_time = 0
var answers_this_game = 0

func create_default_stats() -> Dictionary:
	return {
		"victories": 0,
		"total_questions_answered": 0,
		"correct_answers": 0,
		"incorrect_answers": 0,
		"fastest_win_time": 0,
		"total_games_played": 0,
		"win_streak": 0,
		"best_win_streak": 0,
		"average_answer_time": 0,
		"total_penalties": 0
	}

func _ready() -> void:
	logged_username = UserManager.get_logged_in_username()
	player_id = multiplayer.get_unique_id()
	
	update_quiz_visibility(false)
	
	GameManager.set_quiz_ui(self)
	load_questions()
	load_user_stats()
	
	Respuesta_Uno.pressed.connect(_on_answer_clicked.bind(0))
	Respuesta_Dos.pressed.connect(_on_answer_clicked.bind(1))
	Respuesta_Tres.pressed.connect(_on_answer_clicked.bind(2))
	
	enable_buttons()
	initialize_player_quiz()
	game_start_time = Time.get_ticks_msec()
	
	var check_timer = Timer.new()
	add_child(check_timer)
	check_timer.wait_time = 0.1
	check_timer.one_shot = false
	check_timer.timeout.connect(_check_pause_state)
	check_timer.start()

func _check_pause_state():
	var current_player = GameManager.get_player_for_username(logged_username)
	if current_player and current_player.is_paused:
		if current_player.current_move_index in current_player.pause_indices:
			if not visible:
				update_quiz_visibility(true)

func update_quiz_visibility(should_be_visible: bool):
	if visible != should_be_visible:
		visible = should_be_visible

func load_questions() -> void:
	var file_path = "res://questions.json" if OS.has_feature("editor") else "questions.json"
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.get_data()
			question_bank = data["questions"]
			print("Questions loaded successfully: ", question_bank.size(), " questions")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	else:
		print("Could not open questions file")

func initialize_player_quiz() -> void:
	var rng = RandomNumberGenerator.new()
	
	var unique_seed = hash(str(player_id) + logged_username + str(Time.get_ticks_msec()))
	rng.seed = unique_seed
	
	print("Initializing quiz for player: ", logged_username)
	print("Player Unique Seed: ", unique_seed)
	print("Player ID: ", player_id)
	
	available_question_indices = range(question_bank.size())
	
	for i in range(available_question_indices.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = available_question_indices[i]
		available_question_indices[i] = available_question_indices[j]
		available_question_indices[j] = temp
	
	select_next_question()

@rpc("any_peer", "reliable")
func sync_first_question() -> void:
	if multiplayer.is_server():
		print("Synchronizing first question")

func select_next_question() -> void:
	if available_question_indices.size() > 0:
		var question_index = available_question_indices.pop_front()
		current_question_index = question_index
		
		current_question = question_bank[question_index]
		
		is_final_question = available_question_indices.size() == 0
		
		show_question(current_question)
	else:
		finish_quiz()

func show_question(question) -> void:
	print("Current Question: ", question["question"])
	print("Answers: ", question["answers"])
	print("Correct Answer Index: ", question["correctAnswerIndex"])
	print("Correct Answer: ", question["answers"][question["correctAnswerIndex"]])
	
	Pregunta.text = question["question"]
	
	Respuesta_Uno.text = question["answers"][0]
	Respuesta_Dos.text = question["answers"][1]
	Respuesta_Tres.text = question["answers"][2]
	
	is_penalty = false
	enable_buttons()

func _on_answer_clicked(answer_index: int) -> void:
	print("Answer button clicked:")
	print("Button Index: ", answer_index)
	print("Button Text: ", get_answer_text(answer_index))
	print("Is Penalty Active: ", is_penalty)
	print("Is Game Over: ", is_game_over)
	print("Current Question Index: ", current_question_index)
	
	if is_penalty or is_game_over:
		print("ACTION BLOCKED - Penalty or Game Over Active")
		return
	
	var answer_time = (Time.get_ticks_msec() - question_start_time) / 1000.0
	
	if multiplayer.is_server():
		validate_answer(player_id, logged_username, answer_index, current_question_index, answer_time)
	else:
		rpc_id(1, "validate_answer", player_id, logged_username, answer_index, current_question_index, answer_time)

func get_answer_text(index: int) -> String:
	match index:
		0: return Respuesta_Uno.text
		1: return Respuesta_Dos.text
		2: return Respuesta_Tres.text
		_: return "Unknown"

@rpc("any_peer", "reliable")
func validate_answer(sender_id: int, sender_username: String, answer_index: int, question_index: int, answer_time: float) -> void:
	if not multiplayer.is_server():
		return
	
	var validated_question = question_bank[question_index]
	var is_correct = (answer_index == validated_question["correctAnswerIndex"])
	
	user_stats[sender_username]["total_questions_answered"] += 1
	
	if is_correct:
		user_stats[sender_username]["correct_answers"] += 1
	else:
		user_stats[sender_username]["incorrect_answers"] += 1
		user_stats[sender_username]["total_penalties"] += 1
	
	var current_avg = user_stats[sender_username]["average_answer_time"]
	var total_questions = user_stats[sender_username]["total_questions_answered"]
	user_stats[sender_username]["average_answer_time"] = (current_avg * (total_questions - 1) + answer_time) / total_questions
	
	rpc("process_answer_result", sender_id, sender_username, is_correct, question_index)

@rpc("any_peer", "call_local")
func process_answer_result(sender_id: int, _sender_username: String, is_correct: bool, question_index: int) -> void:
	if sender_id != player_id:
		return
	
	if question_index != current_question_index:
		print("Mismatched question index - Ignoring result")
		return
	
	if is_correct:
		print("Correct answer received for player: ", logged_username)
		update_quiz_visibility(false)
		
		var current_player = GameManager.get_player_for_username(logged_username)
		if current_player:
			print("Resuming player movement for: ", logged_username)
			current_player.is_paused = false
			current_player.external_resume()
			print("Player unpaused after correct answer: ", logged_username)
		
		if is_final_question:
			finish_quiz()
		else:
			select_next_question()
	else:
		apply_penalty()

func show_quiz_ui() -> void:
	visible = true
	print("Quiz UI visibility set to true for: ", logged_username)

func hide_quiz_ui() -> void:
	visible = false
	print("Quiz UI visibility set to false for: ", logged_username)

func apply_penalty() -> void:
	print("Penalty applied to player: ", logged_username)
	update_quiz_visibility(true)
	
	Respuesta_Uno.add_theme_color_override("font_color", Color.RED)
	Respuesta_Dos.add_theme_color_override("font_color", Color.RED)
	Respuesta_Tres.add_theme_color_override("font_color", Color.RED)
	
	disable_buttons()
	is_penalty = true
	rpc("reset_after_penalty", player_id)

@rpc("any_peer", "call_local")
func reset_after_penalty(sender_id: int) -> void:
	if sender_id != player_id:
		return
	
	await get_tree().create_timer(0.5).timeout
	
	enable_buttons()

func finish_quiz() -> void:
	is_game_over = true
	disable_buttons()
	
	if multiplayer.is_server():
		declare_winner(player_id, logged_username)
	else:
		rpc_id(1, "declare_winner", player_id, logged_username)

@rpc("any_peer", "reliable")
func declare_winner(winning_player_id: int, winning_username: String) -> void:
	if not multiplayer.is_server():
		return
	
	print("Player ", winning_username, " finished their quiz")
	
	rpc("game_over", winning_player_id, winning_username)

func load_user_stats() -> void:
	var file_path = "res://user_stats.json" if OS.has_feature("editor") else "user_stats.json"
	
	user_stats = {
		"Green": create_default_stats(),
		"Purple": create_default_stats()
	}
	total_games = 0
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var loaded_data = json.get_data()
			
			if loaded_data.has("total_games"):
				total_games = loaded_data.get("total_games", 0)
			
			if loaded_data.has("users"):
				for username in user_stats.keys():
					if loaded_data["users"].has(username):
						for stat in user_stats[username].keys():
							if loaded_data["users"][username].has(stat):
								user_stats[username][stat] = loaded_data["users"][username][stat]
			
			print("User stats loaded successfully. Total games: ", total_games)
	
	if not multiplayer.is_server():
		request_stats_sync.rpc_id(1)

@rpc("any_peer")
func request_stats_sync() -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if multiplayer.is_server():
		sync_stats.rpc_id(sender_id, user_stats, total_games)

@rpc("any_peer")
func sync_stats(server_stats: Dictionary, server_total_games: int) -> void:
	if not multiplayer.is_server():
		user_stats = server_stats
		total_games = server_total_games
		save_user_stats()
		print("Stats synchronized with server")

func save_user_stats() -> void:
	var file_path = "res://user_stats.json" if OS.has_feature("editor") else "user_stats.json"
	
	var stats_data = {
		"users": user_stats,
		"total_games": total_games
	}
	
	var json_string = JSON.stringify(stats_data, "", true)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	print("User stats saved successfully. Total games: ", total_games)

@rpc("any_peer", "call_local")
func game_over(winning_player_id: int, winning_username: String) -> void:
	is_game_over = true
	disable_buttons()
	show_quiz_ui()
	
	var players = UserManager.logged_in_users.keys()
	var losing_username = players.duplicate()
	losing_username.erase(winning_username)
	losing_username = losing_username[0] if losing_username.size() > 0 else ""
	
	if multiplayer.is_server():
		user_stats[winning_username]["victories"] += 1
		user_stats[winning_username]["win_streak"] += 1
		user_stats[winning_username]["best_win_streak"] = max(
			user_stats[winning_username]["win_streak"],
			user_stats[winning_username]["best_win_streak"]
		)
		
		if losing_username:
			user_stats[losing_username]["win_streak"] = 0
		
		user_stats[winning_username]["total_games_played"] += 1
		if losing_username:
			user_stats[losing_username]["total_games_played"] += 1
		
		var game_time = (Time.get_ticks_msec() - game_start_time) / 1000.0
		if user_stats[winning_username]["fastest_win_time"] == 0 or game_time < user_stats[winning_username]["fastest_win_time"]:
			user_stats[winning_username]["fastest_win_time"] = game_time
		
		total_games += 1
		save_user_stats()
		sync_stats_to_clients.rpc(user_stats, total_games)
		
		GameManager.end_game()
	
	if player_id == winning_player_id:
		Pregunta.text = winning_username + " wins!"
	else:
		Pregunta.text = losing_username + " loses!"

@rpc("authority", "call_local")
func sync_stats_to_clients(new_stats: Dictionary, new_total_games: int) -> void:
	if not multiplayer.is_server():
		user_stats = new_stats
		total_games = new_total_games
		save_user_stats()
		print("Stats synchronized after game over")

func enable_buttons() -> void:
	Respuesta_Uno.disabled = false
	Respuesta_Dos.disabled = false
	Respuesta_Tres.disabled = false
	
	Respuesta_Uno.remove_theme_color_override("font_color")
	Respuesta_Dos.remove_theme_color_override("font_color")
	Respuesta_Tres.remove_theme_color_override("font_color")
	
	is_penalty = false

func disable_buttons() -> void:
	Respuesta_Uno.disabled = true
	Respuesta_Dos.disabled = true
	Respuesta_Tres.disabled = true
