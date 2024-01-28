extends Node3D
 
class_name WaterDroplet

@onready var body = $StaticBody3D
@onready var timer = $Timer

@export var max_bounce = 3
@export var elasticity = 1.0
@export var bounce_force: float = 0.1

@export var active_time = 7.0
@export var fading_time = 3.0

var velocity = Vector3.ZERO
var gravity = 0.098

var friction = 1.2
var bounce_count = 0

var is_fading = false

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(elasticity >= 0.0 and elasticity <= 1.0, "elasticity should be in range [0,1]")
	
	timer.start(active_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	velocity.y -= gravity * delta
	
	var collision_info: KinematicCollision3D = body.move_and_collide(velocity)
	
	if collision_info:
		var collider = collision_info.get_collider()
		
		if collider.is_in_group("player"):
			velocity = -velocity.bounce(collision_info.get_normal())
			
			var is_player_jumping = !collider.is_on_floor()
			
			velocity.y = bounce_force * (1.2 if is_player_jumping else 0.8)
			
			# reset bounce counter
			bounce_count = 0
			
		elif collider.is_in_group("ground"):
			if bounce_count >= max_bounce:
				velocity.y = 0.0
			else:
				velocity.y *= -elasticity
				bounce_count += 1
				
			apply_friction(delta)
		
		elif collider.is_in_group("tree"):
			water_tree(collider.get_parent())
			
func apply_friction(delta):
	if abs(velocity.x) < 0.01:
		velocity.x = 0
	else:
		velocity.x *= (1 - friction * delta)
			
	if abs(velocity.z) < 0.01:
		velocity.z = 0
	else:
		velocity.z *= (1 - friction * delta)


func _on_area_3d_area_entered(area):
	if area.is_in_group("score_ring"):
		print("emit score ring signal")
		area.try_water()
		queue_free()


func _on_timer_timeout():
	is_fading = true
	$AnimationPlayer.speed_scale = 1.0 / fading_time
	$AnimationPlayer.play("fade")
	
	await $AnimationPlayer.animation_finished
	
	queue_free()
	
func water_tree(tree: MyTree):
	tree.water()
	queue_free()
