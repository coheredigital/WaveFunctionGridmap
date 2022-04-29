# WaveFunctionPrototypes
extends Resource
class_name WaveFunctionPrototypesResource


export var size : Vector3 = Vector3(8.0,3.0,8.0)

export var wave_function : Array  # Grid of cells containing prototypes
export var cell_list : Dictionary = {}
export var cell_stack : Dictionary = {}
export var prototypes : Dictionary = {}


var cell_states := {}
var stack : Array
var bounds : AABB


enum CellStates {
	READY,
	COLLAPSED = -2
}


var siblings_offsets = {
	Vector3.FORWARD : 'forward',
	Vector3.RIGHT : 'right',
	Vector3.BACK : 'back',
	Vector3.LEFT : 'left',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down',
}


func _init():
	cell_list = {}
	prototypes = {}


# Called when the node enters the scene tree for the first time.
func collapse():
	initialize_cells()
	seed(OS.get_unix_time())
	iterate()
#	while not is_collapsed():
#		iterate()
#		yield(get_tree(), "idle_frame")

func initialize_cells():
	bounds = AABB(Vector3.ZERO, size)
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
	print('cells intialized: %s' % cell_states.size())


func is_collapsed() -> bool:
	return cell_states.size() == 0


func iterate():
	var coords = get_min_entropy_coords()
	collapse_at(coords)
	propagate(coords)


func collapse_at(coords : Vector3):
	if coords == Vector3.INF:
		push_warning('Invalid coords passed.')
		return

	var possible_prototypes = wave_function[coords.z][coords.y][coords.x]
	var selection = weighted_choice(possible_prototypes)

	var prototype = possible_prototypes[selection]
	possible_prototypes = {selection : prototype}
	wave_function[coords.z][coords.y][coords.x] = possible_prototypes
	cell_states.erase(coords)
#	apply cell
	print('collapsed coord: %s' % coords)


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
	var min_entropy
	var coords = Vector3.INF
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.z):
				var entropy = get_entropy(Vector3(x, y, z))
				if entropy > 1:
					entropy += rand_range(-0.1, 0.1)
					if not min_entropy:
						min_entropy = entropy
						coords = Vector3(x, y, z)
					elif entropy < min_entropy:
						min_entropy = entropy
						coords = Vector3(x, y, z)
	return coords


func get_entropy(coords : Vector3):
	return len(wave_function[coords.z][coords.y][coords.x])


func propagate(co_ords):
	if co_ords:
		stack.append(co_ords)
	while len(stack) > 0:
		var cur_coords = stack.pop_back()
		for offset in get_siblings_offsets(cur_coords):
			var sibling_coords = cur_coords + offset
			var possible_siblings = get_possible_siblings(cur_coords, offset)
			var sibling_possible_prototypes = get_possibilities(sibling_coords).duplicate()

			if len(sibling_possible_prototypes) == 0:
				continue

			for sibling_prototype in sibling_possible_prototypes:
				if not sibling_prototype in possible_siblings:
					constrain(sibling_coords, sibling_prototype)
					if not sibling_coords in stack:
						stack.append(sibling_coords)


func constrain(coords : Vector3, gridmap_index : int):
	wave_function[coords.z][coords.y][coords.x].erase(gridmap_index)


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


func get_possibilities(coords : Vector3):

	if not wave_function.has(coords.z):
		return []
	var z = wave_function[coords.z]

	if not z.has(coords.y):
		return []
	var y = z[coords.y]

	if not y.has(coords.x):
		return []

	var x = y[coords.x]
	return x


func get_possible_siblings(coordinates : Vector3, direction : Vector3) -> Array:
	var valid_siblings = []
	var prototypes = get_possibilities(coordinates)
	var sibling_coordinates = coordinates + direction
	var direction_name = siblings_offsets[direction]
	for prototype in prototypes:
		var siblings = prototypes[prototype]['valid_siblings'][direction_name]
		for n in siblings:
			if not n in valid_siblings:
				valid_siblings.append(n)
	return valid_siblings

