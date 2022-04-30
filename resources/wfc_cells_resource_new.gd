# WaveFunctionCells
extends Resource
class_name WaveFunctionCellsResourceNew

const MESH_NAME = "mesh_name"
const MESH_ROT = "mesh_rotation"
const MESH_INDEX = "gridmap_index"
const SIBLINGS = "valid_siblings"
const CONSTRAIN_TO = "constrain_to"
const CONSTRAIN_FROM = "constrain_from"
const CONSTRAINT_BOTTOM = "bot"
const CONSTRAINT_TOP = "top"
const WEIGHT = "count"


const pX = 0
const pY = 1
const nX = 2
const nY = 3
const pZ = 4
const nZ = 5


var siblings_offsets = {
	Vector3.LEFT : 2,
	Vector3.RIGHT : 0,
	Vector3.FORWARD : 1, # should be 3?
	Vector3.BACK : 3, # should be 1?
	Vector3.UP : 4,
	Vector3.DOWN : 5
}

var cell_states : Dictionary = {}
var cell_queue : Dictionary = {}
var size : Vector3
var stack : Array


func initialize(new_size : Vector3, all_prototypes : Dictionary):
	size = new_size
	initialize_cells(all_prototypes)
	print_debug('Wave function initialized')


func initialize_cells(all_prototypes : Dictionary) -> void:
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var coords = Vector3(x,y,z)
				cell_states[coords] = all_prototypes.duplicate()


func is_collapsed() -> bool:
	for item in cell_states:
		if len(cell_states[item]) > 1:
			return false
	return true


func get_possibilities(coords : Vector3) -> Array:
	return cell_states[coords]


func get_possible_siblings(coords : Vector3, direction : Vector3) -> Array:
	var valid_siblings = []
	var direction_index = siblings_offsets[direction]
	var prototypes = get_possibilities(coords)
	for prototype in prototypes:
		var item_valid_siblings = prototypes[prototype][SIBLINGS]
		var siblings = item_valid_siblings[direction_index]
		for item in siblings:
			if not item in valid_siblings:
				valid_siblings.append(item)
	return valid_siblings


func collapse_at(coords : Vector3):
	var possible_prototypes = cell_states[coords]
	var selection = weighted_choice(possible_prototypes)
	var prototype = possible_prototypes[selection]
	possible_prototypes = {selection : prototype}
	cell_states[coords] = possible_prototypes


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


func iterate() -> void:
	var coords := get_min_entropy_coords()
	collapse_at(coords)
	propagate(coords)


func propagate(co_ords : Vector3) -> void:
	if co_ords != Vector3.INF:
		stack.append(co_ords)
	while len(stack) > 0:
		var cur_coords = stack.pop_back()
		var sibling_offsets := get_siblings_offsets(cur_coords)

		# Iterate over each adjacent cell to this one
		for direction in sibling_offsets:
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


func get_siblings_offsets(coords) -> Array:
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
