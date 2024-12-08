extends Panel

@onready var Username = $Login_Container/Margen1/Username
@onready var Password = $Login_Container/Margen2/Password
@onready var LoginButton = $Login_Container/Margen3/LoginButton

func _ready() -> void:
	LoginButton.pressed.connect(_on_login_button_pressed)

func _on_login_button_pressed() -> void:
	var entered_username = Username.text
	var entered_password = Password.text
	
	if UserManager.login(entered_username, entered_password):
		var middle_scene = load("res://Middle.tscn")
		var middle_scene_instance = middle_scene.instantiate()
		get_tree().root.add_child(middle_scene_instance)
		get_tree().current_scene = middle_scene_instance
		queue_free()
	else:
		Username.text = ""
		Password.text = ""
		print("Invalid username or password")
