extends Resource
class_name Faction

var faction_name : String

var population : int
var cultures : Dictionary = {} # per culture, and the percent of the population it takes up
var culture_approval : Dictionary = {} # per culture, and how much it approves of the faction
var age_distribution : Array[float] = [0,0,0,0,0,0,0,0,0,0]# per interval of 20 years, percent of population
var sub_factions : Array[Faction] # Factions within this faction
var parent_faction : Faction # What is this a sub-faction of

var leadership_values : Culture
var government_type : GovernmentType
enum GovernmentType {None, Coporation, DirectDemocracy, RepresentativeDemocracy, Authoritarian, Totalitarian, Oligarchy, Technocracy, Theocracy, Dictatorship, Monarchy, Communist}

var faction_relations : Dictionary = {} # per faction, be it sub-faction or competitor
enum Relation {Hostile, Dislike, Distrust, Neutral, Trust, Like, Integrated}
var faction_relative_status : Dictionary = {} # per faction, be it sub-faction or competitor
enum RelativeStatus {Subservient, Rebellious, Dominant, Apathetic, Competitive}

var faction_influence : float # Relative influence of this faction. Unlimited, essentially just a powerlevel
var faction_focus : Focus
enum Focus {Economy, Health, Education, Justice, Development, Innovation, Defense, Freedom, Population, Subjugation, Culture, Corruption, Discovery, Sabotage, Conflict, Influence, Diplomacy}

var society : Society

func get_overall_approval():
	var sum = 0.0
	for i in culture_approval.values():
		sum += i
	return sum/len(culture_approval)

