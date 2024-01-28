extends Node3D

var texture_light: Texture2D = preload("res://models/beardie_skin_white.png")

func update_skin(player_id: int):
	var mesh = get_node("Armature/Skeleton3D/Icosphere")
	
	var material = mesh.get_surface_override_material(0)

	if player_id == 1:
		return
		
	if mesh == null:
		print("cannot update null mesh for player:", GameManager.player_id)
		return
		
	
	var overriden_material: StandardMaterial3D = material.duplicate()
	
	match player_id:
		2: # white
			overriden_material.albedo_color = Color("#ffffff")
			overriden_material.albedo_texture = texture_light
		3: # red
			overriden_material.albedo_color = Color("#7b3538")
		4: # yellow
			overriden_material.albedo_color = Color("#b49540")
			overriden_material.albedo_texture = texture_light
		5: # black
			overriden_material.albedo_color = Color("#212206")
	
	mesh.set_surface_override_material(0, overriden_material)

func smile():
	var mesh = get_node("Armature/Skeleton3D/Icosphere")
	mesh.set("blend_shapes/MouthOpened", 0.2)
	print("beardie smile")
