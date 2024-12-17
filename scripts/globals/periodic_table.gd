extends Node

@export var elements : Dictionary

func _init() -> void:
	for file_name in DirAccess.get_files_at("res://system-generator/resources/elements"):
		if (file_name.get_extension() == "tres"):
			var e = load("res://system-generator/resources/elements/"+file_name)
			elements[e.atomic_number] = e
