tool
extends GridMap
class_name WaveFunctionGridMap

signal cell_collapsed(coors, cell_index, cell_orientation)
signal collapsed

const BLANK_CELL_INDEX = "-1"
const BLANK_ID = "-1:-1"
const ORIENTATIONS = "valid_orientations"
const SIBLINGS = "valid_siblings"
const INDEX = "cell_index"
const ORIENTATION = "cell_orientation"
const WEIGHT = "weight"


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


export var initialize := false setget set_initialize
export var generate := false setget set_generate
export var step_collapse := false setget set_step_collapse
export var size = Vector3(8, 3, 8)
export var template_path : PackedScene

export var cells : Dictionary = {}
var cell_queue : Dictionary = {}
var stack : Array
var is_ready := true

onready var template : WaveFunctionGridMapTemplate


func initialize():
	clear()
	template = template_path.instance() as WaveFunctionGridMapTemplate
	template.update_prototypes()
	initialize_cells(template.prototypes)
	apply_constraints()
	print_debug('Wave function initialized')


func initialize_cells(prototypes : Dictionary) -> void:
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var coords = Vector3(x,y,z)
				cells[coords] = prototypes.duplicate(true)


func collapse() -> void:
	if not is_ready:
		return
	while not is_collapsed():
		is_ready = false
		step_collapse()
	is_ready = true


func step_collapse() -> void:
	var coords := get_min_entropy_coords()
	if not coords:
		print_debug('min enrtopy coords not found')
		return
	print('min entropy coords: %s' % coords)
	var prototype := collapse_coord(coords)
	propagate(coords)


func get_random(dict):
   var a = dict.keys()
   a = a[randi() % a.size()]
   return a


func collapse_coord(coords : Vector3) -> Dictionary:
	var possible_prototypes = cells[coords]
	var selection = weighted_choice(possible_prototypes)
	var prototype = possible_prototypes[selection]
#	replace with selected prototype
	cells[coords] = {selection : prototype}
	set_cell_item(coords.x,coords.y,coords.z,prototype[INDEX],prototype[ORIENTATION])
	return prototype


func is_collapsed() -> bool:
	for item in cells:
		if len(cells[item]) > 1:
			return false
	return true


func get_possibilities(coords : Vector3) -> Array:
	return cells[coords]


func get_possible_siblings(coords : Vector3, direction : Vector3) -> Array:
	var valid_siblings = []
	var prototypes = get_possibilities(coords)
	for cell_id in prototypes:
		var item_valid_siblings = prototypes[cell_id][SIBLINGS]
		var siblings = item_valid_siblings[direction]
		for sibling_cell_id in siblings:
			if not sibling_cell_id in valid_siblings:
				valid_siblings.append(sibling_cell_id)
	return valid_siblings


func weighted_choice(prototypes : Dictionary) -> String:
	var proto_weights = {}
	for cell_id in prototypes:
		var weight = prototypes[cell_id][WEIGHT]
		weight += rand_range(-1.0, 1.0)
		proto_weights[weight] = cell_id
	var weight_list = proto_weights.keys()
	weight_list.sort()
	return proto_weights[weight_list[-1]]


func get_entropy(coords : Vector3) -> int:
	var prototypes = cells[coords]
	var entropy : int = len(prototypes)
	return entropy


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


func propagate(coords : Vector3) -> void:
	print_debug('propagate: %s' % coords)
	if coords != Vector3.INF:
		stack.append(coords)
	while len(stack) > 0:
		var current_coords = stack.pop_back()
		var valid_directions := get_valid_directions(current_coords)

		# Iterate over each adjacent cell to this one
		for direction in valid_directions:
			var sibling_coords = current_coords + direction
			var valid_siblings = get_possible_siblings(current_coords, direction)
			var sibling_possible_prototypes = get_possibilities(sibling_coords).duplicate()

			if sibling_possible_prototypes.size() == 0:
				continue

			for sibling_cell_id in sibling_possible_prototypes:
				if not sibling_cell_id in valid_siblings:
					cells[sibling_coords].erase(sibling_cell_id)
#					if not sibling_coords in stack:
#						stack.append(sibling_coords)





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

	for coords in cells:
		var prototypes = get_possibilities(coords)
		if coords.y == size.y - 1:  # constrain top layer to not contain any uncapped prototypes
			for cell_id in prototypes.duplicate():
				var siblings = prototypes[cell_id][SIBLINGS][Vector3.UP]
				if not BLANK_CELL_INDEX in siblings:
					prototypes.erase(cell_id)
#					if not coords in stack:
#						stack.append(coords)
		if coords.y > 0:  # everything other than the bottom
			for id in prototypes.duplicate():
				var custom_constraint = prototypes[id]['constraints']['y']['to']
				if custom_constraint == 0:
					prototypes.erase(id)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.y < size.y - 1:  # everything other than the top
#			for proto in prototypes.duplicate():
#				var custom_constraint = prototypes[proto][CONSTRAIN_TO]
#				if custom_constraint == CONSTRAINT_TOP:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
		if coords.y == 0:  # constrain bottom layer so we don't start with any top-cliff parts at the bottom
			for id in prototypes.duplicate():
				var neighs  = prototypes[id][SIBLINGS][Vector3.DOWN]
				var custom_constraint = prototypes[id]['constraints']['y']['from']
				if (not BLANK_ID in neighs) or (custom_constraint == 0):
					prototypes.erase(id)
#					if not coords in stack:
#						stack.append(coords)
		if coords.x == size.x - 1: # constrain +x-
			for id in prototypes.duplicate():
				var neighs  = prototypes[id][SIBLINGS][Vector3.RIGHT]
				if not BLANK_ID in neighs:
					prototypes.erase(id)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.x == 0: # constrain -x
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS][Vector3.LEFT]
#				if not BLANK_CELL_ID in neighs:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.z == size.z - 1: # constrain +z
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS][Vector3.BACK]
#				if not BLANK_CELL_ID in neighs:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
#		if coords.z == 0: # constrain -z
#			for proto in prototypes.duplicate():
#				var neighs  = prototypes[proto][SIBLINGS][Vector3.FORWARD]
#				if not BLANK_CELL_ID in neighs:
#					prototypes.erase(proto)
#					if not coords in stack:
#						stack.append(coords)
	propagate(Vector3.INF)


func set_initialize(value: bool):
	if not value:
		return
	initialize()

func set_generate(value: bool):
	if not value:
		return
#	collapse()

func set_step_collapse(value: bool):
	if not value:
		return

	if is_collapsed():
		print_debug('All cells collapsed')
		return
	step_collapse()
