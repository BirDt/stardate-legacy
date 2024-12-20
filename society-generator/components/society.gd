extends Node
class_name Society

# generator seed data
@export var society_age : int = 20 # how many years since the colony ship arrived
@export var seed_population : int = 1500 # how many people were originall placed on the ship
@export var travel_time : int = 100

# generation ship data
@export var ship_name : String
@export var origin : OriginCategory
@export var ship_type : ShipCategory

enum OriginCategory {Safe, # ship arrived exactly as expected with no problems
					Catastrophic} # A catastrophic system failure forced the ship to divert

enum ShipCategory {IceShip, # Suspended Animation
					LiveShip} # Living biosphere

# initial population data
@export var initial_culture : Culture = preload("res://society-generator/resources/cultures/Western.tres")
var colonial_faction : Faction

var generated := false

@onready var generator_menu: Control = $GeneratorMenu
@onready var society_menu: Control = $SocietyMenu

var rng = RandomNumberGenerator.new()

# live society data
var infrastructure : int = 1 # How many discrete infrastructure items are there? Start with just 1 (the generation ship)
var population : int
var age_distribution
var cultures : Array[Culture] = []
var factions : Array[Faction]

func sum(arr:Dictionary):
		var result = 0
		for i in arr.keys():
			result+=arr[i]
		return result

func generate_society():
	WorldController.timescale_index = 0
	hide_menu()
	
	WorldController.tick = (0.00000190258752 * 60 * 4 * 8765) * society_age
	
	_generator_input_changed()
	var s = randi()
	if len(seed_input.text) > 0:
		s = seed_input.text.hash()
	rng.seed = s
	
	# calculates colonial faction and any initial sub factions
	determine_initial_ship_details()
	
	create_faction_uis()
	
	generated = true
	show_menu()
	WorldController.timescale_index = 1

func determine_initial_ship_details():
	var file = FileAccess.open("res://society-generator/resources/names/generation_ship.txt", FileAccess.READ)
	var possible_names = file.get_as_text().split("\n")
	ship_name = "The " + possible_names[rng.randi_range(0, len(possible_names)-1)]
	
	cultures.append(initial_culture)
	
	colonial_faction = Faction.new()
	colonial_faction.society = self
	colonial_faction.population = seed_population
	colonial_faction.cultures[initial_culture] = 1.0
	colonial_faction.faction_influence = 1.0
	colonial_faction.leadership_values = initial_culture.create_random_deviation(rng, 0.1)
	
	var twenties = rng.randf_range(0.5, 1.0)
	var thirties = rng.randf_range(0.0, 1.0-twenties)
	var fourties = rng.randf_range(0.0, 1.0-twenties-thirties)
	var fifties = rng.randf_range(0.0, 1.0-twenties-thirties-fourties) 
	var teens = rng.randf_range(0.0, 1.0-twenties-thirties-fourties-fifties)
	
	colonial_faction.age_distribution = [
		0,
		teens,
		twenties,
		thirties,
		fourties,
		fifties,
		0,
		0,
		0,
		0]
	
	if origin_culture.selected == 1:
		var p_govt = [Faction.GovernmentType.Authoritarian, Faction.GovernmentType.Totalitarian, Faction.GovernmentType.Dictatorship, Faction.GovernmentType.Oligarchy, Faction.GovernmentType.Communist]
		colonial_faction.government_type = p_govt[rng.randi_range(0, len(p_govt)-1)]
	else:
		var p_govt = [Faction.GovernmentType.Coporation, Faction.GovernmentType.DirectDemocracy, Faction.GovernmentType.RepresentativeDemocracy, Faction.GovernmentType.Oligarchy, Faction.GovernmentType.Technocracy]
		colonial_faction.government_type = p_govt[rng.randi_range(0, len(p_govt)-1)]
	
	colonial_faction.faction_name = "Colonial Government of %s" % ship_name
	
	print(colonial_faction.faction_name, " is (a) ", Faction.GovernmentType.keys()[colonial_faction.government_type])
	
	factions.append(colonial_faction)
	
	# generate any initial splinter factions
	var splinter_chance = rng.randf_range(0.7, 1.0)
	var splinter_roll = rng.randf()
	print("Rolled ", splinter_roll, " against ", splinter_chance)
	while splinter_roll < splinter_chance and colonial_faction.population > 0.5 * seed_population:
		var splinter_values = initial_culture.create_random_deviation(rng, 0.3)
		var splinter_faction = Faction.new()
		splinter_faction.society = self
		splinter_faction.cultures[initial_culture] = 1.0
		splinter_faction.faction_influence = 0.0
		splinter_faction.government_type = Faction.GovernmentType.values()[rng.randi_range(0, len(Faction.GovernmentType.values()) - 1)]
		splinter_faction.leadership_values = splinter_values
		
		splinter_faction.generate_name(rng, ship_name)
		
		print(splinter_faction.faction_name, " is (a) ", Faction.GovernmentType.keys()[splinter_faction.government_type])
		
		colonial_faction.faction_relations[splinter_faction] = Faction.Relation.values()[clamp(rng.randfn(3.0, 0.01), 0, 6)] # this is wrong, neutral is not zero
		splinter_faction.faction_relations[colonial_faction] = Faction.Relation.values()[rng.randi_range(0, len(Faction.Relation.values())-1)]
		
		colonial_faction.faction_relative_status[splinter_faction] = [Faction.RelativeStatus.Dominant, Faction.RelativeStatus.Apathetic][rng.randi_range(0, 1)]
		if splinter_faction.faction_relations[colonial_faction] == Faction.Relation.Hostile:
			splinter_faction.faction_relative_status[colonial_faction] = Faction.RelativeStatus.Rebellious
		elif splinter_faction.faction_relations[colonial_faction] == Faction.Relation.Integrated:
			splinter_faction.faction_relative_status[colonial_faction] = Faction.RelativeStatus.Subservient
		else:
			splinter_faction.faction_relative_status[colonial_faction] = Faction.RelativeStatus.Apathetic
		
		print("%s is %s to %s, %s is %s to %s" % [colonial_faction.faction_name, Faction.Relation.keys()[colonial_faction.faction_relations[splinter_faction]], splinter_faction.faction_name, splinter_faction.faction_name, Faction.Relation.keys()[splinter_faction.faction_relations[colonial_faction]], colonial_faction.faction_name])
		print("%s is %s to %s, %s is %s to %s" % [colonial_faction.faction_name, Faction.RelativeStatus.keys()[colonial_faction.faction_relative_status[splinter_faction]], splinter_faction.faction_name, splinter_faction.faction_name, Faction.RelativeStatus.keys()[splinter_faction.faction_relative_status[colonial_faction]], colonial_faction.faction_name])
		colonial_faction.sub_factions.append(splinter_faction)
		splinter_faction.parent_faction = colonial_faction
		factions.append(splinter_faction)
		
		splinter_chance /= len(colonial_faction.sub_factions)*rng.randf_range(1, 2)
		
		# determine age distribution for each splinter and update colonial faction
		var colonial_real_population = []
		var splinter_real_population = []
		for i in len(colonial_faction.age_distribution):
			colonial_real_population.append(floor(colonial_faction.age_distribution[i]*colonial_faction.population))
		for i in len(colonial_real_population):
			splinter_real_population.append(clamp(floor(randi_range(0, 0.25 * colonial_real_population[i])), 0, INF))
			colonial_real_population[i] -= splinter_real_population[i]
		
		splinter_faction.population = splinter_real_population.reduce(func (a, b): return a+b, 0)
		colonial_faction.population = colonial_real_population.reduce(func (a, b): return a+b, 0)
		
		for i in len(colonial_real_population):
			colonial_faction.age_distribution[i] = colonial_real_population[i]/float(colonial_faction.population)
		for i in len(splinter_real_population):
			splinter_faction.age_distribution[i] = splinter_real_population[i]/float(splinter_faction.population)
	
	for i in factions:
		i.new_focus(rng, true)
		print(i.faction_name + " starting with focus " + Faction.Focus.keys()[i.faction_focus])

