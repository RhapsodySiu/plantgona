extends Node3D

@onready var in_game_ui: Control = $InGameUI

var seed_label_scene: PackedScene = preload("res://ui/seed_label.tscn")

func _ready():
	if GameManager.is_multiplayer():
		print("[%d] get peers:" % GameManager.player_id, multiplayer.get_peers())
		
		for pid in multiplayer.get_peers():
			add_player(pid)

	add_player(GameManager.player_id)
		
	update_seed_ui()
	
func _exit_tree():
	var players = $Players.get_children()
	for player in players:
		player.on_fruit_eaten.disconnect(update_seed_ui)
		player.on_seed_sowed.disconnect(update_seed_ui)

func _get_seed_count() -> int:
	var players = $Players.get_children()
	for player in players:
		if GameManager.player_id == 0:
			return player.seed_count
		elif player.corr_player_id == GameManager.player_id:
			return player.seed_count
	return 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit() # Quits the game
	
	if event.is_action_pressed("change_mouse_input"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Capture mouse if clicked on the game, needed for HTML5
# Called when an InputEvent hasn't been consumed by _input() or any GUI item
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_dead_height_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.die()

func add_player(id = 0):
	var character = GameManager.get_player_instance()
	
	if id != 0:
		character.configure_player(id)
	
	var init_position = get_node("%SpawnPosition").position
	
	init_position.x += randf_range(-10.0, 10.0)
	init_position.z += randf_range(-10.0, 10.0)
	
	character.position = init_position
	character.name = str(id)
	
	character.on_fruit_eaten.connect(update_seed_ui)
	character.on_seed_sowed.connect(update_seed_ui)
		
	$Players.add_child(character, true)
	
	print("character added for id=", id)
	
func update_seed_ui():
	var seed_count = _get_seed_count()
	var ui_seed_count = in_game_ui.get_node("FruitCountContainer").get_child_count()
	
	while seed_count > ui_seed_count:
		var label = GameManager.get_seed_label()
		in_game_ui.get_node("FruitCountContainer").add_child(label)
		ui_seed_count += 1
		
	while ui_seed_count != 0 and seed_count < ui_seed_count:
		var label = in_game_ui.get_node("FruitCountContainer").get_child(0)
		label.queue_free()
		ui_seed_count -= 1
		
