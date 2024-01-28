extends Node3D

class_name MyTree

signal on_watered

@onready var body: StaticBody3D = $StaticBody3D

func water():
	on_watered.emit()
