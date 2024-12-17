extends Node3D
class_name StarSystem

@export var system_statistics : SystemVariables

@export var force_habitable := false

@export var random_seed := true
@export var sys_seed := 0
@export var skybox_seed := 0.0

var remaining_mass : float
var remaining_mass_earth :
	get:
		return remaining_mass * 333000
	set(x):
		remaining_mass = x / 333000

var elemental_mass : ElementalCompositionDigest = ElementalCompositionDigest.new()
var remaining_elemental_mass : ElementalCompositionDigest = ElementalCompositionDigest.new()

const STAR = preload("res://system-generator/components/star.tscn")
const PLANETOID = preload("res://system-generator/components/planetoid.tscn")

@onready var trackball_camera = $CameraParent
@onready var switches: VBoxContainer = $SystemUI/SystemOutline/MarginContainer/ScrollContainer/VBoxContainer

var system_root : Star
var planets : Array[Planetoid]

@onready var world_environment: WorldEnvironment = $WorldEnvironment

var sector : String

func _ready() -> void:
	if random_seed:
		randomize()
		sys_seed = randi()
	seed(sys_seed)
	
	skybox_seed = randf_range(10000, 100000)
	print("Skybox seed: ", skybox_seed)
	
	world_environment.environment.sky.sky_material.set("shader_parameter/seed", skybox_seed)
	
	# Our system statistics governs the total mass of the system, it's age, and it's elemental abundances
	if system_statistics == null:
		print("Generating new system data with seed ", sys_seed, "...")
		system_statistics = SystemVariables.new()
	
	# this clusterfuck converts abundance ppm to total mass of each element as well as the percentage count of each element
	remaining_mass = system_statistics.mass
	elemental_mass.composition = []
	for i in system_statistics.abundance.keys():
		elemental_mass.push(PeriodicTable.elements[i], system_statistics.abundance[i] * remaining_mass)
	for i in system_statistics.abundance.keys():
		remaining_elemental_mass.push(PeriodicTable.elements[i], system_statistics.abundance[i])
	print("System elemental percentages: ", remaining_elemental_mass.human_readable())
	
	# generate the system sector name using markov chainis
	var file = FileAccess.open("res://system-generator/resources/names/sector_name.txt", FileAccess.READ)
	var m = MarkovMachine.new(file.get_as_text())
	sector = m.generate_new().capitalize()
	
	print("Sector is ", sector)
	
	print("Generating new root star...")
	# generate the central star (we dont have binary systems because the orbit math is too annoying), planets (and their features) and buttons to quickly go between each
	generate_star()
	generate_features()
	generate_feature_switches()
	
	WorldController.tick_propagate.connect(_tick_process)
	
	save_system_seed()

func save_system_seed():
	var file = FileAccess.open("user://saved_system_seed", FileAccess.WRITE)
	file.store_string(str(sys_seed) + "\n" + str(int(force_habitable)))

func generate_star() -> void:
	#chomp a random portion of mass
	#since we want the star to have exoplanets, we cap this at 0.99, and minimum of 0.2 because that makes our smallest star an M
	#20% of the time, we let 'er rip
	var mass_perc : float
	if randf() < 0.8:
		mass_perc = clamp(randfn(0.95, 0.04), 0.2, 0.99)
	else:
		mass_perc = randf_range(0.2, 0.99)
	var star_mass = remaining_mass * mass_perc
	remaining_mass -= star_mass
	
	system_root = STAR.instantiate()
	system_root.mass = star_mass
	system_root.age = system_statistics.system_age
	add_child(system_root)
	
	trackball_camera.watching = system_root
	
	# We add a new button for watching the root star
	var b = Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = system_root.obj_name
	b.pressed.connect(func (): trackball_camera.watching = system_root)
	switches.add_child(b)
	
	# we need to cull hydrogen and helium mass, since we assume that's what the star is made of.
	# if our system is majority hydrogen and helium (which usually happens) and we don't do this, then we'll end up with a lot of
	# hydrogen gas giants and hydrogen/helium atmospheres
	print("Remaining system mass: ", remaining_mass, " Solar Masses")
	var hydrogen_mass = system_root.mass * system_root.composition.find(1)
	var helium_mass = system_root.mass * system_root.composition.find(2)
	elemental_mass.modify(1, clamp(elemental_mass.find(1) - hydrogen_mass, 0.07, INF))
	elemental_mass.modify(2, clamp(elemental_mass.find(2) - helium_mass, 0.02, INF))
	remaining_elemental_mass.composition = []
	var e_mass = elemental_mass.sum_total()
	for i in system_statistics.abundance.keys():
		remaining_elemental_mass.push(PeriodicTable.elements[i], elemental_mass.find(i)/e_mass)
	print("System elemental percentages: ", elemental_mass.human_readable())

