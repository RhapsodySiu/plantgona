extends Node3D

@export var trees: Array[PackedScene]
@export var fruit_scene: PackedScene
@export var water_level_arr: Array[int] = [3, 10]
@export var max_fruit_spawn = 3

@onready var score_ring: Area3D = $ScoreRing
@onready var fruit_timer: Timer = $Timer
@onready var grow_sfx: AudioStreamPlayer3D = $GrowSound
@onready var water_sfx: AudioStreamPlayer3D = $WaterSound

var current_state = 0
var water_received = 0
var fruit_spawned = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	grow_sfx.play()
	var tree = trees[0].instantiate()

	add_tree_to_scene(tree)
	
	score_ring.area_shape_entered.connect(on_area_entered)


func _on_tree_watered():
	water_sfx.play()
	water_received += 1
	print("watered to tree: ", water_received)
	
	if current_state == len(water_level_arr):
		print("noop for grown fruit tree")
		return
		
	if water_received >= water_level_arr[current_state]:
		grow_tree()
	
func _exit_tree():
	if score_ring:
		score_ring.area_shape_entered.disconnect(on_area_entered)
	
func on_area_entered(area: Area3D):
	print("area entered:", area)
	if area.is_in_group("ball"):
		print("watered in area")
		_on_tree_watered()

func yield_fruit():
	score_ring.area_shape_entered.disconnect(on_area_entered)
	score_ring.queue_free()
	score_ring = null
	
	if fruit_timer.is_stopped() and fruit_spawned < max_fruit_spawn:
		var wait_time = randf_range(5.0, 10.0)
		print("set timer to ", wait_time)
		fruit_timer.start(wait_time)

func add_tree_to_scene(tree: MyTree):
	$Tree.add_child(tree)
	tree.on_watered.connect(_on_tree_watered)
	
func grow_tree():
	if current_state > len(water_level_arr):
		print("! should not execute grow_tree here")
		return
		
	current_state += 1
	print("change tree state")
	var tree_to_add = trees[current_state].instantiate()
	var tree_to_delete = $Tree.get_child(0)
	
	tree_to_delete.on_watered.disconnect(_on_tree_watered)
	tree_to_add.scale = Vector3(0.5, 0.5, 0.5)
	
	add_tree_to_scene(tree_to_add)
	
	grow_sfx.play()
	
	var tween = create_tween()
	tween.tween_property(tree_to_delete, "scale", Vector3(0.5, 0.5, 0.5), 0.5).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(tree_to_add, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BOUNCE)
	tween.play()
	await tween.finished
	
	tree_to_delete.queue_free()
	
	if current_state == len(water_level_arr):
		print("start growing fruit")
		yield_fruit()

func _on_timer_timeout():
	print("spawn fruit")
	var fruit = fruit_scene.instantiate()
	
	fruit.position.x = randf_range(-3.0, 3.0)
	fruit.position.y = 5.0
	fruit.position.z = randf_range(-3.0, 3.0)
	
	add_child(fruit)
	
	fruit_spawned += 1
	
	if fruit_spawned > max_fruit_spawn:
		print("stop spawning fruit")
		fruit_timer.stop()
