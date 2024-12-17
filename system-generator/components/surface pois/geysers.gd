extends Sprite3D
class_name Geyser

@onready var poi_info: Control = $PoIInfo

var seed := 0

var rng = RandomNumberGenerator.new()

var parent_planet : Planetoid
var parent_region : PlanetSurface.SurfaceRegion

enum GeyserClass {HotSpring, Fumarole, Geyser}

# PoI Values
var geyser_class : GeyserClass

var obj_name : String
var region_name : String
var debug_pos : Vector2

func _ready() -> void:
	rng.seed = seed
	
	populate_poi_info()
	
	look_at(parent_planet.position)

@onready var v_box_container: VBoxContainer = $PoIInfo/Panel/VBoxContainer

func set_class(region_class : PlanetSurface.RegionClass):
	var possible_classes = [GeyserClass.HotSpring, GeyserClass.Fumarole, GeyserClass.Geyser]

	geyser_class = possible_classes[rng.randi_range(0, len(possible_classes)-1)]

func populate_poi_info():
	var info_strings : Array[String] = [obj_name,
	"%s" % debug_pos,
										"In %s" % region_name,
										"Geyser Type: %s" % [GeyserClass.keys()[geyser_class]]]

	for i in info_strings:
		var x = Label.new()
		x.add_theme_font_size_override("font_size", 12)
		x.text = i
		v_box_container.add_child(x)

func _on_hover_detector_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	poi_info.position = camera.unproject_position(event_position)

func _on_hover_detector_mouse_entered() -> void:
	poi_info.show()

func _on_hover_detector_mouse_exited() -> void:
	poi_info.hide()
