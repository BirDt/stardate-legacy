extends Resource
class_name Culture

@export var power_distance : float = 0.0 # -1.0: distributed power, 1.0: doubtless heirarchy
@export var individualism : float = 0.0 # -1.0: collectivist, 1.0: individualist
@export var achievement_motivation : float = 0.0 # -1.0: preference for cooperation, modesty, caring for the weak, and quality of life,
										# 1.0: preference in society for achievement, heroism, assertiveness, and material rewards for success
@export var uncertainty_avoidance : float = 0.0 # -1.0: fewer rules, more acceptance of ideas, 1.0: stiff codes, absolute truth
@export var long_term_orientation : float = 0.0 # -1.0: little adaptation, traditional, 1.0: pragmatic, adaptive
@export var indulgence : float = 0.0 # -1.0: restricts gratification, 1.0: free gratification
@export var communication_style : float = 0.0 # -1.0: indirect communication, 1.0: direct communication
@export var time_orientation : float = 0.0 # -1.0: polychronic, 1.0: monochronic
@export var trust : float = 0.0 # -1.0: cognitive trust (built on competency and reliability), 1.0: affective trust (interpersonal relationships)
@export var life_value : float = 0.0 # -1.0: human life is expendable for societal benefit, 1.0: human life is sacred
@export var risk_aversion : float = 0.0 # -1.0: value stability and security, 1.0: value innovation and entrepeneurship
@export var privacy : float = 0.0 # -1.0: transparency with personal details, 1.0: expect privacy about personal dealings
@export var work_ethic : float = 0.0 # -1.0: lazy, 1.0: hard-working
@export var environmental_orientation : float = 0.0 # -1.0: sustainability, 1.0: exploitation
@export var ethical_orientation : float = 0.0 # -1.0: consequentialist, 1.0: deontological
@export var cultural_patience : float = 0.0 # -1.0: impatient (better to receive little now than receive more later), 1.0: patient

@export var culture_name : String

var deviation : float = 0.0 # deviation from whatever the values of the culture originally were. At 1.0, we should consider it it's own culture
@export var origin : Culture # a reference to this cultures original starting values

enum Scale {POWER, INDIV, MOTIVE, UNC, LTO, INDUL, COMM, TIME, TRUST, LIFE, RISK, PRIV, WORK, ENV, ETHICS, PAT}

var cultural_relations : Dictionary = {}
enum Relation {Hostile, Dislike, Distrust, Neutral, Trust, Like, Integrated}

func get_scale(s : Scale):
	return [power_distance, individualism, achievement_motivation, uncertainty_avoidance, long_term_orientation, indulgence, communication_style, time_orientation,
			trust, life_value, risk_aversion, privacy, work_ethic, environmental_orientation, ethical_orientation, cultural_patience][s]

func create_random_deviation(rng: RandomNumberGenerator, weight: float) -> Culture:
	var new_culture = Culture.new()
	new_culture.power_distance = clampf(rng.randfn(power_distance, weight), -1.0, 1.0)
	new_culture.individualism = clampf(rng.randfn(individualism, weight), -1.0, 1.0)
	new_culture.achievement_motivation = clampf(rng.randfn(achievement_motivation, weight), -1.0, 1.0)
	new_culture.uncertainty_avoidance = clampf(rng.randfn(uncertainty_avoidance, weight), -1.0, 1.0)
	new_culture.long_term_orientation = clampf(rng.randfn(long_term_orientation, weight), -1.0, 1.0)
	new_culture.indulgence = clampf(rng.randfn(indulgence, weight), -1.0, 1.0)
	new_culture.communication_style = clampf(rng.randfn(communication_style, weight), -1.0, 1.0)
	new_culture.time_orientation = clampf(rng.randfn(time_orientation, weight), -1.0, 1.0)
	new_culture.trust = clampf(rng.randfn(trust, weight), -1.0, 1.0)
	new_culture.life_value = clampf(rng.randfn(life_value, weight), -1.0, 1.0)
	new_culture.risk_aversion = clampf(rng.randfn(risk_aversion, weight), -1.0, 1.0)
	new_culture.privacy = clampf(rng.randfn(privacy, weight), -1.0, 1.0)
	new_culture.work_ethic = clampf(rng.randfn(work_ethic, weight), -1.0, 1.0)
	new_culture.environmental_orientation = clampf(rng.randfn(environmental_orientation, weight), -1.0, 1.0)
	new_culture.ethical_orientation = clampf(rng.randfn(ethical_orientation, weight), -1.0, 1.0)
	new_culture.cultural_patience = clampf(rng.randfn(cultural_patience, weight), -1.0, 1.0)
	new_culture.origin = self
	new_culture.deviation = abs(new_culture.power_distance - power_distance) + abs(new_culture.individualism - individualism) + abs(new_culture.achievement_motivation - achievement_motivation) + abs(new_culture.uncertainty_avoidance - uncertainty_avoidance) +\
							abs(new_culture.long_term_orientation - long_term_orientation) + abs(new_culture.indulgence - indulgence) + abs(new_culture.communication_style - communication_style) + abs(new_culture.time_orientation - time_orientation) +\
							abs(new_culture.trust - trust) + abs(new_culture.life_value - life_value) + abs(new_culture.risk_aversion - risk_aversion) + abs(new_culture.privacy - privacy) + abs(new_culture.work_ethic - work_ethic) + abs(new_culture.environmental_orientation - environmental_orientation) +\
							abs(new_culture.ethical_orientation - ethical_orientation) + abs(new_culture.cultural_patience - cultural_patience)    
	return new_culture
