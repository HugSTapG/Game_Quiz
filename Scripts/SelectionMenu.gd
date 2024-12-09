extends Panel

@onready var Identifier = $VBoxContainer/Identifier
@onready var StartButton = $VBoxContainer/Margen1/StartButton
@onready var ServerAddress = $VBoxContainer/Margen2/ServerAddress
@onready var JoinButton = $VBoxContainer/Margen3/JoinButton
@onready var StatusLabel = $VBoxContainer/StatusLabel

var logged_username = ""

func _ready() -> void:
	print("SelectionMenu ready")
	
	logged_username = UserManager.get_logged_in_username()
	print("Logged username in SelectionMenu: ", logged_username)
	
	ServerAddress.text = "127.0.0.1"
	
	if Identifier:
		Identifier.text = "Logged as, " + logged_username
	
	StartButton.pressed.connect(_on_start_server_pressed)
	JoinButton.pressed.connect(_on_join_server_pressed)

func _on_start_server_pressed() -> void:
	print("Start server pressed")
	NetworkManager.create_server(
		func():
			print("Server started. Waiting for players...")
			StatusLabel.text = "Server started. Waiting for players...",
		func():
			print("Both players connected and ready to start!")
			StatusLabel.text = "Both players ready to start!"
	)

func _on_join_server_pressed() -> void:
	print("Join server pressed")
	var address = ServerAddress.text
	NetworkManager.join_server(
		address,
		func():
			print("Successfully connected to server")
			StatusLabel.text = "Connected to server",
		func():
			print("Connection to server failed")
			StatusLabel.text = "Failed to connect to server"
	)
