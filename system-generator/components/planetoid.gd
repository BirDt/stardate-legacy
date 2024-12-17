extends MeshInstance3D
class_name Planetoid

@export var mass := 0.0 # Earth Masses
@export var orbit_distance := 0.0 # AU

var scale_distance :
	get:
		var d = orbit_distance*(80 if not moon else 700)
		if not moon:
			return d
		else:
			return clamp(d, parent_planetoid.scale_radius + scale_radius + 0.5, INF)

var planet_radius : float # Earth radii
var density : float # kg/m3
var orbit_speed : float # km/s
var orbital_period : float 
var orbital_period_human_readable : float # solar days
var rotation_period : float # solar days
var axial_tilt : float # radians

var surface_gravity : float # Gs
var surface_temperature : float # Kelvin
var atmospheric_pressure : float # Atmospheres

var crust_composition : ElementalCompositionDigest = ElementalCompositionDigest.new()
var atmospheric_composition : ElementalCompositionDigest = ElementalCompositionDigest.new()

@export var force_habitable_generation := false

const G = 6.67 * pow(10, -11)

const PLANET_MASS_TO_RADIUS = preload("res://curves/planet_mass_to_radius.tres")

@onready var orbit_vis: Draw3D = $OrbitVis

const PLANETOID = preload("res://system-generator/components/planetoid.tscn")

var habitable : bool # whether liquid water can exist on the surface

var system : StarSystem

var parent_sun : Star
var parent_planetoid : Planetoid

var scale_radius

var obj_name : String

var tidal_lock = false

@export var moon = false
var moons : Array[Planetoid]

@onready var surface: PlanetSurface = $Surface

func _ready() -> void:
	print("New Planetoid with mass of ", mass, " Earth Masses")
	top_level = true
	if force_habitable_generation:
		print("Forcing habitable planet generation...")
	
	# we need to determine if our parent is a star or if we are a moon
	if get_parent() is Star:
		parent_sun = get_parent()
		system = parent_sun.get_parent()
	elif get_parent() is Planetoid:
		parent_planetoid = get_parent()
		system = parent_planetoid.parent_sun.get_parent()
	
	determine_radius()
	determine_surface_gravity(true)
	determine_orbit()
	determine_habitability()
	
	if not moon:
		generate_moons()
		generate_ring()
	
	determine_classification()
	determine_surface_temperature()
	determine_composition()
	determine_appearance()
	
	# we generate surface details when detail view is activated, so we need to pre-set the surface seed otherwise we might get
	# different generation depend on which planet is first generated
	surface.seed = randi()
	surface.point_num = randi_range(4, 40)
	surface.max_features = ceil(20 * planet_radius)
	
	orbit_vis.reparent(get_parent())
	
	WorldController.tick_propagate.connect(_tick_process)

func determine_radius():
	if force_habitable_generation:
		planet_radius = randf_range(0.5, 2.49)
		# Habitable planets should have a gravity between 0.4 and 1.7
		# TODO: this is hacky, come back here later
		while surface_gravity == null or surface_gravity < 0.4  or surface_gravity > 1.7:
			determine_surface_gravity(false)
			if surface_gravity < 0.3:
				#print("Decreasing radius ", planet_radius, " ", surface_gravity, " ", mass)
				planet_radius -= 0.2 * planet_radius
			else:
				#print("Increasing radius ", planet_radius, " ", surface_gravity, " ", mass)
				planet_radius += 0.2 * planet_radius
	else:
		planet_radius = PLANET_MASS_TO_RADIUS.sample(mass) + randfn(0, 0.15)
	
	print("Planet radius is ", planet_radius, " Earth Radii")
	
	var projected_volume = (4.0/3.0) * PI * pow(planet_radius * 6378 * 1000, 3)
	var r_mass = mass * 5.98 * pow(10, 24)
	density = (r_mass/projected_volume)
	
	# scale size
	if parent_sun:
		mesh.radius = (0.75 if planet_radius > 0.8 and planet_radius < 3 else 0.5 if planet_radius < 0.8 else 1) * parent_sun.radius
	else:
		mesh.radius = (0.25 if planet_radius > 0.8 and planet_radius < 3 else 0.1 if planet_radius < 0.8 else 0.5) * parent_planetoid.mesh.radius
	
	mesh.height = mesh.radius*2
	$HoverDetector/CollisionShape3D.shape.radius = mesh.radius
	scale_radius = mesh.radius
	
	print("Planet density is ", density, " kg/m^3")