func new_focus(rng: RandomNumberGenerator, on_ship: bool):
	if faction_focus != null:
		complete_initiative()
	
	var focus_weights = {Focus.Economy: 0, Focus.Health: 0, Focus.Education: 0, Focus.Justice: 0, Focus.Development: 0, Focus.Innovation: 0, Focus.Defense: 0, Focus.Freedom: 0, Focus.Population: 0, Focus.Subjugation: 0, Focus.Culture: 0, Focus.Corruption: 0, Focus.Discovery: 0, Focus.Sabotage: 0, Focus.Conflict: 0, Focus.Influence: 0}
	
	focus_weights[Focus.Economy] += (leadership_values.get_scale(Culture.Scale.WORK)+1.0) * 2.5
	focus_weights[Focus.Economy] += (leadership_values.get_scale(Culture.Scale.MOTIVE)+1.0) * 2.5
	focus_weights[Focus.Health] += (leadership_values.get_scale(Culture.Scale.LIFE)+1.0) * 5
	focus_weights[Focus.Corruption] += (leadership_values.get_scale(Culture.Scale.POWER)+1.0) * 5
	focus_weights[Focus.Education] += (leadership_values.get_scale(Culture.Scale.MOTIVE)+1.0) * 5
	focus_weights[Focus.Justice] += (leadership_values.get_scale(Culture.Scale.UNC)+1.0) * 2.5
	focus_weights[Focus.Justice] -= (leadership_values.get_scale(Culture.Scale.INDUL)+1.0) * 2.5
	focus_weights[Focus.Development] += (leadership_values.get_scale(Culture.Scale.LTO)+1.0) * 5
	focus_weights[Focus.Innovation] += (leadership_values.get_scale(Culture.Scale.PAT)+1.0) * 2.5
	focus_weights[Focus.Innovation] += (leadership_values.get_scale(Culture.Scale.RISK)+1.0) * 2.5
	focus_weights[Focus.Defense] += (leadership_values.get_scale(Culture.Scale.INDIV)+1.0) * 1.5
	focus_weights[Focus.Freedom] += (leadership_values.get_scale(Culture.Scale.INDIV)+1.0) * 2.5
	focus_weights[Focus.Freedom] += (leadership_values.get_scale(Culture.Scale.INDUL)+1.0) * 2.5
	focus_weights[Focus.Population] += (leadership_values.get_scale(Culture.Scale.LIFE)+1.0) * 2.5
	focus_weights[Focus.Population] += (leadership_values.get_scale(Culture.Scale.LTO)+1.0) * 2.5
	focus_weights[Focus.Culture] += (leadership_values.get_scale(Culture.Scale.POWER)*-1.0+1.0) * 5
	focus_weights[Focus.Discovery] += (leadership_values.get_scale(Culture.Scale.RISK)+1.0) * 5
	
	if faction_focus == Focus.Corruption:
		focus_weights[Focus.Corruption] *= 3
	
	match government_type:
		GovernmentType.Coporation:
			focus_weights[Focus.Economy] *= 2
			focus_weights[Focus.Innovation] *= leadership_values.get_scale(Culture.Scale.RISK)+1.0
			focus_weights[Focus.Development] *= (leadership_values.get_scale(Culture.Scale.LTO)+1.0)
			focus_weights[Focus.Population] *= (-1*leadership_values.get_scale(Culture.Scale.LIFE)+1.0)
			focus_weights[Focus.Education] *= (1 - get_overall_approval()) * 10
		GovernmentType.Oligarchy:
			focus_weights[Focus.Corruption] *= 2
			focus_weights[Focus.Defense] *= (len(sub_factions)/5)+1
			focus_weights[Focus.Justice] *= (1 - get_overall_approval()) * 10
			focus_weights[Focus.Culture] += leadership_values.deviation * 2
		GovernmentType.DirectDemocracy:
			pass
		GovernmentType.RepresentativeDemocracy:
			focus_weights[faction_focus] /= 3.0
		GovernmentType.Authoritarian:
			focus_weights[Focus.Defense] *= 2
			focus_weights[Focus.Justice] *= 2 
			focus_weights[Focus.Population] *= (leadership_values.get_scale(Culture.Scale.LIFE)+1.0)
		GovernmentType.Totalitarian:
			focus_weights[Focus.Corruption] *= 2 * (leadership_values.get_scale(Culture.Scale.INDUL))
			focus_weights[Focus.Defense] *= 2
			focus_weights[Focus.Education] /= 2 
			focus_weights[Focus.Population] *= (leadership_values.get_scale(Culture.Scale.LIFE)+1.0)
			focus_weights[Focus.Freedom] /= 3
		GovernmentType.Technocracy:
			focus_weights[Focus.Economy] *= (leadership_values.get_scale(Culture.Scale.WORK)+1.0)
			focus_weights[Focus.Development] *= (leadership_values.get_scale(Culture.Scale.LTO)+1.0)
			focus_weights[Focus.Innovation] *= (leadership_values.get_scale(Culture.Scale.PAT)+1.0)
		GovernmentType.Theocracy:
			focus_weights[Focus.Development] *= (leadership_values.get_scale(Culture.Scale.POWER)+1.0)
			focus_weights[Focus.Culture] *= (-1*leadership_values.get_scale(Culture.Scale.INDUL)+1.0)
		GovernmentType.Dictatorship:
			focus_weights[Focus.Defense] *= 2
			focus_weights[Focus.Corruption] *= 2 
			focus_weights[Focus.Culture] *= (-1*leadership_values.get_scale(Culture.Scale.INDUL)+1.0)
		GovernmentType.Monarchy:
			focus_weights[Focus.Economy] *= (leadership_values.get_scale(Culture.Scale.MOTIVE)+1.0)
			focus_weights[Focus.Development] *= (leadership_values.get_scale(Culture.Scale.PAT)+1.0)
		GovernmentType.Communist:
			focus_weights[Focus.Freedom] *= (-1*leadership_values.get_scale(Culture.Scale.POWER)+1.0)
			focus_weights[Focus.Population] *= (leadership_values.get_scale(Culture.Scale.LTO)+1.0)
	
	if len(society.factions) > 1:
		var conflict_weight = 1.0
		var diplomacy_weight = 1.0
		for i in society.factions:
			if i in faction_relative_status.keys() and faction_relative_status[i] == RelativeStatus.Competitive:
				conflict_weight = 10 if faction_relations[i] == Relation.Hostile else 5 if faction_relations[i] == Relation.Dislike else 1 if faction_relations[i] == Relation.Distrust else 0
				diplomacy_weight = 10 if faction_relations[i] == Relation.Integrated else 5 if faction_relations[i] == Relation.Like else 1 if faction_relations[i] == Relation.Trust else 0
				if i.faction_influence > faction_influence:
					focus_weights[Focus.Influence] += 1
		focus_weights[Focus.Conflict] = conflict_weight * (-1*leadership_values.get_scale(Culture.Scale.PAT)+1.0)
		focus_weights[Focus.Diplomacy] = diplomacy_weight * (leadership_values.get_scale(Culture.Scale.PAT)+1.0)
	
	if parent_faction:
		if faction_relative_status[parent_faction] == RelativeStatus.Rebellious:
			focus_weights[Focus.Freedom] *= (leadership_values.get_scale(Culture.Scale.INDIV)+1.0)
			focus_weights[Focus.Sabotage] = 2 * (leadership_values.get_scale(Culture.Scale.RISK)+1.0)
		if faction_relative_status[parent_faction] == RelativeStatus.Subservient:
			focus_weights[Focus.Diplomacy] *= (leadership_values.get_scale(Culture.Scale.TRUST)+1.0) 

	for i in sub_factions:
		if faction_relative_status[i] == RelativeStatus.Dominant:
			focus_weights[Focus.Justice] *= (leadership_values.get_scale(Culture.Scale.POWER)+1.0) 
			focus_weights[Focus.Subjugation] += 2 * (leadership_values.get_scale(Culture.Scale.POWER)+1.0) 
	
	if on_ship:
		focus_weights[Focus.Development] = 0
		focus_weights[Focus.Population] /= 2
		focus_weights[Focus.Discovery] = 0
	faction_focus = Utils.pick_weighted(focus_weights, rng)

