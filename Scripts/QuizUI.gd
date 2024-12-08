extends Panel

@onready var Pregunta = $Quiz_Container/Pregunta
@onready var Respuesta_Uno = $Quiz_Container/MargenR1/Respuesta_Uno
@onready var Respuesta_Dos = $Quiz_Container/MargenR2/Respuesta_Dos
@onready var Respuesta_Tres = $Quiz_Container/MargenR3/Respuesta_Tres

var all_question_data = [
	{
		"question": "If you freeze water, what do you get?",
		"answers": ["Ice", "Bomb", "Fire"],
		"correctAnswerIndex": 0
	},
	{
		"question": "What is the capital of France?",
		"answers": ["Berlin", "Madrid", "Paris"],
		"correctAnswerIndex": 2
	},
	{
		"question": "What is 2 + 2?",
		"answers": ["3", "4", "5"],
		"correctAnswerIndex": 1
	},
	{
		"question": "Which planet is closest to the Sun?",
		"answers": ["Venus", "Mercury", "Mars"],
		"correctAnswerIndex": 1
	}
]

var question_data = []
var current_question_index = 0
var is_penalty = false
var is_game_over = false
var logged_username = ""
var player_id = 0

func _ready() -> void:
	print("QuizUI ready - Multiplayer is server: ", multiplayer.is_server())
	
	logged_username = UserManager.get_logged_in_username()
	print("Username in QuizUI: " + logged_username)
	
	generate_unique_questions()
	
	Respuesta_Uno.pressed.connect(_on_answer_clicked.bind(0))
	Respuesta_Dos.pressed.connect(_on_answer_clicked.bind(1))
	Respuesta_Tres.pressed.connect(_on_answer_clicked.bind(2))
	
	if multiplayer.is_server():
		player_id = 1
		rpc("initialize_quiz", logged_username, player_id)
	else:
		player_id = 2
		rpc_id(1, "request_quiz_initialization", logged_username, player_id)

func generate_unique_questions() -> void:
	var shuffled_questions = all_question_data.duplicate()
	shuffled_questions.shuffle()
	question_data = shuffled_questions.slice(0, 1)

@rpc("any_peer", "reliable")
func request_quiz_initialization(username: String, remote_player_id: int):
	print("Client requesting quiz initialization")
	rpc("initialize_quiz", username, remote_player_id)

@rpc("any_peer", "call_local")
func initialize_quiz(username: String, remote_player_id: int):
	print("Initializing quiz for: " + username + " with Player ID: " + str(remote_player_id))
	
	if remote_player_id != player_id:
		print("Mismatched player ID. Skipping initialization.")
		return
	
	if Pregunta:
		Pregunta.text = username + "'s Quiz: " + question_data[current_question_index]["question"]
	
	show_question(current_question_index)

@rpc("any_peer", "call_local")
func show_question(index: int) -> void:
	var question_info = question_data[index]
	
	Pregunta.text = question_info["question"]
	
	Respuesta_Uno.text = question_info["answers"][0]
	Respuesta_Dos.text = question_info["answers"][1]
	Respuesta_Tres.text = question_info["answers"][2]

func _on_answer_clicked(answer_index: int) -> void:
	if is_penalty or is_game_over:
		return
	
	rpc("check_answer", answer_index, player_id)

@rpc("any_peer", "call_local")
func check_answer(answer_index: int, checking_player_id: int) -> void:
	if checking_player_id != player_id:
		return
	
	var correct_answer_index = question_data[current_question_index]["correctAnswerIndex"]
	
	if answer_index == correct_answer_index:
		current_question_index += 1
		if current_question_index < question_data.size():
			rpc("show_question", current_question_index)
		else:
			rpc("game_over", true, checking_player_id)
	else:
		rpc("apply_penalty", checking_player_id)

@rpc("any_peer", "call_local")
func apply_penalty(penalty_player_id: int) -> void:
	if penalty_player_id != player_id:
		return
	
	Respuesta_Uno.add_theme_color_override("font_color", Color.RED)
	Respuesta_Dos.add_theme_color_override("font_color", Color.RED)
	Respuesta_Tres.add_theme_color_override("font_color", Color.RED)
	
	Respuesta_Uno.disabled = true
	Respuesta_Dos.disabled = true
	Respuesta_Tres.disabled = true
	
	is_penalty = true
	
	rpc("reset_after_penalty", penalty_player_id)

@rpc("any_peer", "call_local")
func reset_after_penalty(penalty_player_id: int) -> void:
	if penalty_player_id != player_id:
		return
	
	await get_tree().create_timer(0.5).timeout
	
	Respuesta_Uno.disabled = false
	Respuesta_Dos.disabled = false
	Respuesta_Tres.disabled = false
	
	Respuesta_Uno.remove_theme_color_override("font_color")
	Respuesta_Dos.remove_theme_color_override("font_color")
	Respuesta_Tres.remove_theme_color_override("font_color")
	
	is_penalty = false

@rpc("any_peer", "call_local")
func game_over(is_winner: bool, winner_id: int) -> void:
	if winner_id != player_id:
		return
	
	is_game_over = true
	disable_buttons()
	
	if is_winner:
		Pregunta.text = "You win!"
	else:
		Pregunta.text = "You lose!"

@rpc("any_peer", "call_local")
func disable_buttons() -> void:
	Respuesta_Uno.disabled = true
	Respuesta_Dos.disabled = true
	Respuesta_Tres.disabled = true
