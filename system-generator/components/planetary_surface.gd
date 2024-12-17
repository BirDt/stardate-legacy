extends Node3D
class_name PlanetSurface

class SurfaceRegion:
	var region_name : String
	var center : Vector2
	var polygon : PackedVector2Array
	var region_class : RegionClass
	
	func _init(_center, _polygon, _name, _class) -> void:
		center = _center
		polygon = _polygon
		region_name = _name + ": " + RegionClass.keys()[_class]
		region_class = _class
	
	func point_in_region(pos_x, pos_y):
		return Geometry2D.is_point_in_polygon(Vector2(pos_x, pos_y), polygon)

var delaunay: Delaunay

var scale_radius : float

var rng = RandomNumberGenerator.new()

var seed := 0
var point_num := 20

var initialized := false

var regions : Array[SurfaceRegion] = []

# general list of planetary regions. these don't do anything excpet impacting planetary feature generation
enum RegionClass {HotDesert, ColdDesert, Wetland, MountainRange, Plain, Canyon, KarstLandscape, Plateau, Trench, Abyss, IceShelf, Glacier, FaultZone, LavaField, MagmaOcean, Crater, SaltPan, Permafrost, IcebergField, GreatBasin,
	GeothermalField, VolcanicArchipelago, StonyDesert, CryovolcanoField, BasaltPlains, LavaTubes, SaltPillars, FrozenOcean, Ocean, MagneticAnomaly, RichPlateau}

var max_features := 20

var parent_planet : Planetoid

func initialize():
	if initialized:
		return
	
	parent_planet = get_parent()
	
	delaunay = Delaunay.new(Rect2(0,0,360,180))
	
	scale_radius = get_parent().scale_radius + 0.01
	surface_projection.mesh.radius = scale_radius
	surface_projection.mesh.height = surface_projection.mesh.radius*2

	rng.seed = seed
	
	for x in range(10):
		for y in range(10):
			add_point(Vector2(clamp(x + rng.randf_range(-10,10) * (360/10), 1, 360), clamp(y + rng.randf_range(-10,10) * (180/10), 1, 180)))

	var triangles = delaunay.triangulate()

	# each region is a voronoi cell - unfortunately this doesn't work on a spherical plane so we get some glitches around x = 0
	var sites = delaunay.make_voronoi(triangles)
	
	var c = 0
	for site in sites:
		show_site(site, false)
		
		regions.append(SurfaceRegion.new(site.center, site.polygon, str(c), determine_region_class()))
		c += 1
		
	generate_landmarks()
	initialized = true

func determine_region_class():
	var possible_classes = []
		
	if parent_planet.planet_class != Planetoid.PlanetClass.Water:
		possible_classes.append_array([RegionClass.ColdDesert, RegionClass.Plain, RegionClass.Canyon, RegionClass.Plateau, RegionClass.Crater, RegionClass.StonyDesert])
	if parent_planet.planet_class == Planetoid.PlanetClass.Ice:
		possible_classes.append_array([RegionClass.IceShelf, RegionClass.Glacier, RegionClass.Permafrost, RegionClass.FrozenOcean])
	if parent_planet.planet_class == Planetoid.PlanetClass.Water:
		possible_classes.append_array([RegionClass.Ocean, RegionClass.Ocean, RegionClass.Ocean, RegionClass.VolcanicArchipelago, RegionClass.Abyss, RegionClass.Trench, RegionClass.IcebergField])
	if parent_planet.planet_class == Planetoid.PlanetClass.Metallic or parent_planet.planet_class == Planetoid.PlanetClass.Terrestrial:
		possible_classes.append_array([RegionClass.MountainRange, RegionClass.KarstLandscape, RegionClass.HotDesert, RegionClass.SaltPan, RegionClass.GreatBasin, RegionClass.BasaltPlains])
	if parent_planet.planet_class == Planetoid.PlanetClass.Metallic:
		possible_classes.append_array([RegionClass.MagneticAnomaly])
	if parent_planet.planet_class == Planetoid.PlanetClass.Terrestrial:
		if parent_planet.habitable:
			possible_classes.append_array([RegionClass.Ocean, RegionClass.Abyss, RegionClass.Wetland])
	if parent_planet.volcanism == Planetoid.Volcanism.Low or parent_planet.volcanism == Planetoid.Volcanism.Medium or parent_planet.volcanism == Planetoid.Volcanism.High or parent_planet.volcanism == Planetoid.Volcanism.Extreme:
		possible_classes.append_array([RegionClass.FaultZone, RegionClass.GeothermalField])
		if not parent_planet.habitable:
			possible_classes.append_array([RegionClass.CryovolcanoField])
	if parent_planet.volcanism == Planetoid.Volcanism.Medium or parent_planet.volcanism == Planetoid.Volcanism.High or parent_planet.volcanism == Planetoid.Volcanism.Extreme:
		possible_classes.append_array([RegionClass.LavaField, RegionClass.MagmaOcean, RegionClass.LavaTubes])
	
	return possible_classes[rng.randi_range(0, len(possible_classes)-1)]

func add_point(point: Vector2):
	delaunay.add_point(point)

