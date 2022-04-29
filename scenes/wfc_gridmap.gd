# A little test combining Martin Donald's work with WFC with Godots Gridmap
tool
extends GridMap

export var size : Vector3 = Vector3(8.0,3.0,8.0)
export var prototype_data : Resource
var prototypes := {}

var wave_function : Array  # Grid of cells containing prototypes
var cell_states := {}
var cell_stack := {}
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

# Called when the node enters the scene tree for the first time.
func _ready():
	prototypes = prototype_data.prototypes
	initialize_cells()

func generate():

	clear()
	initialize_cells()
	seed(OS.get_unix_time())
	while not is_collapsed():
		iterate()
		yield(get_tree(), "idle_frame")

func initialize_cells():
	bounds = AABB(Vector3.ZERO, size - Vector3(1.0,1.0,1.0))
	for _z in range(size.z):
		var y = []
		for _y in range(size.y):
			var x = []
			for _x in range(size.x):
				x.append(prototypes.duplicate())
#				track each unique cell state
				cell_states[Vector3(_x,_y,_z)] = prototypes.duplicate()
				cell_stack[Vector3(_x,_y,_z)] = 1
			y.append(x)
		wave_function.append(y)
	print('cells intialized: %s' % cell_states.size())


func is_collapsed() -> bool:
	return cell_stack.size() == 0


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
	cell_stack.erase(coords)
#	apply cell
	print('collapsed coord: %s' % coords)
	set_cell_item(coords.x,coords.y,coords.z,selection)


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

			for sibling_prototype in sibling_possible_prototypes:
				var sibling_cell = possible_siblings[sibling_prototype]
				if not sibling_cell in possible_siblings:
					constrain(sibling_coords, sibling_possible_prototypes[sibling_prototype])
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


func get_possibilities(coords : Vector3):
	return wave_function[coords.z][coords.y][coords.x]



