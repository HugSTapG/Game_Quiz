extends Panel

# Declare the UI nodes
var question_label: Label
var answer_button_1: Button
var answer_button_2: Button
var answer_button_3: Button
var quiz_container: VBoxContainer

func _ready() -> void:
	# Get the nodes from the scene
	question_label = get_node("Quiz_Container/Pregunta")
	answer_button_1 = get_node("Quiz_Container/MargenR1/Respuesta_Uno")
	answer_button_2 = get_node("Quiz_Container/MargenR2/Respuesta_Dos")
	answer_button_3 = get_node("Quiz_Container/MargenR3/Respuesta_Tres")
	quiz_container = get_node("Quiz_Container")

	# Initially hide the entire Panel node (including all children)
	self.visible = false

	# Set default values for the question and answers
	update_ui("What is your favorite color?", ["Red", "Blue", "Green"])

# Function to update the UI with a new question and answers
func update_ui(question: String, answers: Array) -> void:
	# Set the question text
	question_label.text = question
	
	# Set the answers in the buttons
	if answers.size() >= 1:
		answer_button_1.text = answers[0]
	if answers.size() >= 2:
		answer_button_2.text = answers[1]
	if answers.size() >= 3:
		answer_button_3.text = answers[2]

# Called every frame
func _process(delta: float) -> void:
	# Toggle the visibility of the entire Panel when the action is triggered
	if Input.is_action_just_pressed("ui_aceptar"):  # Make sure this is correctly mapped in the Input Map
		self.visible = !self.visible