@onready var points_of_interest: Node3D = $PointsOfInterest

func generate_landmarks():
	var feature_num = 0
	
	var c = 0.9
	var rand = rng.randf()
	while feature_num < max_features and rand < c:
		# find a random point then determine it's region
		# getting a random point in a random region is too annoying
		var random_location = Vector2(rng.randf_range(-PI, PI), rng.randf_range(-2/PI, 2/PI))
		var region_at_location = get_region_at_point(random_location.y, random_location.x)
		
		if region_at_location == null:
			break
		else:
			print("Attempting to generate feature at ", random_location, " in ", region_at_location.region_name)
			var a
			var r : SurfaceRegion = region_at_location
			
			var possible_features = []
			# Mountains
			if r.region_class in [RegionClass.MountainRange, RegionClass.Crater, RegionClass.FaultZone, RegionClass.VolcanicArchipelago, RegionClass.Glacier, RegionClass.Plateau, RegionClass.RichPlateau, RegionClass.Plain, RegionClass.KarstLandscape]:
				possible_features.append(preload("res://system-generator/components/surface pois/mountain.tscn"))
			if r.region_class in [RegionClass.FaultZone, RegionClass.VolcanicArchipelago, RegionClass.GeothermalField, RegionClass.LavaField, RegionClass.MagmaOcean, RegionClass.BasaltPlains, RegionClass.LavaTubes, RegionClass.MagneticAnomaly]:
				possible_features.append(preload("res://system-generator/components/surface pois/volcano.tscn"))
			if r.region_class in [RegionClass.CryovolcanoField]:
				possible_features.append(preload("res://system-generator/components/surface pois/cryovolcano.tscn"))
			if r.region_class in [RegionClass.CryovolcanoField, RegionClass.GeothermalField, RegionClass.LavaField, RegionClass.VolcanicArchipelago, RegionClass.FaultZone, RegionClass.Plain]:
				possible_features.append(preload("res://system-generator/components/surface pois/geysers.tscn"))
			if r.region_class in [RegionClass.FaultZone, RegionClass.Plain, RegionClass.Ocean, RegionClass.KarstLandscape, RegionClass.Glacier, RegionClass.LavaField, RegionClass.MagmaOcean, RegionClass.RichPlateau, RegionClass.MountainRange, RegionClass.Trench, RegionClass.Abyss, RegionClass.SaltPan, RegionClass.GeothermalField, RegionClass.Canyon]:
				possible_features.append(preload("res://system-generator/components/surface pois/rift.tscn"))
			if r.region_class in [RegionClass.Crater, RegionClass.Plain, RegionClass.Plateau, RegionClass.FaultZone, RegionClass.HotDesert, RegionClass.ColdDesert, RegionClass.KarstLandscape, RegionClass.SaltPan, RegionClass.GreatBasin]:
				possible_features.append(preload("res://system-generator/components/surface pois/basin.tscn"))
			
			if len(possible_features) > 0:
				print("Found features")
				feature_num += 1 
				a = possible_features[rng.randi_range(0, len(possible_features)-1)].duplicate().instantiate()
				
				a.seed = rng.randi()
				a.set_class(r.region_class)
				a.parent_planet = parent_planet
				a.obj_name = "%s Feature %s" % [parent_planet.obj_name, feature_num]
				a.debug_pos = Vector2(rad_to_deg(random_location.x),rad_to_deg(random_location.y))
				a.region_name = r.region_name
				
				# The 90 degree offset here is because we rotate the map UV
				a.position = lat_long_to_cartesian(random_location.y, deg_to_rad(90) - random_location.x, scale_radius + 0.001)
				points_of_interest.add_child(a)
				
				rand = rng.randf()
				c *= 1.0 - (feature_num/100) # halve the chances of another landmark

@onready var surface_projection: MeshInstance3D = $SurfaceProjection
@onready var surface_map: SubViewport = $SurfaceProjection/SurfaceMap

func show_site(site: Delaunay.VoronoiSite, poly):
	if not poly:
		var line = Line2D.new()
		var p = site.polygon
		p.append(p[0])
		line.points = p
		line.width = 1
		line.default_color = Color.GREEN_YELLOW
		surface_map.add_child(line)

	if poly:
		var polygon = Polygon2D.new()
		var p = site.polygon
		p.append(p[0])
		polygon.polygon = p
		polygon.color = Color(randf_range(0,1),randf_range(0,1),randf_range(0,1),0.5)
		polygon.z_index = -1
		surface_map.add_child(polygon)

func lat_long_to_cartesian(latitude, longitude, radius):
	var x = radius * cos(latitude) * cos(longitude)
	var z = radius * cos(latitude) * sin(longitude)
	var y = radius * sin(latitude)
	return Vector3(x,y,z)

func get_region_at_point(latitude, longitude):
	var pos_x = rad_to_deg(longitude) + 180
	var pos_y = 90 - rad_to_deg(latitude)
	$SurfaceProjection/SurfaceMap/Cursor.position = Vector2(pos_x, pos_y)
	for i in regions:
		if i.point_in_region(pos_x, pos_y):
			return i
	return null
