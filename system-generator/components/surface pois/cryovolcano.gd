extends Sprite3D
class_name Cryovolcano

@onready var poi_info: Control = $PoIInfo

var seed := 0

var rng = RandomNumberGenerator.new()

var parent_planet : Planetoid
var parent_region : PlanetSurface.SurfaceRegion

enum VolcanoClass {CinderCone, Composite, LavaDome, Shield}

# PoI Values
var percent_of_radius : float
var volcano_class : VolcanoClass

var obj_name : String
var region_name : String
var debug_pos : Vector2

func _ready() -> void:
	rng.seed = seed
	
	percent_of_radius = clamp(rng.randfn(0.001, 0.0005), 0.0001, INF)
	populate_poi_info()
	
	look_at(parent_planet.position)

@onready var v_box_container: VBoxContainer = $PoIInfo/Panel/VBoxContainer

func set_class(region_class : PlanetSurface.RegionClass):
	var possible_classes = [VolcanoClass.CinderCone, VolcanoClass.Composite, VolcanoClass.LavaDome, VolcanoClass.Shield]

	volcano_class = possible_classes[rng.randi_range(0, len(possible_classes)-1)]

func populate_poi_info():
	var info_strings : Array[String] = [obj_name,
	"%s" % debug_pos,
										"In %s" % region_name,
										"Cryovolcano Type: %s" % [VolcanoClass.keys()[volcano_class]],
										"Percent of Radius: %s%%" % [percent_of_radius * 100],
										"True Height: %sm" % [parent_planet.planet_radius * 6371000 * percent_of_radius]]

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
