extends Node

const MAX_PLAYERS = 5

var address

var player_id = 0
var player_name = ""

var global_state = {
	"total_score": 0,
	"tree_grown": 0
}

var players = {}

var sapling_scene: PackedScene = preload("res://components/sapling.tscn")
var water_scene: PackedScene = preload("res://components/water_droplet.tscn")
var seed_label_scene: PackedScene = preload("res://ui/seed_label.tscn")
var player_scene: PackedScene = preload("res://controllers/my_player.tscn")

func is_multiplayer() -> bool:
	return player_id != 0
	
func add_score():
	global_state["total_score"] += 1
	print("Global score: ", global_state["total_score"])

func plant_sapling(pos: Vector3):
	var sapling: Node3D = sapling_scene.instantiate()
	
	pos.y = 0.0 # make sure stay on the ground
	
	sapling.global_position = pos
	sapling.scale *= 0.3
	get_tree().current_scene.add_child(sapling)
	
	var tween = create_tween()
	tween.tween_property(sapling, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BOUNCE)
	tween.play()

	global_state["tree_grown"] += 1
	
	if global_state["tree_grown"] >= 3:
		print("win!")
	
func get_player_instance() -> MyPlayer:
	return player_scene.instantiate()
	
func set_player_info(id: int, info: Variant):
	players[id] = info
	
func get_player_info(id: int) -> Variant:
	if players.has(id):
		return players[id]
	return null
	
func fire_water(pos: Vector3, direction: Vector3):
	var water: WaterDroplet = water_scene.instantiate()
	
	var init_velo = direction * water.bounce_force
	
	init_velo.y = randf_range(0.8, 1.2) * water.bounce_force
	water.global_position = pos
	
	get_parent().add_child(water)
	water.velocity = init_velo
	
	get_tree().current_scene.add_child(water)

func get_seed_label() -> TextureRect:
	return seed_label_scene.instantiate()
