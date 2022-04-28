# A little test combining Martin Donald's work with WFC with Godots Gridmap
tool
extends GridMap


export var size : Vector3 = Vector3(8.0,3.0,8.0)

var prototypes := {}
var wave_function : Array  # Grid of cells containing prototypes
var grid_cells_state = {}
var stack : Array

export var export_definitions : bool = false setget set_export_definitions

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


func generate():

	seed(OS.get_unix_time())
	self.initialize(size)


	while not is_collapsed():
		iterate()
		yield(get_tree(), "idle_frame")





func iterate():
	var coords = get_min_entropy_coords()
	collapse_at(coords)
	propagate(coords)


func get_min_entropy_coords():
	var min_entropy
	var coords
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


func collapse_at(coords : Vector3):
	var possible_prototypes = wave_function[coords.z][coords.y][coords.x]
	var selection = weighted_choice(possible_prototypes)
	var prototype = possible_prototypes[selection]
	possible_prototypes = {selection : prototype}
	wave_function[coords.z][coords.y][coords.x] = possible_prototypes


func weighted_choice(prototypes):
	var proto_weights = {}
	for p in prototypes:
		var w = prototypes[p]['count']
		w += rand_range(-1.0, 1.0)
		proto_weights[w] = p
	var weight_list = proto_weights.keys()
	weight_list.sort()
	return proto_weights[weight_list[-1]]


func propagate(co_ords, single_iteration=false):
	if co_ords:
		stack.append(co_ords)
	while len(stack) > 0:
		var cur_coords = stack.pop_back()

		# Iterate over each adjacent cell to this one
		for d in valid_dirs(cur_coords):

			var other_coords = (cur_coords + d)
			var possible_neighbours = get_possible_siblings(cur_coords, d)
			var other_possible_prototypes = get_possibilities(other_coords).duplicate()

			if len(other_possible_prototypes) == 0:
				continue

			for other_prototype in other_possible_prototypes:
				if not other_prototype in possible_neighbours:
					constrain(other_coords, other_prototype)
					if not other_coords in stack:
						stack.append(other_coords)
		if single_iteration:
			break


func constrain(coords : Vector3, prototype_name : String):
	wave_function[coords.z][coords.y][coords.x].erase(prototype_name)


func valid_dirs(coords):
	var x = coords.x
	var y = coords.y
	var z = coords.z

	var width = size.x
	var height = size.y
	var length = size.z
	var dirs = []

	if x > 0: dirs.append(Vector3.LEFT)
	if x < width-1: dirs.append(Vector3.RIGHT)
	if y > 0: dirs.append(Vector3.DOWN)
	if y < height-1: dirs.append(Vector3.UP)
	if z > 0: dirs.append(Vector3.FORWARD)
	if z < length-1: dirs.append(Vector3.BACK)

	return dirs



func initialize(new_size : Vector3):
	update_prototypes()

	size = new_size
	for _z in range(size.z):
		var y = []
		for _y in range(size.y):
			var x = []
			for _x in range(size.x):
				x.append(prototypes.duplicate())
#				track each unique cell state
				grid_cells_state[Vector3(_x,_y,_z)] = prototypes.duplicate()
			y.append(x)
		wave_function.append(y)


# Called when the node enters the scene tree for the first time.
func _ready():
	update_prototypes()


func update_prototypes() -> void:
	#	initialize cell list
	var cell_list := mesh_library.get_item_list()
	for item in cell_list:
		prototypes[item] = {
			'count' : 0,
			'valid_siblings': {}
		}

	var cells := get_used_cells()
	for cell_coordinates in cells:

		var cell_index := get_cell_item(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		if not prototypes.has(cell_index):
			continue

		var cell_prototype = prototypes[cell_index]
		var valid_siblings : Dictionary = cell_prototype.valid_siblings
		cell_prototype.count += 1

#		check valid nearby cells
		for offset in siblings_offsets:
			var offset_name = siblings_offsets[offset]
			var cell_offset = cell_coordinates + offset
			var sibling_cell = get_cell_item(cell_offset.x, cell_offset.y, cell_offset.z)
			var sibling_cell_orientation = get_cell_item_orientation(cell_offset.x, cell_offset.y, cell_offset.z)

#			init sibling dictionary
			if not offset_name in valid_siblings:
				valid_siblings[offset_name] = {}

			var cell_valid_siblings = valid_siblings[offset_name]

#			init valid sibling / orientation
			if not cell_valid_siblings.has(sibling_cell):
				cell_valid_siblings[sibling_cell] = []

#			append unique orientations
			if not cell_valid_siblings[sibling_cell].has(sibling_cell_orientation):
				cell_valid_siblings[sibling_cell].append(sibling_cell_orientation)


func is_collapsed():
	for z in wave_function:
		for y in z:
			for x in y:
				if len(x) > 1:
					return false
	return true


func get_possibilities(coords : Vector3):
	return wave_function[coords.z][coords.y][coords.x]


func get_possible_siblings(coordinates : Vector3, direction : Vector3):
	var valid_siblings = []
	var prototypes = get_possibilities(coordinates)
	var sibling_coordinates = coordinates + direction
	var direction_name = siblings_offsets[direction]
	for prototype in prototypes:
		var siblings = prototypes[prototype]['valid_siblings'][direction_name]
		for n in siblings:
			if not n in valid_siblings:
				valid_siblings.append(n)


func set_export_definitions(value : bool) -> void:
	update_prototypes()
	print(prototypes)

