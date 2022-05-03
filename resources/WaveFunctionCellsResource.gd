# WaveFunctionCells
extends Resource
class_name WaveFunctionCellsResource

signal cell_collapsed(coors, cell_index, cell_orientation)

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
export var cell_states : Dictionary = {}
var cell_queue : Dictionary = {}
var size : Vector3
var stack : Array


func initialize(new_size : Vector3, all_prototypes : Dictionary):
	size = new_size
	initialize_cells(all_prototypes)
	apply_constraints()
	cell_template = cell_states.duplicate(true)
	reset()
	print_debug('Wave function initialized')


func initialize_cells(all_prototypes : Dictionary) -> void:
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var coords = Vector3(x,y,z)
				cell_states[coords] = all_prototypes.duplicate()


func reset():
	cell_states = cell_template.duplicate(true)


func is_collapsed() -> bool:
	for item in cell_states:
		if len(cell_states[item]) > 1:
			return false
	return true


func get_possibilities(coords : Vector3) -> Array:
	return cell_states[coords]


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
	var possible_prototypes = cell_states[coords]
	var selection = weighted_choice(possible_prototypes)
	var prototype = possible_prototypes[selection]
	possible_prototypes = {selection : prototype}
	cell_states[coords] = possible_prototypes
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
	cell_states[coords].erase(cell_name)


func get_entropy(coords : Vector3) -> int:
	return len(cell_states[coords])


func get_min_entropy_coords() -> Vector3:
	var min_entropy = 1000.0
	var coords

	for cell_coords in cell_states:
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
#	emit_signal("cell_collapsed", coords, prototype.cell_index, prototype.cell_orientation)



func propagate(co_ords : Vector3) -> void:
	if co_ords != Vector3.INF:
		stack.append(co_ords)
	while len(stack) > 0:
		var cur_coords = stack.pop_back()
		var valid_directions := get_valid_directions(cur_coords)

		# Iterate over each adjacent cell to this one
		for direction in valid_directions:
			var sibling_coords = (cur_coords + direction)
			var possible_siblings = get_possible_siblings(cur_coords, direction)
			var sibling_possible_prototypes = get_possibilities(sibling_coords).duplicate()

			if len(sibling_possible_prototypes) == 0:
				continue

			for sibling_possible_prototype in sibling_possible_prototypes:
				if not sibling_possible_prototype in possible_siblings:
					constrain(sibling_coords, sibling_possible_prototype)
					if not sibling_coords in stack:
						stack.append(sibling_coords)


func get_valid_directions(coords) -> Array:
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


func apply_constraints():

	var add_to_stack = []

	var sibling_directions = siblings_offsets.duplicate()

	for coords in cell_states:

		var protos = get_possibilities(coords)
		if coords.y == size.y - 1:  # constrain top layer to not contain any uncapped prototypes
			for proto in protos.duplicate():
				var neighs  = protos[proto][SIBLINGS]['up']
				if not BLANK_CELL_ID in neighs:
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
		if coords.y > 0:  # everything other than the bottom
			for proto in protos.duplicate():
				var custom_constraint = protos[proto][CONSTRAIN_TO]
				if custom_constraint == CONSTRAINT_BOTTOM:
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
		if coords.y < size.y - 1:  # everything other than the top
			for proto in protos.duplicate():
				var custom_constraint = protos[proto][CONSTRAIN_TO]
				if custom_constraint == CONSTRAINT_TOP:
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
		if coords.y == 0:  # constrain bottom layer so we don't start with any top-cliff parts at the bottom
			for proto in protos.duplicate():
				var neighs  = protos[proto][SIBLINGS]['down']
				var custom_constraint = protos[proto][CONSTRAIN_FROM]
				if (not BLANK_CELL_ID in neighs) or (custom_constraint == CONSTRAINT_BOTTOM):
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
		if coords.x == size.x - 1: # constrain +x-
			for proto in protos.duplicate():
				var neighs  = protos[proto][SIBLINGS]['right']
				if not BLANK_CELL_ID in neighs:
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
		if coords.x == 0: # constrain -x
			for proto in protos.duplicate():
				var neighs  = protos[proto][SIBLINGS]['left']
				if not BLANK_CELL_ID in neighs:
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
		if coords.z == size.z - 1: # constrain +z
			for proto in protos.duplicate():
				var neighs  = protos[proto][SIBLINGS]['back']
				if not BLANK_CELL_ID in neighs:
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
		if coords.z == 0: # constrain -z
			for proto in protos.duplicate():
				var neighs  = protos[proto][SIBLINGS]['forward']
				if not BLANK_CELL_ID in neighs:
					protos.erase(proto)
					if not coords in stack:
						stack.append(coords)
	propagate(Vector3.INF)