func determine_surface_gravity(logging):
	# this does not account for variable density
	var real_mass = mass * 5.98 * pow(10, 24)
	var real_rad = planet_radius * 6378 * 1000
	
	var msec_gravity = G * (real_mass / pow(real_rad, 2))
	surface_gravity = msec_gravity * 0.10197162129779
	
	if logging:
		print("Planet gravity is ", msec_gravity, " m/sec^2 or ", surface_gravity, "g")

func determine_orbit():
	# if we forced habitable generation, then our orbit distance was decided at the system level
	# if we didn't, then we generate it greater than the roche limit for the mass
	if not force_habitable_generation:
		var p
		var r
		if parent_sun:
			p = parent_sun
			r = p.radius * p.SOLAR_RADIUS
		else:
			p = parent_planetoid
			r = p.mesh.radius * 0.009157 * Star.SOLAR_RADIUS
		var m = mass * 5.98 * pow(10, 24)
		var hyp_roche = ((r) * 2 * pow(m/density, 1.0/3.0)) * 6.6845871226706 * pow(10, -12)
		if p is Star:
			orbit_distance = randf_range(hyp_roche + 0.05, 50 + p.hz_outer_radius)
		else:
			orbit_distance = randf_range((hyp_roche), 0.1)
			print("Minimum moon orbit distance of ", hyp_roche, " AU - ", p.mass, " ", mass)
	
	var parent_mass : float # Suns
	if parent_sun:
		parent_mass = parent_sun.mass 
	else:
		parent_mass = parent_planetoid.mass / 333000
	
	parent_mass *= 1.98847 * pow(10, 30)
	
	var distance_at_apoapsis_m = (orbit_distance * 1.495979)*100000000*1000
	
	orbit_speed = sqrt((G * parent_mass)/distance_at_apoapsis_m) / 1000

	print("Planetary orbit at ", orbit_distance, " AU")
	print("Planet orbiting sun at ", orbit_speed, " km/s")
	
	orbital_period = (2 * PI * orbit_distance)/orbit_speed
	orbital_period_human_readable = abs(orbital_period / 0.211 * 365) #0.211 is 1 solar day
	
	print("Orbital period of ", orbital_period_human_readable, " days") 
	
	# we want habitable planets to have a earth-like rotation period
	if force_habitable_generation:
		rotation_period = randfn(1, 0.2) * (1 if randf() < 0.5 else -1)
		axial_tilt = deg_to_rad(randf_range(0, 35))
	else:
		rotation_period = randfn(1/mass, 1) * (-1 if randf() < 0.5 else 1)
		axial_tilt = deg_to_rad(randf_range(0, 90))
	
	# tidal_lock is just a value for backend tracking, it isn't used in any calculation
	if is_equal_approx(rotation_period, orbital_period):
		tidal_lock = true
	
	#rotation.z = axial_tilt
	print("Rotation period of ", abs(rotation_period), " days")
	print("Axial tilt of ", rad_to_deg(axial_tilt), " degrees")

func determine_habitability():
	# can we have liquid water?
	var b : Star
	var o : float
	if parent_sun:
		b = parent_sun
		o = orbit_distance
	elif parent_planetoid:
		b = parent_planetoid.get_parent()
		o = parent_planetoid.orbit_distance
	
	habitable = b.hz_inner_radius < o and b.hz_outer_radius > o and surface_gravity > 0.4 and surface_gravity < 1.7 
	could_be_ice = o > b.hz_outer_radius
	could_be_water = habitable
	print("Planet is habitable? ", habitable)

## Planetary Class Assignment

enum PlanetClass {Terrestrial, Metallic, Water, Gas, Ice}
enum AtmosphereClass {None, Light, EarthLike, Heavy}
enum Volcanism {None, Low, Medium, High, Extreme}

var could_be_ice = false
var could_be_gas = false
var could_be_water = false
var could_be_metallic = true
var could_be_terrestrial = true

var planet_class : PlanetClass
var atmosphere_class : AtmosphereClass
var volcanism : Volcanism
var volcanism_force : float # Ne-6

