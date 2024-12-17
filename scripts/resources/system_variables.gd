extends Resource
class_name SystemVariables

@export var mass := 0.0 # system mass in Solar Masses
@export var abundance : Dictionary = {}

@export var system_age := 0.0 #Gyr

func sum(arr:Dictionary):
		var result = 0
		for i in arr.keys():
			result+=arr[i]
		return result

func _init() -> void:
	#80% of the time, we generate a relatively normal habitable system
	#20% of the time, we let the rng gods go wild
	if randf() < 0.80:
		system_age = clamp(randfn(5, 1), 1, 13)
		mass = clamp(randfn(1.1, 0.5), 0.5, 20)
	else:
		system_age = randf_range(1, 13)
		mass = randf_range(0.5, 20)
	
	# Setting abundances
	# This isn't perfect, but it's good enough
	for i in PeriodicTable.elements.keys():
		abundance[i] = 0.0
	
	# https://en.wikipedia.org/wiki/Abundance_of_the_chemical_elements#Universe
	var ppm = 1000000.0
	abundance[1] = clamp(randfn(719000.0/ppm, 0.05), 0.7, 0.9)
	abundance[2] = clamp(randfn(220000.0/ppm, 0.05), 0.2, 0.25)
	abundance[8] = randfn(10400.0/ppm, 0.005)
	abundance[6] = randfn(4600.0/ppm, 0.0005)
	abundance[10] = randfn(1340.0/ppm, 0.0005)
	abundance[26] = randfn(1090.0/ppm, 0.0005)
	abundance[7] = randfn(960.0/ppm, 0.00005)
	abundance[14] = randfn(650.0/ppm, 0.00005)
	abundance[12] = randfn(580.0/ppm, 0.00005)
	abundance[16] = randfn(440.0/ppm, 0.00005)
	
	# Everything else is randomised, just for fun
	# this isn't particularly realistic, but it can make for some funny results
	var s = abundance.keys()
	s.shuffle()
	for i in s:
		if abundance[i] == 0 and PeriodicTable.elements[i].natural:
			abundance[i] = randf_range(0, 1.0-sum(abundance)) * ((i/98) if randf() < 0.8 else 1)
			if abundance[1] < 0:
				abundance[i] = 0.0
	
	# Keep the sum of abundance at 100%
	if sum(abundance) > 1.0:
		var diff = sum(abundance) - 1.0
		abundance[1] -= diff/2
		abundance[2] -= diff/2
	
	print("Total element abundance: ", sum(abundance))
	print("Printing abundances...")
	for i in abundance.keys():
		print(PeriodicTable.elements[i].name, ": ", abundance[i] * 100, "%")

	print("Generated new system")
	print("System mass: ", mass, " Solar Masses")
	print("System metallicity: ", (1.0 - abundance[1] - abundance[2]) * 100, "%")
	print("System age: ", system_age, " Gyr")
