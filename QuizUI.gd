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

func _ready() -> void:
	load_questions()
	load_user_stats()
	
	logged_username = UserManager.get_logged_in_username()
	player_id = multiplayer.get_unique_id()
	
	Respuesta_Uno.pressed.connect(_on_answer_clicked.bind(0))
	Respuesta_Dos.pressed.connect(_on_answer_clicked.bind(1))
	Respuesta_Tres.pressed.connect(_on_answer_clicked.bind(2))
	
	enable_buttons()
	initialize_player_quiz()
	
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
		else:
			pass
	else:
		pass

func initialize_player_quiz() -> void:
	var rng = RandomNumberGenerator.new()
	
	var unique_seed = hash(str(player_id) + logged_username + str(Time.get_ticks_msec()))
	rng.seed = unique_seed
	
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
		pass

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
	Pregunta.text = question["question"]
	Respuesta_Uno.text = question["answers"][0]
	Respuesta_Dos.text = question["answers"][1]
	Respuesta_Tres.text = question["answers"][2]
	
	is_penalty = false
	enable_buttons()

func _on_answer_clicked(answer_index: int) -> void:
	if is_penalty or is_game_over:
		return
	
	if multiplayer.is_server():
		validate_answer(player_id, logged_username, answer_index, current_question_index)
	else:
		rpc_id(1, "validate_answer", player_id, logged_username, answer_index, current_question_index)

func get_answer_text(index: int) -> String:
	match index:
		0: return Respuesta_Uno.text
		1: return Respuesta_Dos.text
		2: return Respuesta_Tres.text
		_: return "Unknown"

@rpc("any_peer", "reliable")
func validate_answer(sender_id: int, _sender_username: String, answer_index: int, question_index: int) -> void:
	if not multiplayer.is_server():
		return
	
	if question_index < 0 or question_index >= question_bank.size():
		return
	
	var validated_question = question_bank[question_index]
	
	var is_correct = (answer_index == validated_question["correctAnswerIndex"])
	
	rpc("process_answer_result", sender_id, _sender_username, is_correct, question_index)

@rpc("any_peer", "call_local")
func process_answer_result(sender_id: int, _sender_username: String, is_correct: bool, question_index: int) -> void:
	if sender_id != player_id:
		return
	
	if question_index != current_question_index:
		return
	
	if is_correct:
		if is_final_question:
			finish_quiz()
		else:
			select_next_question()
	else:
		apply_penalty()

func apply_penalty() -> void:
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
	
	rpc("game_over", winning_player_id, winning_username)

func load_user_stats() -> void:
	var file_path = "res://user_stats.json" if OS.has_feature("editor") else "user_stats.json"
	
	user_stats = {
		"Green": {"victories": 0},
		"Purple": {"victories": 0}
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
				user_stats = loaded_data["users"]

func save_user_stats() -> void:
	if not multiplayer.is_server():
		return
	
	var file_path = "res://user_stats.json" if OS.has_feature("editor") else "user_stats.json"
	
	total_games += 1
	
	var stats_data = {
		"users": user_stats,
		"total_games": total_games
	}
	
	var json_string = JSON.stringify(stats_data, "", true)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

@rpc("any_peer", "call_local")
func game_over(winning_player_id: int, winning_username: String) -> void:
	is_game_over = true
	disable_buttons()
	
	var players = UserManager.logged_in_users.keys()
	var losing_username = players.duplicate()
	losing_username.erase(winning_username)
	losing_username = losing_username[0] if losing_username.size() > 0 else ""
	
	if multiplayer.is_server():
		if winning_username in user_stats:
			if "victories" not in user_stats[winning_username]:
				user_stats[winning_username]["victories"] = 0
			user_stats[winning_username]["victories"] += 1
		
		save_user_stats()
	
	if player_id == winning_player_id:
		Pregunta.text = winning_username + " wins!"
	else:
		Pregunta.text = losing_username + " loses!"

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
