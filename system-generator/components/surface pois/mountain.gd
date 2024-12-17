extends Sprite3D
class_name Mountain

@onready var poi_info: Control = $PoIInfo

var seed := 0

var rng = RandomNumberGenerator.new()

var parent_planet : Planetoid
var parent_region : PlanetSurface.SurfaceRegion

enum MountainClass {Arete, Drumlin, Esker, Monadnock, Nunatak, GlacialHorn, Bornhardt, Cuesta, FaultBlock, Mesa, Butte, TowerKarst, Hogback, Trap}

# PoI Values
var percent_of_radius : float
var mountain_class : MountainClass

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
	var possible_classes = []
	
	# RegionClass.MountainRange, RegionClass.KarstLandscape, RegionClass.Crater, RegionClass.FaultZone, RegionClass.VolcanicArchipelago, RegionClass.Glacier, RegionClass.Plateau, RegionClass.RichPlateau, RegionClass.Plain
	if region_class in [PlanetSurface.RegionClass.Glacier]:
		possible_classes.append(MountainClass.Nunatak)
	if region_class in [PlanetSurface.RegionClass.Plateau, PlanetSurface.RegionClass.RichPlateau, PlanetSurface.RegionClass.KarstLandscape]:
		possible_classes.append_array([MountainClass.Trap, MountainClass.TowerKarst])
	if region_class in [PlanetSurface.RegionClass.VolcanicArchipelago, PlanetSurface.RegionClass.Crater]:
		possible_classes.append_array([MountainClass.Monadnock, MountainClass.Esker, MountainClass.Hogback])
	if region_class in [PlanetSurface.RegionClass.Crater]:
		possible_classes.append_array([MountainClass.Cuesta])
	if region_class in [PlanetSurface.RegionClass.FaultZone]:
		possible_classes.append(MountainClass.FaultBlock)
	if region_class in [PlanetSurface.RegionClass.MountainRange]:
		possible_classes.append_array([MountainClass.Arete, MountainClass.GlacialHorn, MountainClass.Hogback])
	if region_class in [PlanetSurface.RegionClass.Plateau, PlanetSurface.RegionClass.RichPlateau, PlanetSurface.RegionClass.Plain]:
		possible_classes.append_array([MountainClass.Esker, MountainClass.Mesa, MountainClass.Butte])
		
	mountain_class = possible_classes[rng.randi_range(0, len(possible_classes)-1)]

func populate_poi_info():
	var info_strings : Array[String] = [obj_name,
	"%s" % debug_pos,
										"In %s" % region_name,
										"Mountain Type: %s" % [MountainClass.keys()[mountain_class]],
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
