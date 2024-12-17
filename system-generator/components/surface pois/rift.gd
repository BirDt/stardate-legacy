extends Sprite3D
class_name Rift

@onready var poi_info: Control = $PoIInfo

var seed := 0

var rng = RandomNumberGenerator.new()

var parent_planet : Planetoid
var parent_region : PlanetSurface.SurfaceRegion

# PoI Values
var percent_of_radius : float
var length : float
var width : float

var obj_name : String
var region_name : String
var debug_pos : Vector2

func _ready() -> void:
	rng.seed = seed
	
	percent_of_radius = clamp(rng.randfn(0.0001, 0.00001), 0.000005, INF)
	length = rng.randf_range(200000, parent_planet.planet_radius * 6371000 * 0.2)
	width = rng.randf_range(0, length * 0.6)
	populate_poi_info()
	
	look_at(parent_planet.position)

@onready var v_box_container: VBoxContainer = $PoIInfo/Panel/VBoxContainer

func set_class(region_class : PlanetSurface.RegionClass):
	pass

func populate_poi_info():
	var info_strings : Array[String] = [obj_name,
										"%s" % debug_pos,
										"Rift",
										"In %s" % region_name,
										"Length: %sm" % length,
										"Width: %sm" % width,
										"Percent of Radius: %s%%" % [percent_of_radius * 100],
										"True Depth: %sm" % [parent_planet.planet_radius * 6371000 * percent_of_radius]]

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
