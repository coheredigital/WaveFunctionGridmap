# WaveFunctionCells
extends Resource
class_name WaveFunctionCellsResource

signal cell_collapsed(coors, cell_index, cell_orientation)
signal collapsed

const MESH_NAME = "mesh_name"
const MESH_ROT = "mesh_rotation"
const MESH_INDEX = "gridmap_index"
const SIBLINGS = "valid_siblings"
const CONSTRAIN_TO = "constrain_to"
const CONSTRAIN_FROM = "constrain_from"
const CONSTRAINT_BOTTOM = "bot"
const CONSTRAINT_TOP = "top"
const WEIGHT = "weight"
const BLANK_CELL_ID = "-1_-1"
const BLANK_CELL_INDEX = "-1"


const siblings_offsets = {
	Vector3.LEFT : 'left',
	Vector3.RIGHT : 'right',
	Vector3.FORWARD : 'forward',
	Vector3.BACK : 'back',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down'
}


const siblings_index = {
	Vector3.LEFT : 2,
	Vector3.RIGHT : 0,
	Vector3.BACK : 3, # should be 1?
	Vector3.FORWARD : 1, # should be 3?
	Vector3.UP : 4,
	Vector3.DOWN : 5
}


class EntropySorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false
	static func sort_descending(a, b):
		if a[0] > b[0]:
			return true
		return false


export var cell_template : Dictionary = {}
export var cells : Dictionary = {}
var cell_queue : Dictionary = {}
var size : Vector3
var stack : Array
var is_ready := true


func initialize(new_size : Vector3, prototypes : Dictionary):
	size = new_size
	initialize_cells(prototypes)
	apply_constraints()
	cell_template = cells.duplicate(true)
	reset()
	print_debug('Wave function initialized')


func initialize_cells(prototypes : Dictionary) -> void:
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var coords = Vector3(x,y,z)
				cells[coords] = prototypes.duplicate()


func reset():
	is_ready = true
	cells = cell_template.duplicate(true)


func collapse() -> void:
	if not is_ready:
		return
	while not is_collapsed():
		is_ready = false
		step_collapse()
	is_ready = true


func is_collapsed() -> bool:

	for item in cells:
		if len(cells[item]) > 1:
			return false
	return true


func get_possibilities(coords : Vector3) -> Array:
	return cells[coords]


func get_possible_siblings(coords : Vector3, direction : Vector3) -> Array:
	var valid_siblings = []
	var direction_name = siblings_offsets[direction]
	var prototypes = get_possibilities(coords)
	for id in prototypes:
		var item_valid_siblings = prototypes[id][SIBLINGS]
		var siblings = item_valid_siblings[direction_name]
		for item in siblings:
			if not item in valid_siblings:
				valid_siblings.append(item)
	return valid_siblings


func collapse_at(coords : Vector3) -> Dictionary:
	var possible_prototypes = cells[coords]
	var selection = weighted_choice(possible_prototypes)
	var prototype = possible_prototypes[selection]
	possible_prototypes = {selection : prototype}
	cells[coords] = possible_prototypes
	return prototype


func weighted_choice(prototypes : Dictionary) -> String:
	var proto_weights = {}
	for p in prototypes:
		var w = prototypes[p][WEIGHT]
		w += rand_range(-1.0, 1.0)
		proto_weights[w] = p
	var weight_list = proto_weights.keys()
	weight_list.sort()
	return proto_weights[weight_list[-1]]


func constrain(coords : Vector3, cell_name : String) -> void:
	cells[coords].erase(cell_name)


func get_entropy(coords : Vector3) -> int:
	return len(cells[coords])


func get_min_entropy_coords() -> Vector3:
	var min_entropy = 1000.0
	var coords

	for cell_coords in cells:
		var entropy = get_entropy(cell_coords)
		if entropy > 1:
			entropy += rand_range(-0.1, 0.1)
			if entropy < min_entropy:
				min_entropy = entropy
				coords = cell_coords

	return coords


func step_collapse() -> void:
	var coords := get_min_entropy_coords()
	var prototype := collapse_at(coords)
	propagate(coords)


func propagate(coords : Vector3) -> void:
	if coords != Vector3.INF:
		stack.append(coords)
	while len(stack) > 0:
		var current_coords = stack.pop_back()
		var valid_directions := get_valid_directions(current_coords)

		# Iterate over each adjacent cell to this one
		for direction in valid_directions:
			var sibling_coords = (current_coords + direction)
			var possible_siblings = get_possible_siblings(current_coords, direction)
			var sibling_possible_prototypes = get_possibilities(sibling_coords).duplicate()

			if len(sibling_possible_prototypes) == 0:
				continue

			for sibling_possible_prototype in sibling_possible_prototypes:
				if not sibling_possible_prototype in possible_siblings:
					constrain(sibling_coords, sibling_possible_prototype)
					if not sibling_coords in stack:
						stack.append(sibling_coords)


func get_valid_directions(coords) -> Array:
	var directions = []
	if coords.x > 0:
		directions.append(Vector3.LEFT)
	if coords.x < size.x-1:
		directions.append(Vector3.RIGHT)
	if coords.y > 0:
		directions.append(Vector3.DOWN)
	if coords.y < size.y-1:
		directions.append(Vector3.UP)
	if coords.z > 0:
		directions.append(Vector3.FORWARD)
	if coords.z < size.z-1:
		directions.append(Vector3.BACK)
	return directions


func apply_constraints():

	var add_to_stack = []

	var sibling_directions = siblings_offsets.duplicate()

	for coords in cells:

		var prototypes = get_possibilities(coords)
		if coords.y == size.y - 1:  # constrain top layer to not contain any uncapped prototypes
			for proto in prototypes.duplicate():
				var siblings = prototypes[proto][SIBLINGS]['up']
				if not BLANK_CELL_INDEX in siblings:
					prototypes.erase(proto)
					if not coords in stack:
						stack.append(coords)

#		if coords.y > 0:  # everything other than the bottom
#			for proto in prototypes.duplicate():
#				var custom_constraint = prototypes[proto][CONSTRAIN_TO]
#				if custom_constraint == CONSTRAINT_BOTTOM:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.y < size.y - 1:  # everything other than the top
#			for proto in prototypes.duplicate():
#				var custom_constraint = prototypes[proto][CONSTRAIN_TO]
#				if custom_constraint == CONSTRAINT_TOP:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.y == 0:  # constrain bottom layer so we don't start with any top-cliff parts at the bottom
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS]['down']
#				var custom_constraint = prototypes[proto][CONSTRAIN_FROM]
#				if (not BLANK_CELL_ID in neighs) or (custom_constraint == CONSTRAINT_BOTTOM):
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.x == size.x - 1: # constrain +x-
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS]['right']
#				if not BLANK_CELL_ID in neighs:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.x == 0: # constrain -x
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS]['left']
#				if not BLANK_CELL_ID in neighs:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.z == size.z - 1: # constrain +z
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS]['back']
#				if not BLANK_CELL_ID in neighs:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.z == 0: # constrain -z
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS]['forward']
#				if not BLANK_CELL_ID in neighs:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
	propagate(Vector3.INF)