func determine_classification():
	if mass > 10 and not moon:
		could_be_gas = true
	if mass < 15:
		could_be_ice = could_be_ice
		could_be_water = could_be_water 
	if mass > 15:
		could_be_ice = false
		could_be_water = false
	if mass > 5:
		could_be_metallic = false
		could_be_terrestrial = false
	
	var class_seed = randf()
	
	if could_be_gas and class_seed < 0.8:
		planet_class = PlanetClass.Gas
	elif could_be_ice and class_seed > 0.7 and class_seed < 0.9:
		planet_class = PlanetClass.Ice
	elif could_be_water and class_seed > 0.9:
		planet_class = PlanetClass.Water
	elif could_be_metallic and class_seed > 0.5 and class_seed < 0.7:
		planet_class = PlanetClass.Metallic
	elif could_be_terrestrial:
		planet_class = PlanetClass.Terrestrial
	elif could_be_gas:
		planet_class = PlanetClass.Gas
	else:
		planet_class = PlanetClass.Terrestrial
		
	print("Planet is a ", PlanetClass.keys()[planet_class], " planet")
	
	if force_habitable_generation:
		atmosphere_class = AtmosphereClass.EarthLike
	elif not planet_class == PlanetClass.Gas:
		var atmos_seed = randf()
		if atmos_seed < 0.5:
			atmosphere_class = AtmosphereClass.None
		elif atmos_seed < 0.75:
			atmosphere_class = AtmosphereClass.Light
		elif atmos_seed < 0.9:
			atmosphere_class = AtmosphereClass.EarthLike
		else: 
			atmosphere_class = AtmosphereClass.Heavy
	else:
		atmosphere_class = AtmosphereClass.None
		
	print("Planet has a ", AtmosphereClass.keys()[atmosphere_class], " atmosphere")
	
	# we only consider the closest moon for volcanism
	if len(moons) > 0 and planet_class != PlanetClass.Gas and not moon:
		moons.sort_custom(func (a : Planetoid, b : Planetoid): return a.orbit_distance < b.orbit_distance)
		var closest_moon = moons[0]
		var real_mass = closest_moon.mass * 5.98 * pow(10, 24)
		var real_radius = planet_radius * 6378
		var real_distance = closest_moon.orbit_distance * 1.495979 * pow(10, 8)
		volcanism_force = G * real_mass * ((2*real_radius)/pow(real_distance, 3))
	elif moon:
		var real_mass = parent_planetoid.mass * 5.98 * pow(10, 24)
		var real_radius = planet_radius * 6378
		var real_distance = orbit_distance * 1.495979 * pow(10, 8)
		volcanism_force = G * real_mass * ((2*real_radius)/pow(real_distance, 3))
	else:
		volcanism_force = 0
	
	if is_zero_approx(volcanism_force):
		volcanism = Volcanism.None
	elif volcanism_force < 1.2:
		volcanism = Volcanism.Low
	elif volcanism_force < 5:
		volcanism = Volcanism.Medium
	elif volcanism_force < 20:
		volcanism = Volcanism.High
	else:
		volcanism = Volcanism.Extreme
	
	print("Volcanism force of ", volcanism_force, " NE-6 - ", Volcanism.keys()[volcanism])

