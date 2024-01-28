extends FPSController3D

class_name MyPlayer

## Example script that extends [CharacterController3D] through 
## [FPSController3D].
## 
## This is just an example, and should be used as a basis for creating your 
## own version using the controller's [b]move()[/b] function.
## 
## This player contains the inputs that will be used in the function 
## [b]move()[/b] in [b]_physics_process()[/b].
## The input process only happens when mouse is in capture mode.
## This script also adds submerged and emerged signals to change the 
## [Environment] when we are in the water.

signal on_fruit_eaten
signal on_seed_sowed

@export var input_back_action_name := "move_backward"
@export var input_forward_action_name := "move_forward"
@export var input_left_action_name := "move_left"
@export var input_right_action_name := "move_right"
@export var input_sprint_action_name := "move_sprint"
@export var input_jump_action_name := "move_jump"
@export var input_crouch_action_name := "move_crouch"
@export var input_fly_mode_action_name := "move_fly_mode"
@export var input_sow_action_name := "sow"

@export var underwater_env: Environment

@onready var anim_player = $beardie/AnimationPlayer
@onready var respawn_timer = $RespawnTimer
@onready var water_timer = $WaterTimer

@onready var sync_player_input = $PlayerInput

var can_fire_water := false
var is_water_cooldown := false
var seed_count := 0
@export var corr_player_id := 0

# should pause input
var paused := false

func _ready():	
	# add some offset to prevent collide with other players
	position.x += randf_range(-10.0, 10.0)
	position.y = 5.0
	position.z += randf_range(-10.0, 10.0)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup()
	emerged.connect(_on_controller_emerged.bind())
	submerged.connect(_on_controller_subemerged.bind())
	
	# show_beardie_smile()

func configure_player(id: int):
	corr_player_id = id
	
	$PlayerInput.set_multiplayer_authority(id)
	set_process(id == GameManager.player_id)
	print("[%d] set process of %d to %s" % [GameManager.player_id, id, str(id == GameManager.player_id)])
	
	if GameManager.players[id].has("name"):
		$Label3D.text = GameManager.players[id]["name"]
	$beardie.update_skin(GameManager.players[id]["order"])
	print("player [id=", id, "] configured")
	
	# disable camera if not own player
	if GameManager.player_id == corr_player_id:
		get_node("Head/Camera").make_current()
	
func show_beardie_smile():
	$FocusCamera.make_current()
	$beardie.smile()
	
func _physics_process(delta):
	if paused:
		return
		
	var is_valid_input := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if is_valid_input:
		if Input.is_action_just_pressed(input_fly_mode_action_name):
			fly_ability.set_active(not fly_ability.is_actived())
		var input_axis = sync_player_input.input_dir
		var input_jump = !can_fire_water and sync_player_input.is_jumping
		
		sync_player_input.is_jumping = false
		
		# var input_crouch = Input.is_action_pressed(input_crouch_action_name)
		var input_sprint = Input.is_action_pressed(input_sprint_action_name)
		var input_swim_down = Input.is_action_pressed(input_crouch_action_name)
		var input_swim_up = Input.is_action_pressed(input_jump_action_name)
		
		var input_sow = Input.is_action_just_pressed(input_sow_action_name)
		
		## Start handling animation
		if input_axis.length() > 0:
			anim_player.play("walk", 0.5, 5.0 if input_sprint else 3.0)
		else:
			anim_player.play("idle", 0.5)
		## End of handling animation
		move(delta, input_axis, input_jump, false, input_sprint, input_swim_down, input_swim_up)
		
		if can_fire_water and Input.is_action_just_pressed(input_jump_action_name) and !is_water_cooldown:
			fire_water()
		
		if input_sow and seed_count > 0 and !can_fire_water:
			sow()
			
	else:
		# NOTE: It is important to always call move() even if we have no inputs 
		## to process, as we still need to calculate gravity and collisions.
		move(delta)


func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_head(event.relative)


func _on_controller_emerged():
	camera.environment = null


func _on_controller_subemerged():
	camera.environment = underwater_env

func add_score():
	GameManager.add_score()

func fire_water():
	var water_direction = ($WaterSpawner.global_position - global_position).normalized()
	
	is_water_cooldown = true
	GameManager.fire_water($WaterSpawner.global_position, water_direction)
	water_timer.start()

func eat():
	seed_count += 1
	on_fruit_eaten.emit()

func sow():
	seed_count -= 1
	GameManager.plant_sapling($SaplingSpawner.global_position)
	on_seed_sowed.emit()

func die():
	$Bubble.emitting = true # play particle animation and wait 4s
	# hide beardie
	$beardie.visible = false
	
	paused = true
	respawn_timer.start()


func _on_respawn_timer_timeout():
	print("respawn")
	$beardie.visible = true
	var respawn_position = get_parent().get_node("%SpawnPosition").global_position
	
	respawn_position.x += randf_range(-10.0, 10.0)
	respawn_position.z += randf_range(-10.0, 10.0)
	
	global_position = respawn_position
	
	paused = false


func _on_water_timer_timeout():
	is_water_cooldown = false
