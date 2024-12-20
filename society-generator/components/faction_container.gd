extends VBoxContainer

@export var faction : Faction

@onready var faction_name: Label = $HBoxContainer/FactionName
@onready var population: Label = $HBoxContainer/Population
@onready var focus: Label = $HBoxContainer2/Focus
@onready var govt_type: Label = $HBoxContainer2/GovtType

func _physics_process(delta: float) -> void:
	faction_name.text = faction.faction_name
	population.text = "Population: " + str(faction.population)
	focus.text = "Current Focus: " + Faction.Focus.keys()[faction.faction_focus]
	govt_type.text = "Govt. Type: " + Faction.GovernmentType.keys()[faction.government_type]