func determine_surface_temperature():
	match atmosphere_class:
		AtmosphereClass.None:
			atmospheric_pressure = 0
		AtmosphereClass.Light:
			atmospheric_pressure = randf_range(0, 0.6)
		AtmosphereClass.EarthLike:
			atmospheric_pressure = randf_range(0.6, 1.4)
		AtmosphereClass.Heavy:
			atmospheric_pressure = randf_range(1.4, 100)
	
	var albedo = 0.0
	
	match planet_class:
		PlanetClass.Terrestrial:
			albedo = randf_range(6,11)
		PlanetClass.Metallic:
			albedo = randf_range(0,6)
		PlanetClass.Gas:
			albedo = randf_range(30, 100)
		PlanetClass.Water:
			albedo = randf_range(10, 20)
		PlanetClass.Ice:
			albedo = randf_range(50, 70)
			
	match atmosphere_class:
		AtmosphereClass.None:
			albedo += 0
		AtmosphereClass.Light:
			albedo += randf_range(0, 2)
		AtmosphereClass.EarthLike:
			albedo += randf_range(2, 12)
		AtmosphereClass.Heavy:
			albedo += randf_range(12, 100)
	
	albedo = clamp(albedo/100, 0, 1)
	
	var greenhouse = 0.0
	
	match atmosphere_class:
		AtmosphereClass.None:
			greenhouse = 0
		AtmosphereClass.Light:
			greenhouse = randf_range(0, 0.9)
		AtmosphereClass.EarthLike:
			greenhouse = randf_range(0.9, 1.5)
		AtmosphereClass.Heavy:
			greenhouse = randf_range(1.5, 500)
	
	var L : float
	var d : float
	if parent_sun:
		L = parent_sun.luminosity
		d = orbit_distance
	elif parent_planetoid:
		L = parent_planetoid.get_parent().luminosity
		d = parent_planetoid.orbit_distance
	L *= 3.828 * pow(10, 26)
	d *= 1.496 * pow(10, 11)
	
	var stefan_boltzmann = 5.67 * pow(10, -8)
	
	# this is very rough
	surface_temperature = (pow((L/pow(d, 2)) * ((1-albedo)/(4*stefan_boltzmann)) * (1 + ((3.0/4.0)*greenhouse)), 1.0/4.0))/2
	
	# Add some variation based on volcanism
	match volcanism:
		Volcanism.Extreme:
			surface_temperature += randf_range(100,1000)
		Volcanism.High:
			surface_temperature += randf_range(15,100)
		Volcanism.Medium:
			surface_temperature += randf_range(5,15)
		Volcanism.Low:
			surface_temperature += randf_range(0,5)
		_:
			surface_temperature += 0
	
	if planet_class == PlanetClass.Gas:
		surface_temperature *= randf_range(100, 500)
	
	print("Average surface temperature of ", surface_temperature - 273.15, " Celsius")

func determine_composition():
	var possible_crust_elements = PeriodicTable.elements.values()
	var abundance = system.remaining_elemental_mass.composition
	
	# filter natural
	possible_crust_elements = possible_crust_elements.map(func (x: Element): return null if not x or not x.natural else x)
	
	match planet_class:
		PlanetClass.Terrestrial:
			# Filter to solids only
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or x.melting_point == 0 or surface_temperature > x.melting_point else x)
			# Remove heavy elements
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or x.atomic_number > 34 else x)
		PlanetClass.Metallic:
			# filter to solids only
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or x.melting_point == 0 or surface_temperature > x.melting_point else x)
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or x.category in [Element.Category.Nonmetal, Element.Category.NobleGas, Element.Category.Halogen, Element.Category.Metalloid, Element.Category.AlkaliMetal, Element.Category.AlkaliEarthMetal] else x)
		PlanetClass.Water:
			# filter to liquids and solids
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or surface_temperature > x.boiling_point else x)
		PlanetClass.Ice:
			# solids only
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or x.melting_point == 0 or surface_temperature > x.melting_point else x)
		PlanetClass.Gas:
			# gasses only
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or x.boiling_point == 0 or surface_temperature < x.boiling_point else x)
		_:
			# Filter to solids only
			possible_crust_elements = possible_crust_elements.map(func (x : Element): return null if not x or x.melting_point == 0 or surface_temperature > x.melting_point else x)
	
	possible_crust_elements = possible_crust_elements.filter(func (x): return x != null)
	var possible_abundance = []
	
	for i in abundance:
		if i.element in possible_crust_elements:
			var c = i
			if planet_class == PlanetClass.Terrestrial and i.element.atomic_number == 14:
				c.percent = 0.5
			possible_abundance.push_back(c)
	
	var comp_length = randf_range(0, 10)
	var initial_comp = randf_range(0.4, 0.8)
	while len(possible_abundance) > comp_length:
		possible_abundance.sort_custom(func (x, y): return x.percent > y.percent)
		var s
		if planet_class == PlanetClass.Terrestrial and len(crust_composition.composition) == 0:
			s = possible_abundance.slice(0, 1)
		else:
			s = possible_abundance.slice(0, 5)
		s.shuffle()
		var e = s[0]
		possible_abundance.erase(e)
		if len(crust_composition.composition) == 0:
			crust_composition.push(e.element, initial_comp)
		else:
			crust_composition.push(e.element, randf_range(0, 1.0 - crust_composition.sum_total()))
			
	if atmosphere_class != AtmosphereClass.None:
		var possible_atmosphere_elements = PeriodicTable.elements.values()
		abundance = system.remaining_elemental_mass.composition
		
		# filter natural
		possible_atmosphere_elements = possible_atmosphere_elements.map(func (x: Element): return null if not x or not x.natural else x)
		# Filter to gasses only
		possible_atmosphere_elements = possible_atmosphere_elements.map(func (x : Element): return x if x and surface_temperature > x.boiling_point else null)
		
		possible_atmosphere_elements = possible_atmosphere_elements.filter(func (x): return x != null)
		possible_abundance = []
		
		for i in abundance:
			if i.element in possible_atmosphere_elements:
				var c = i
				if not c.element.category in [Element.Category.Nonmetal, Element.Category.NobleGas]:
					c.percent /= c.element.atomic_number * 10
				possible_abundance.push_back(c)
		
		comp_length = randf_range(0, 10)
		initial_comp = randf_range(0.5, 0.9)
		while len(possible_abundance) > comp_length:
			possible_abundance.sort_custom(func (x, y): return x.percent > y.percent)
			var s
			s = possible_abundance.slice(0, 5)
			s.shuffle()
			var e = s[0]
			possible_abundance.erase(e)
			if len(atmospheric_composition.composition) == 0:
				atmospheric_composition.push(e.element, initial_comp)
			else:
				atmospheric_composition.push(e.element, randf_range(0, 1.0 - atmospheric_composition.sum_total()))

