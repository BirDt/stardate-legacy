extends Node

const SYSTEM = preload("res://system-generator/components/system.tscn")

@export var load_system := true
@export var remember_time := true

func _ready() -> void:
	var p = SYSTEM.instantiate()
	
	# If load_system is true, read the system seed and whether to force habitability from saved_system_seed
	# INFO: this is a placeholder for an actual "save" system, and effectively just a proof of concept that the generation is deterministic
	if FileAccess.file_exists("user://saved_system_seed") and load_system:
		print("Loading previous system save...")
		var file = FileAccess.open("user://saved_system_seed", FileAccess.READ)
		var c = file.get_as_text().split("\n")
		p.random_seed = false
		p.sys_seed = int(c[0])
		p.force_habitable = bool(int(c[1]))

	# INFO: we don't change scene here, we add the system as a child
	add_child(p)
