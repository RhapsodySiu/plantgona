extends Control

@export var Address = "127.0.0.1"

@onready var player_name_input = $LineEdit
@onready var log_label: Label = $LogContainer/Label
 
const PORT = 8654

var peer: MultiplayerPeer

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


# server + client
func _on_peer_connected(id: int):
	print("player connected: ", id)

# server + client
func _on_peer_disconnected(id: int):
	print("player disconnted: ", id, ", my id=", GameManager.player_id)
	
	if GameManager.player_id == 1:
		GameManager.players.erase(id)
		update_players.bind(GameManager.players).rpc()
	
# client
func _on_connected_to_server():
	print("client: connected to server, sending info")
	send_player_info.bind(GameManager.player_id, GameManager.get_player_info(GameManager.player_id)).rpc_id(1)

# client
func _on_connection_failed():
	print("connection fails")
	
func _get_player_name():
	return player_name_input.text
	
func _on_host_button_pressed():
	# reset host info
	GameManager.player_id = 1
	GameManager.player_name = _get_player_name()
	GameManager.set_player_info(1, { "name": _get_player_name(), "order": 1 })
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, GameManager.MAX_PLAYERS)
	if error != OK:
		print("cannot host: ", error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_FASTLZ)
	
	multiplayer.set_multiplayer_peer(peer)
	
	log_label.text = "Waiting for players (1/5)"

func _on_join_button_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, PORT)
	
	GameManager.player_id = peer.get_unique_id()
	GameManager.player_name = _get_player_name()
	GameManager.set_player_info(GameManager.player_id, { "name": _get_player_name() })
	print("client: set player info to: ", GameManager.get_player_info(GameManager.player_id))
	
	peer.get_host().compress(ENetConnection.COMPRESS_FASTLZ)
	multiplayer.set_multiplayer_peer(peer)
	log_label.text = "Joined"

@rpc("any_peer", "call_local")
func send_player_info(id: int, info: Variant):
	print("client: set name of id=", id, " to ", info["name"])
	if !GameManager.players.has(id):
		print("client: add new entry")
		info.merge({ "order": GameManager.players.size() + 1 })
		GameManager.players[id] = info # rare case
	else:
		GameManager.players[id].merge(info, true)
	
	if GameManager.player_id == 1:
		print("server: update player, current", GameManager.players)
		update_players.bind(GameManager.players).rpc()

@rpc("authority", "call_local")
func start_game():
	var game_scene = load("res://scenes/game_scene.tscn").instantiate()
	get_tree().root.add_child(game_scene)
	self.hide()
	
func update_log():
	print("[%d]" % GameManager.player_id, "update log")
	log_label.text = "Waiting for players (%d/5)" % GameManager.players.size()
	
# will update log
@rpc("authority", "call_local")
func update_players(players: Dictionary):
	print("update players:", players)
	GameManager.players = players
	update_log()

func _on_start_button_pressed():
	print("start game")
	start_game.rpc()
