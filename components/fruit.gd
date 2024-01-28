extends Node3D


func _on_area_3d_body_entered(body):
	if body.is_in_group("player") and visible:
		if body.seed_count > 5:
			print("skip for eating too many")
			return
			
		print("fruit is eaten")
		visible = false # prevent trigger multiple time before sound finishes
		$AudioStreamPlayer3D.play()
		body.eat()

		await $AudioStreamPlayer3D.finished
		queue_free()
