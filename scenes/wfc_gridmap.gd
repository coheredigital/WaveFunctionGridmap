# A little test combining Martin Donald's work with WFC with Godots Gridmap
tool
extends GridMap

export var size : Vector3 = Vector3(8.0,3.0,8.0)
export var prototype_data : Resource
export var initialize_cells : bool setget set_initialize
export var generate_step : bool setget set_generate_step
#export var generate_map : bool setget set_generate_map

export var prototypes := {}
export var cell_states := {}
export var cell_queue := {}
export var stack : Array

var bounds : AABB
var siblings_offsets = {
	Vector3.FORWARD : 'forward',
	Vector3.RIGHT : 'right',
	Vector3.BACK : 'back',
	Vector3.LEFT : 'left',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down',
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


# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()


func set_generate_step(value):
	if not value:
		return
	iterate()


#func set_generate_map(value):
#	if not value:
#		return
#	print('Generate map!')
#	generate()


func generate():
	initialize()
	seed(OS.get_unix_time())
	while not is_collapsed():
		iterate()
		yield(get_tree(), "idle_frame")


func set_initialize(value):
	if not value:
		return
	initialize()


func initialize():
	clear() #clear the gridmap
	prototypes = prototype_data.prototypes.duplicate()
	cell_states = {}
	cell_queue = {}
	bounds = AABB(Vector3.ZERO, size - Vector3(1.0,1.0,1.0))
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var coords = Vector3(x,y,z)
#				track each unique cell state
				cell_states[coords] = prototypes.duplicate()
				cell_queue[coords] = [get_entropy(coords),coords]

	sort_queue()

	print_debug('cells intialized: %s' % cell_states.size())



func is_collapsed() -> bool:
	return cell_queue.size() == 0


func iterate():
	var coords = get_min_entropy_coords()
	print_debug("Iterate cell: %s" % coords)
	assert( coords != Vector3.INF, 'Invalid coords returned from get_min_entropy_coords.')
	collapse_at(coords)
	propagate(coords)


func collapse_at(coords : Vector3):
	var possible_prototypes = cell_states[coords]
	var selection = weighted_choice(possible_prototypes)
	var prototype = possible_prototypes[selection]
	possible_prototypes = {selection : prototype}
	cell_states[coords] = possible_prototypes
	cell_queue.erase(coords)
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
	var entropy_array = cell_queue.values()
	var queued_cell : Array = entropy_array.pop_front()
	var queue_entropy : float = queued_cell[0]
	var queue_coords : Vector3 = queued_cell[1]
	print('queued: %s entropy: %s'  % [queue_coords, queue_entropy])
	return queue_coords


func sort_queue():
	print_debug('Sort queue')
	var entropy_array = cell_queue.values()
	entropy_array.sort_custom(EntropySorter, "sort_ascending")
#	reset queue order
#	TODO: consider using a sorted array, may be easier
	cell_queue = {}
	for item in entropy_array:
		cell_queue[item[1]] = [item[0],item[1]]


func get_entropy(coords : Vector3):
	var available_prototypes = cell_states[coords]
	var entropy = len(available_prototypes)
	entropy += rand_range(-0.1, 0.1)
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
	cell_states[coords].erase(cell_name)


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
	return cell_states[coords]

