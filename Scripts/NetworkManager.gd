extends Node

const PORT = 4242
const MAX_PLAYERS = 2

var peer = ENetMultiplayerPeer.new()
var players = {}
var logged_in_players = {}

var on_server_started = null
var on_client_connected = null
var on_client_disconnected = null
var on_both_players_connected = null
var on_connection_failed = null

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func reset_network():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	
	peer = ENetMultiplayerPeer.new()
	players.clear()
	logged_in_players.clear()

func create_server(
	server_started_callback = null, 
	both_players_callback = null
):
	reset_network()
	
	on_server_started = server_started_callback
	on_both_players_connected = both_players_callback
	
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		
		var username = UserManager.get_logged_in_username()
		players[1] = username
		
		if on_server_started:
			on_server_started.call()
	else:
		if on_connection_failed:
			on_connection_failed.call()

func join_server(
	address = "127.0.0.1", 
	connected_callback = null, 
	failed_callback = null
):
	reset_network()
	
	on_client_connected = connected_callback
	on_connection_failed = failed_callback
	
	var error = peer.create_client(address, PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	else:
		if on_connection_failed:
			on_connection_failed.call()

func connected_to_server():
	var username = UserManager.get_logged_in_username()
	rpc_id(1, "sync_player_username", username)
	
	if on_client_connected:
		on_client_connected.call()

func connection_failed():
	if on_connection_failed:
		on_connection_failed.call()

func peer_connected(id):
	if on_client_connected:
		on_client_connected.call()

func peer_disconnected(id):
	if id in players:
		var username = players[id]
		players.erase(id)

@rpc("any_peer", "call_local")
func sync_player_username(username):
	var sender_id = multiplayer.get_remote_sender_id()
	
	if sender_id != 0:
		players[sender_id] = username
	
	if players.size() == 2:
		start_multiplayer_quiz()

func start_multiplayer_quiz():
	rpc("load_quiz_scene")

@rpc("any_peer", "call_local")
func load_quiz_scene():
	get_tree().change_scene_to_file("res://UI.tscn")
