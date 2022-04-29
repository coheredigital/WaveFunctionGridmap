# A little test combining Martin Donald's work with WFC with Godots Gridmap
tool
extends GridMap

export var size : Vector3 = Vector3(8.0,3.0,8.0)
export var prototype_data : Resource
export var initialize_cells : bool setget set_initialize
export var generate_step : bool setget set_generate_step
#export var generate_map : bool setget set_generate_map
export var prototypes := {}


export var wave_function : Array  # Grid of cells containing prototypes
export var cell_states := {}
export var stack : Array
export var bounds : AABB


var siblings_offsets = {
	Vector3.FORWARD : 'forward',
	Vector3.RIGHT : 'right',
	Vector3.BACK : 'back',
	Vector3.LEFT : 'left',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down',
}


# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()

func set_generate_step(value):
	iterate()

#func set_generate_map(value):
#	generate()

func generate():
	initialize()
	seed(OS.get_unix_time())
	while not is_collapsed():
		iterate()
		yield(get_tree(), "idle_frame")


func set_initialize(value):
	initialize()


func initialize():
	prototypes = prototype_data.prototypes.duplicate()
	clear() #clear the gridmap
	wave_function = []
	bounds = AABB(Vector3.ZERO, size - Vector3(1.0,1.0,1.0))
	for _z in range(size.z):
		var y = []
		for _y in range(size.y):
			var x = []
			for _x in range(size.x):
				x.append(prototypes.duplicate())
#				track each unique cell state
				cell_states[Vector3(_x,_y,_z)] = prototypes.duplicate()
			y.append(x)
		wave_function.append(y)
	print_debug('cells intialized: %s' % cell_states.size())
	prototype_data.wave_function = wave_function


func is_collapsed() -> bool:
	return cell_states.size() == 0


func iterate():
	var coords = get_min_entropy_coords()
	print_debug("Iterate cell: %s" % coords)
	assert( coords != Vector3.INF, 'Invalid coords returned from get_min_entropy_coords.')
	collapse_at(coords)
	propagate(coords)


func collapse_at(coords : Vector3):

	var possible_prototypes = wave_function[coords.z][coords.y][coords.x]
	var selection = weighted_choice(possible_prototypes)

	var prototype = possible_prototypes[selection]

	possible_prototypes = {selection : prototype}
	wave_function[coords.z][coords.y][coords.x] = possible_prototypes
	cell_states.erase(coords)
#	apply cell
	print('collapsed coord: %s' % coords)
	set_cell_item(coords.x,coords.y,coords.z,prototype.cell_index,prototype.cell_orientation)


func weighted_choice(prototypes):
	var proto_weights = {}
	for p in prototypes:
		var w = prototypes[p]['count']
		w += rand_range(-1.0, 1.0)
		proto_weights[w] = p
	var weight_list = proto_weights.keys()
	weight_list.sort()
	return proto_weights[weight_list[-1]]


func get_min_entropy_coords() -> Vector3:
	var min_entropy := 1000.0
	var coords := Vector3.INF
	for cell_coords in cell_states:
		var entropy = get_entropy(cell_coords)
		if entropy > 1:
			entropy += rand_range(-0.1, 0.1)
			if entropy < min_entropy:
				min_entropy = entropy
				coords = cell_coords
	return coords


func get_entropy(coords : Vector3):
	var available_prototypes = wave_function[coords.z][coords.y][coords.x]
	var entropy = len(available_prototypes)
	return entropy


func propagate(co_ords):
	if co_ords:
		stack.append(co_ords)
	while len(stack) > 0:
		var cur_coords = stack.pop_back()
		var sibling_offsets := get_siblings_offsets(cur_coords)

		for offset in sibling_offsets:
			var sibling_coords = cur_coords + offset
			var possible_siblings = get_possible_siblings(cur_coords, offset)
			var sibling_possible_prototypes = get_possibilities(sibling_coords).duplicate()

			if len(sibling_possible_prototypes) == 0:
				continue

			for sibling_possible_prototype in sibling_possible_prototypes:
				if not possible_siblings.has(sibling_possible_prototype):
					constrain(sibling_coords, sibling_possible_prototype)
					if not sibling_coords in stack:
						stack.append(sibling_coords)


func constrain(coords : Vector3, cell_name : String):
	wave_function[coords.z][coords.y][coords.x].erase(cell_name)


func get_siblings_offsets(coords) -> Array:
	var x = coords.x
	var y = coords.y
	var z = coords.z

	var width = size.x
	var height = size.y
	var length = size.z
	var dirs = []
	var new_dirs = []

	for offset in siblings_offsets:
		if bounds.has_point(coords + offset):
			dirs.append(offset)

	return dirs


func get_possible_siblings(coordinates : Vector3, direction : Vector3) -> Dictionary:
	var valid_siblings = {}
	var direction_name = siblings_offsets[direction]
	var prototypes = get_possibilities(coordinates)
	var sibling_coordinates = coordinates + direction
	for item in prototypes:
		var siblings = prototypes[item]['valid_siblings'][direction_name]
		for n in siblings:
			if not n in valid_siblings:
				valid_siblings[n] = siblings[n]
	return valid_siblings


func get_possibilities(coords : Vector3):
	return wave_function[coords.z][coords.y][coords.x]



