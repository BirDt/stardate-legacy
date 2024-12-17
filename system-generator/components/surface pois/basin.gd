extends Sprite3D
class_name Basin

@onready var poi_info: Control = $PoIInfo

var seed := 0

var rng = RandomNumberGenerator.new()

var parent_planet : Planetoid
var parent_region : PlanetSurface.SurfaceRegion

enum BasinClass {Basin, Crater}

# PoI Values
var percent_of_radius : float
var radius : float
var basin_class : BasinClass

var obj_name : String
var region_name : String
var debug_pos : Vector2

func _ready() -> void:
	rng.seed = seed
	
	percent_of_radius = clamp(rng.randfn(0.0001, 0.00001), 0.000005, INF)
	radius = rng.randf_range(200000, parent_planet.planet_radius * 6371000 * 0.2)
	populate_poi_info()
	
	look_at(parent_planet.position)

@onready var v_box_container: VBoxContainer = $PoIInfo/Panel/VBoxContainer

func set_class(region_class : PlanetSurface.RegionClass):
	if region_class == PlanetSurface.RegionClass.Crater:
		basin_class = BasinClass.Crater
	else:
		if rng.randf() < 0.7:
			basin_class = BasinClass.Basin
		else:
			basin_class = BasinClass.Crater

func populate_poi_info():
	var info_strings : Array[String] = [obj_name,
										"%s" % debug_pos,
										"In %s" % region_name,
										"%s" % BasinClass.keys()[basin_class],
										"Radius: %sm" % radius,
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
