extends Node

const SYSTEM = preload("res://system-generator/components/system.tscn")

@export var remember_time := true

@onready var seed_input: LineEdit = $LoaderUI/Panel/MarginContainer/VBoxContainer/SeedInput
@onready var force_habitable: CheckBox = $LoaderUI/Panel/MarginContainer/VBoxContainer/ForceHabitable

@onready var loader_ui: Control = $LoaderUI

func _on_generate_new_pressed() -> void:
	var p = SYSTEM.instantiate()
	
	p.force_habitable = force_habitable.button_pressed 
	if len(seed_input.text) > 0:
		p.sys_seed = seed_input.text.hash()
		p.random_seed = false
	
	add_child(p)
	loader_ui.queue_free()


func _on_load_existing_pressed() -> void:
	var p = SYSTEM.instantiate()
	
	# If load_system is true, read the system seed and whether to force habitability from saved_system_seed
	# INFO: this is a placeholder for an actual "save" system, and effectively just a proof of concept that the generation is deterministic
	print("Loading previous system save...")
	var file = FileAccess.open("user://saved_system_seed", FileAccess.READ)
	var c = file.get_as_text().split("\n")
	p.random_seed = false
	p.sys_seed = int(c[0])
	p.force_habitable = bool(int(c[1]))

	# INFO: we don't change scene here, we add the system as a child
	add_child(p)
	loader_ui.queue_free()
