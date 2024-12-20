extends Object
class_name Utils

static func pick_weighted(dictionary : Dictionary, rng: RandomNumberGenerator):
	var sum_weights = 0
	for i in dictionary.keys():
		sum_weights += dictionary[i]
	
	var rnd = rng.randi_range(0, sum_weights - 1)
	
	for i in dictionary.keys():
		if rnd < dictionary[i]:
			return i
		rnd -= dictionary[i]
