extends CSGPolygon3D

var inner_radius : float
var outer_radius : float

var mass : float

var distinct_rings : int
var ring_compositions : Array[ElementalCompositionDigest]

enum RingType {Dusty, Rocky}
var ring_types : Array[RingType]

var parent : Planetoid

func _ready() -> void:
	parent = get_parent()
	var r = parent.mesh.radius * 0.009157 * Star.SOLAR_RADIUS
	mass = randf_range(0.000001, 0.05)
	var hyp_roche = (2.44 * (r) * pow(mass/randf_range(600,2000), 1.0/3.0)) / 1.495979
	inner_radius = randf_range(hyp_roche, 0.05)
	outer_radius = randf_range(inner_radius, 0.1)
	
	distinct_rings = floor(randfn(4, 3))
	distinct_rings = clamp(distinct_rings, 1, distinct_rings+1)
	
	material.albedo_texture.height = 1 if distinct_rings == 1 else 100 * (distinct_rings - 1)
	
	$HoverDetector/CollisionShape3D.shape.radius = outer_radius * 500
	
	polygon[0].x = inner_radius * 500
	polygon[1].x = inner_radius * 500
	polygon[2].x = outer_radius * 500
	polygon[3].x = outer_radius * 500
	
	determine_ring_compositions()
	
	populate_ring_details()

func determine_ring_compositions():
	for i in range(distinct_rings):
		ring_types.append(RingType.Dusty)
		ring_compositions.append(ElementalCompositionDigest.new())
		
	for i in range(distinct_rings):
		ring_types[i] = RingType.Dusty if randf() < 0.65 else RingType.Rocky
		
		var possible_composition_elements = PeriodicTable.elements.values()
		var abundance = parent.system.remaining_elemental_mass.composition
		
		# filter natural
		possible_composition_elements = possible_composition_elements.map(func (x: Element): return null if not x or not x.natural else x)
		
		var possible_abundance = []
	
		for j in abundance:
			if j.element in possible_composition_elements:
				possible_abundance.push_back(j)
		
		var comp_length = randf_range(0, 10)
		var initial_comp = randf_range(0.0, 1.0)
		while len(possible_abundance) > comp_length:
			possible_abundance.sort_custom(func (x, y): return x.percent > y.percent)
			var s
			s = possible_abundance.slice(0, 5)
			s.shuffle()
			var e = s[0]
			possible_abundance.erase(e)
			if len(ring_compositions[i].composition) == 0:
				ring_compositions[i].push(e.element, initial_comp)
			else:
				ring_compositions[i].push(e.element, randf_range(0, 1.0 - ring_compositions[i].sum_total()))

@onready var ring_details: Control = $RingDetails
@onready var v_box_container: VBoxContainer = $RingDetails/Panel/VBoxContainer

func populate_ring_details():
	var info_strings : Array[String] = ["Mass: %s Earth Masses" % [mass],
										"System Inner Radius: %s AU" % [inner_radius],
										"System Outer Radius: %s AU" % [outer_radius],
										"Distinct Rings: %s" % [distinct_rings],
										"Ring Details:"]
	
	for i in range(distinct_rings):
		info_strings.push_back("Ring %s: %s Ring, with composition of %s" % [i+1, RingType.keys()[ring_types[i]], ring_compositions[i].human_readable()])
	
	for i in info_strings:
		var x = Label.new()
		x.add_theme_font_size_override("font_size", 12)
		x.text = i
		v_box_container.add_child(x)

func _on_hover_detector_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not WorldController.detail_view:
		ring_details.position = camera.unproject_position(event_position)

func _on_hover_detector_mouse_entered() -> void:
	if not WorldController.detail_view:
		ring_details.show()

func _on_hover_detector_mouse_exited() -> void:
	ring_details.hide()
