extends MultiplayerSynchronizer

@export var is_jumping := false
@export var input_dir := Vector2.ZERO

func _process(delta):
	if Input.is_action_just_pressed("move_jump"):
		jump.rpc()
	
	input_dir = Input.get_vector("move_backward", "move_forward", "move_left", "move_right")
		
@rpc("call_local")
func jump():
	is_jumping = true
