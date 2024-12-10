extends Panel

@onready var Identifier = $VBoxContainer/Identifier
@onready var StartButton = $VBoxContainer/Margen1/StartButton
@onready var ServerAddress = $VBoxContainer/Margen2/ServerAddress
@onready var JoinButton = $VBoxContainer/Margen3/JoinButton
@onready var StatusLabel = $VBoxContainer/StatusLabel

var logged_username = ""

func _ready() -> void:
	logged_username = UserManager.get_logged_in_username()
	ServerAddress.text = "127.0.0.1"
	
	if Identifier:
		Identifier.text = "Logged as, " + logged_username
	
	StartButton.pressed.connect(_on_start_server_pressed)
	JoinButton.pressed.connect(_on_join_server_pressed)

func _on_start_server_pressed() -> void:
	NetworkManager.create_server(
		func():
			StatusLabel.text = "Server started. Waiting for players...",
		func():
			StatusLabel.text = "Both players ready to start!"
	)

func _on_join_server_pressed() -> void:
	var address = ServerAddress.text
	NetworkManager.join_server(
		address,
		func():
			StatusLabel.text = "Connected to server",
		func():
			StatusLabel.text = "Failed to connect to server"
	)
