extends Resource
class_name ElementalCompositionDigest

class CompositionPair:
	@export var element : Element
	@export var percent : float

var composition : Array[CompositionPair]

func push(x: Element, p: float):
	var c = CompositionPair.new()
	c.element = x
	c.percent = abs(p)
	composition.push_back(c)

func find(x: int):
	for i in composition:
		if i.element.atomic_number == x:
			return i.percent

func modify(x: int, p: float):
	for i in len(composition):
		if composition[i].element.atomic_number == x:
			composition[i].percent = p

func sum_total():
	var r = 0.0
	for i in composition:
		r += i.percent
	return r

func human_readable() -> String:
	var to_show = composition
	to_show.sort_custom(func (x : CompositionPair, y : CompositionPair): return x.percent > y.percent)
	to_show = to_show.slice(0, 6)
	
	var display_strings : Array[String] = []
	for i in to_show:
		display_strings.push_back("%s: %.2f%%" % [i.element.symbol, i.percent*100])
	return ", ".join(display_strings)

func human_readable_mass() -> String:
	var to_show = composition
	to_show.sort_custom(func (x : CompositionPair, y : CompositionPair): return x.percent > y.percent)
	to_show = to_show.slice(0, 6)
	
	var display_strings : Array[String] = []
	for i in to_show:
		display_strings.push_back("%s: %.2f Solar Masses" % [i.element.symbol, i.percent])
	return ", ".join(display_strings)