func complete_initiative():
	pass

func tick(rng: RandomNumberGenerator, on_ship = false):
	# calculate_approval()
	new_focus(rng, on_ship)

# this should really take leadership values into account
func generate_name(rng: RandomNumberGenerator, origin_location_name : String):
	var possible_prefixes = []
	var possible_suffixes = []
	if government_type == GovernmentType.None:
		possible_prefixes.append_array(["Gang of", "Brutes of", "Anarchs of", "The Lawless of", ])
		possible_suffixes.append_array(["Vagabonds", "Thieves", "Anarchs", "Free-men", "Posse", "Gang", "Syndicate"])
	if government_type == GovernmentType.Coporation:
		possible_suffixes.append_array(["Inc.", "Co.", "Enterprises", "Ltd.", "Cooperative", "Business Systems"])
	if government_type == GovernmentType.Oligarchy:
		possible_prefixes.append_array(["The Rightful Owners of", "Keepers of"])
		possible_suffixes.append_array(["Assembly", "Council"])
	if government_type == GovernmentType.DirectDemocracy or government_type == GovernmentType.RepresentativeDemocracy:
		possible_prefixes.append_array(["Constituents of", "Party of"])
		possible_suffixes.append_array(["Party", "House"])
	if government_type == GovernmentType.Authoritarian or government_type == GovernmentType.Totalitarian or government_type == GovernmentType.Dictatorship or government_type == GovernmentType.Communist:
		possible_prefixes.append_array(["Democratic Party of"])
		possible_suffixes.append_array(["Regime"])
	if government_type == GovernmentType.Communist:
		possible_suffixes.append_array(["Commune"])
	if government_type == GovernmentType.Theocracy or government_type == GovernmentType.Monarchy:
		possible_prefixes.append_array(["Cult of", "Kingdom of"])
		possible_suffixes.append_array(["High Council", "The Venerable"])
	if government_type == GovernmentType.Technocracy:
		possible_suffixes.append_array(["General Assembly", "Cohort"])
	
	var middle : String
	if rng.randf() < 0.3:
		middle = origin_location_name
	else:
		var file = FileAccess.open("res://society-generator/resources/names/factions.txt", FileAccess.READ)
		var m = MarkovMachine.new(file.get_as_text())
		middle = m.generate_new().capitalize()
	
	var should_pick_suffix = rng.randf() < 0.5
	if not should_pick_suffix and len(possible_prefixes) > 0:
		faction_name = "%s %s" % [possible_prefixes[rng.randi_range(0, len(possible_prefixes)-1)], middle]
	if should_pick_suffix and len(possible_suffixes) > 0:
		faction_name = "%s%s %s" % ["The " if rng.randf() < 0.5 and not middle.begins_with("The") else "",middle, possible_suffixes[rng.randi_range(0, len(possible_suffixes)-1)]]
	else:
		faction_name = middle
