extends CSGSphere3D
class_name Star

@export var mass := 0.0
@export var age := 0.0

enum StellarClass {O, B, A, F, G, K, M}

var stellar_class : StellarClass
var temperature : float # Kelvin
var luminosity : float # L☉
var solar_radii : float # r☉
var density : float # kg/m3

var hz_inner_radius : float # in AU
var hz_outer_radius : float # in AU

var composition : ElementalCompositionDigest = ElementalCompositionDigest.new()

var star_color : Color

const SOLAR_RADIUS = 6.957

var obj_name : String

var scale_radius

func _ready() -> void:
	print("New Star with mass of ", mass, " Solar Masses and ", age, " Gyr years old.")
	determine_stellar_class()
	determine_temperature()
	determine_radius()
	determine_habitable_zone()
	determine_composition()
	determine_name()
	populate_star_details()
	
func determine_stellar_class():
	# we determine stellar class solely by mass
	# yes, this should take age into account, but im not an astrophysicist so i don't know how i would do work this out programmatically
	if mass < 0.45: #0
		stellar_class = StellarClass.M
	elif mass > 0.45 and mass < 0.8: #0.007
		stellar_class = StellarClass.K
	elif mass > 0.8 and mass < 1.04: #0.01
		stellar_class = StellarClass.G
	elif mass > 1.04 and mass < 1.4: #0.013
		stellar_class = StellarClass.F
	elif mass > 1.4 and mass < 2.1: #0.021
		stellar_class = StellarClass.A
	elif mass > 2.1 and mass < 16: #0.065
		stellar_class = StellarClass.B
	elif mass > 16: #0.35
		stellar_class = StellarClass.O
	
	print("Star class is ", StellarClass.keys()[stellar_class])
	
const STAR_MASS_TO_TEMPERATURE = preload("res://curves/star_mass_to_temperature.tres")
const STAR_TEMPERATURE_TO_COLOR = preload("res://gradients/star_temperature_to_color.tres")

func determine_temperature():
	# temperature is determined by a curve sampled by mass, which uses a bunch of known stars as sample points
	# star color is determined likewise
	var sample_point = (mass/100)
	temperature = STAR_MASS_TO_TEMPERATURE.sample(sample_point) * 1000
	star_color = STAR_TEMPERATURE_TO_COLOR.sample(sample_point)
	
	material.set("albedo_color", star_color)
	
	print("Star temperature is ", temperature, " K")
	print("Star color is #", star_color.to_html(false))
	
	## luminosity
	## this clusterfuck is my attempt at a curve of best fit for the hertzsprung-russel diagram
	## it sucks
	luminosity = 14341850000 + ((78.43685-14341850000)/(1 + pow(temperature/145852.2,7.237745)))-78.46
	
	print("Star luminosity is ", luminosity, " L☉")

func determine_radius():
	var r : float = pow((3.0 * mass)/4.0*PI, 1.0/3.0) # 0.62035 is 1 solar mass
	solar_radii = (r/0.62035) - 1.14503109452965 # This makes it so a star with 1 mass is always 1 in radius
	
	if solar_radii < 0.8:
		radius = 1.5
	elif solar_radii > 0.8 and solar_radii < 1.5:
		radius = 5
	elif solar_radii > 1.5 and solar_radii < 2.5:
		radius = 7.5
	else:
		radius = 15
	$HoverDetector/CollisionShape3D.shape.radius = radius
	
	scale_radius = radius
	
	print("Star is ", solar_radii, " Solar Radii")
	
	var projected_volume = (4.0/3.0) * PI * pow(solar_radii * SOLAR_RADIUS, 3)
	var r_mass = mass * 1.9885
	density = (r_mass/projected_volume) * 1000 * 1000
	
	print("Star density is ", density, " kg/m^3")

func determine_habitable_zone():
	hz_inner_radius = sqrt(luminosity / 1.1)
	hz_outer_radius = sqrt(luminosity / 0.53)
	
	print("Star is habitable between ", hz_inner_radius, " AU and ", hz_outer_radius, " AU")
	
	var hyp_roche = 2.44 * (solar_radii * SOLAR_RADIUS) * pow(5513/density, 1.0/3.0)
	print("Hypothetical Earth Roch Limit is ", hyp_roche, " km")
	var hz_outer_km = hz_outer_radius * 1.495979 * pow(10, 8)
	if hyp_roche > hz_outer_km:
		print("WARNING: Projected Roche Limit greater than habitable zone. Star cannot support habitable worlds.")
	else:
		print("Habitable zone outside Roche Limit")

func determine_composition():
	# we assume our star is composed of hydrogen and helium only. this is unrealistic,  but it prevents too much hydrogen and helium
	# from being used in planetary generation
	var h = randf_range(0.65,0.85)
	var he = 1.0 - h
	
	composition.push(PeriodicTable.elements[1], h)
	composition.push(PeriodicTable.elements[2], he)

func determine_name():
	# this is how we generate the star name, using the sector
	var sector = get_parent().sector
	obj_name = "%s Sector %s-%s" % [sector, floor(temperature/100), floor(mass*10)]

@onready var star_details: Control = $StarDetails
@onready var v_box_container: VBoxContainer = $StarDetails/Panel/VBoxContainer

func populate_star_details():
	# Star details labels
	var info_strings : Array[String] = [obj_name,
										"%s Class Star" % [StellarClass.keys()[stellar_class]], 
										"Age: %s Gyr" % [age],
										"Luminosity: %s L☉" % [luminosity],
										"Temperature: %s Kelvin" % [temperature],
										"Mass: %s Solar Masses" % [mass],
										"Radius: %s Solar Radii" % [solar_radii],
										"Mass: %s Earth Masses" % [mass],
										"Habitable Zone: between %s and %s AU" % [hz_inner_radius, hz_outer_radius],
										"Elemental Composition: %s" % [composition.human_readable()]]
	
	for i in info_strings:
		var x = Label.new()
		x.add_theme_font_size_override("font_size", 12)
		x.text = i
		v_box_container.add_child(x)

func _on_hover_detector_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	star_details.position = camera.unproject_position(event_position)

func _on_hover_detector_mouse_entered() -> void:
	star_details.show()

func _on_hover_detector_mouse_exited() -> void:
	star_details.hide()