func determine_appearance():
	match planet_class:
		PlanetClass.Gas:
			mesh.material = preload("res://materials/planetoids/base/gas.tres").duplicate()
		PlanetClass.Water:
			mesh.material = preload("res://materials/planetoids/base/water.tres").duplicate()
		PlanetClass.Ice:
			mesh.material = preload("res://materials/planetoids/base/ice.tres").duplicate()
		PlanetClass.Metallic:
			mesh.material = preload("res://materials/planetoids/base/metallic.tres").duplicate()
		_:
			mesh.material = preload("res://materials/planetoids/base/terrestrial.tres").duplicate()
	
	# gas giants dont have volcanism or atmoshperes, so we skip them (if we don't do this, it causes problems)
	if planet_class != PlanetClass.Gas:
		match volcanism:
			Volcanism.Extreme:
				mesh.material.next_pass = preload("res://materials/planetoids/volcanism/extreme.tres").duplicate()
			Volcanism.High:
				mesh.material.next_pass = preload("res://materials/planetoids/volcanism/high.tres").duplicate()
			Volcanism.Medium:
				mesh.material.next_pass = preload("res://materials/planetoids/volcanism/medium.tres").duplicate()
			_:
				mesh.material.next_pass = preload("res://materials/planetoids/volcanism/low.tres").duplicate()
		
		match atmosphere_class:
			AtmosphereClass.None:
				mesh.material.next_pass.next_pass = preload("res://materials/planetoids/atmos/none.tres").duplicate()
			AtmosphereClass.Light:
				mesh.material.next_pass.next_pass = preload("res://materials/planetoids/atmos/light.tres").duplicate()
			AtmosphereClass.EarthLike:
				mesh.material.next_pass.next_pass = preload("res://materials/planetoids/atmos/earthlike.tres").duplicate()
			AtmosphereClass.Heavy:
				mesh.material.next_pass.next_pass = preload("res://materials/planetoids/atmos/heavy.tres").duplicate()

func generate_moons():
	if randf() < (0.5 if mass < 10 else 0.8):
		while randf() < ((0.2 if mass < 10 else 0.5)/len(moons)):
			print("Generating moon...")
			var p = PLANETOID.instantiate()
			var body_mass = randf_range(0.000006, 0.025)
			get_parent().get_parent().remaining_mass_earth -= body_mass
			p.mass = body_mass
			p.moon = true
			add_child(p)
			moons.push_back(p)
	print("Generated ", len(moons), " moons")
	
const RING = preload("res://system-generator/components/ring.tscn")

func generate_ring():
	var c = clampf(randf(), 0.0, 0.8)/mass
	if c < 0.0065 and randf() < 0.5: # 65% chance at mass of Jupiter, then a tossup
		var r = RING.instantiate()
		add_child(r)