func show_menu():
	if generated:
		society_menu.show()
	else:
		generator_menu.show()

func hide_menu():
	generator_menu.hide()
	society_menu.hide()

@onready var factions_box: VBoxContainer = $SocietyMenu/Panel/MarginContainer/VBoxContainer/ScrollContainer/FactionsBox
const FACTION_CONTAINER = preload("res://society-generator/components/faction_container.tscn")

func create_faction_uis():
	for i in factions_box.get_children():
		i.queue_free()

	for i in factions:
		var f = FACTION_CONTAINER.instantiate()
		f.faction = i
		factions_box.add_child(f)
		var s = HSeparator.new()
		factions_box.add_child(s)

@onready var age_input: SpinBox = $GeneratorMenu/Panel/MarginContainer/VBoxContainer/HBoxContainer/AgeInput
@onready var seed_pop_input: SpinBox = $GeneratorMenu/Panel/MarginContainer/VBoxContainer/HBoxContainer2/SeedPopInput
@onready var travel_time_input: SpinBox = $GeneratorMenu/Panel/MarginContainer/VBoxContainer/HBoxContainer5/TravelTimeInput
@onready var ship_type_input: OptionButton = $GeneratorMenu/Panel/MarginContainer/VBoxContainer/HBoxContainer3/ShipType
@onready var society_origin: OptionButton = $GeneratorMenu/Panel/MarginContainer/VBoxContainer/HBoxContainer4/SocietyOrigin
@onready var seed_input: LineEdit = $GeneratorMenu/Panel/MarginContainer/VBoxContainer/SeedInput
@onready var origin_culture: OptionButton = $GeneratorMenu/Panel/MarginContainer/VBoxContainer/HBoxContainer6/OriginCulture

func _generator_input_changed() -> void:
	society_age = age_input.value
	seed_population = seed_pop_input.value
	travel_time = travel_time_input.value
	ship_type = ShipCategory.values()[ship_type_input.selected]
	origin = OriginCategory.values()[society_origin.selected]
	match origin_culture.selected:
		0:
			initial_culture = preload("res://society-generator/resources/cultures/Western.tres")
		_:
			initial_culture = preload("res://society-generator/resources/cultures/Soviet.tres")