func can_generate_planetoid():
	# if we have enough mass to generate a new planetoid, we return true
	return remaining_mass_earth > 0.05

func generate_planetoid(x):
	var p = PLANETOID.instantiate()
	if x:
		#NOTE: force_habitable does not guarantee a "habitable planet", only one within the goldilocks zone of the parent star
		var body_mass = randf_range(0.107, 9.44)
		remaining_mass_earth -= body_mass
		var p_orbit = randf_range(system_root.hz_inner_radius, system_root.hz_outer_radius)
		p.mass = body_mass
		p.orbit_distance = p_orbit
		p.force_habitable_generation = force_habitable
	else:
		var body_mass = randf_range(0.05, 1000) if randf() < 0.3 else randf_range(0.05, 15) # too many fkn gas giants
		remaining_mass_earth -= body_mass
		p.mass = body_mass
	system_root.add_child(p)
		
	planets.push_back(p)
	
	print("Remaining system mass: ", remaining_mass_earth, " Earth Masses")

func generate_features():
	print("Generating system planets")
	
	generate_planetoid(force_habitable) # always generate at least one planetoid, otherwise it's no fun

	var many_planets = randf() > 0.8 # if we should generate many planets
	
	#hard cap of 12, since that seems to be all it can handle without shitting itself perfomrance wise
	while can_generate_planetoid() and randf() > clamp(len(planets)* 0.02 if many_planets else 0.181, 0, 0.9) and len(planets) < 12:
		generate_planetoid(false)
	
	print("Finished with ", len(planets), " planets and ", remaining_mass_earth, " Earth Masses remaining")

func generate_feature_switches():
	# generate all the watch buttons
	planets.sort_custom(func (x : Planetoid, y : Planetoid): return x.orbit_distance < y.orbit_distance)
	var p = 0
	for i in planets:
		p += 1
		var star_name = system_root.obj_name 
		i.obj_name = "%s %s" % [star_name, p]
		var b = Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "├─  %s" % i.obj_name
		b.pressed.connect(func (): trackball_camera.watching = i)
		switches.add_child(b)
		i.populate_planet_details()
		i.moons.sort_custom(func (x : Planetoid, y : Planetoid): return x.orbit_distance < y.orbit_distance)
		var moon_designations = "abcdefghijklmnopqrstuvwxyz".split("")
		var m = 0
		for j in i.moons:
			j.obj_name = "%s%s" % [i.obj_name, moon_designations[m]]
			m += 1
			var bx = Button.new()
			bx.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bx.text = "│ └  %s" % j.obj_name
			bx.pressed.connect(func (): trackball_camera.watching = j)
			j.populate_planet_details()
			switches.add_child(bx)

func _tick_process(t) -> void:
	# update current time label
	var hours = int(floor(t / (0.00000190258752 * 60 * 4)))
	var days = hours/24
	hours = hours % 24
	var months = days/30
	days = days % 30
	var years = months/12
	months = months % 12
	$SystemUI/Label.text = "Year: %s, Month: %s, Day: %s, Hour: %s " % [years, months, days, hours]


func _on_timescale_slider_value_changed(value: float) -> void:
	WorldController.timescale_index = floor(value)