func _tick_process(t) -> void:
	get_planet_pos_for_tick(t)
	get_planet_rotation_for_tick(t)
	update_orbit_visualisation()

var INITIAL_ANGLE := randf_range(0,360)

func update_orbit_visualisation():
	orbit_vis.clear()
	orbit_vis.circle_XZ(Vector3.ZERO, scale_distance)

func get_planet_pos_for_tick(t):
	position = get_parent().position
	var d = scale_distance
	var omega = ((2 * PI) / ((2 * PI * orbit_distance) / (orbit_speed))) / 19.5
	var angle_at_time = deg_to_rad(INITIAL_ANGLE) + (omega * t)
	var x_pos = d * cos(angle_at_time)
	var z_pos = d * sin(angle_at_time)
	
	position.x += x_pos
	position.z += z_pos
	

func get_planet_rotation_for_tick(t):
	var r = Vector3(0, rotation.y + ((1.5*PI/rotation_period)*WorldController.timescale), 0)
	rotation = r
	
@onready var planet_details: Control = $PlanetDetails
@onready var v_box_container: VBoxContainer = $PlanetDetails/Panel/VBoxContainer

func populate_planet_details():
	var info_strings : Array[String] = [obj_name,
										"%s world with %s atmosphere" % [PlanetClass.keys()[planet_class], AtmosphereClass.keys()[atmosphere_class]],
										"%s volcanism" % [Volcanism.keys()[volcanism]],
										"Surface Temperature: %s Celsius" % [surface_temperature - 273.15],
										"Surface Gravity: %s Gs" % [surface_gravity],
										"Atmospheric Pressure: %s Atmospheres" % [atmospheric_pressure],
										"Mass: %s Earth Masses" % [mass],
										"Radius: %s Earth Radii" % [planet_radius],
										"Axial Tilt: %s Degrees" % [rad_to_deg(axial_tilt)],
										"Distance to Parent Body: %s AU" % [orbit_distance],
										"Orbital Period: %s Solar Days" % [orbital_period_human_readable],
										"Rotation Period: %s Solar Days" % [abs(rotation_period)],
										"Tidally Locked: %s" % tidal_lock,
										"Atmospheric Composition: %s" % [atmospheric_composition.human_readable() if atmosphere_class != AtmosphereClass.None else "No Atmosphere"],
										"Crust Composition: %s" % [crust_composition.human_readable()]]
	
	for i in info_strings:
		var x = Label.new()
		x.add_theme_font_size_override("font_size", 12)
		x.text = i
		v_box_container.add_child(x)

func _on_click_detector_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	# make sure we show the right details
	if not should_show_detail_view:
		planet_details.position = camera.unproject_position(event_position)
	else:
		coordinates.position = camera.unproject_position(event_position)
		var e = to_local(event_position)
		var r = surface.get_region_at_point(asin(e.y/scale_radius), atan2(e.x, e.z))
		if r:
			surface_region.text = "Region: " + r.region_name
		else:
			surface_region.text = "Null Region"
		longitude.text = "%.4f degrees East" % rad_to_deg(atan2(e.x, e.z))
		latitude.text = "%.4f degrees North" % rad_to_deg(asin(e.y/scale_radius))

func _on_hover_detector_mouse_entered() -> void:
	if not should_show_detail_view:
		planet_details.show()
	else:
		coordinates.show()

func _on_hover_detector_mouse_exited() -> void:
	planet_details.hide()
	coordinates.hide()

var should_show_detail_view := false :
	set(x):
		if should_show_detail_view != x:
			should_show_detail_view = x
			_show_detail_view(should_show_detail_view)
			
@onready var coordinates: Control = $Coordinates
@onready var surface_region: Label = $Coordinates/Panel/VBoxContainer/SurfaceRegion
@onready var longitude: Label = $Coordinates/Panel/VBoxContainer/Longitude
@onready var latitude: Label = $Coordinates/Panel/VBoxContainer/Latitude

func _show_detail_view(d):
	if planet_class != PlanetClass.Gas:
		surface.initialize()
	$Surface.visible = d
	if d:
		planet_details.hide()
	else:
		coordinates.hide()

func _process(delta: float) -> void:
	should_show_detail_view = WorldController.detail_view and (WorldController.camera.watching == self)
