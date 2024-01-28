extends Area3D


func try_water():
	if get_parent().is_in_group("sapling"):
		get_parent()._on_tree_watered()
