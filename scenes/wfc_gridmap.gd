# A little test combining Martin Donald's work with WFC with Godots Gridmap
tool
extends GridMap

export var size : Vector3 = Vector3(8.0,3.0,8.0) setget set_size
export var prototype_data : Resource
export var reset : bool setget set_reset
#export var refresh_queue : bool setget set_refresh_queue
export var generate_step : bool setget set_generate_step
#export var generate_map : bool setget set_generate_map

export var cell_states : Dictionary = {}
#var cell_queue : Dictionary = {}
var stack : Array

export var wave_function : Array  # Grid of modules containing prototypes

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

#
#func set_refresh_queue(value):
#	if not value:
#		return
#	update_queue()


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



func set_reset(value):
	if not value:
		return
	initialize()


func set_size(value : Vector3):
	size = value
	bounds = AABB(Vector3.ZERO, size - Vector3(1.0,1.0,1.0))


func initialize():
	clear() #clear the gridmap
	cell_states = {}
#	cell_queue = {}
	initialize_cells()
	initialize_wave_funtion()
#	update_queue()
	print_debug('cells intialized: %s' % cell_states.size())


func initialize_wave_funtion():
	for _z in range(size.z):
		var y = []
		for _y in range(size.y):
			var x = []
			for _x in range(size.x):
				x.append(prototype_data.prototypes.duplicate(true))
			y.append(x)
		wave_function.append(y)
	print_debug('Wave function initialized')

func initialize_cells():
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var coords = Vector3(x,y,z)
#				track each unique cell state
				cell_states[coords] = prototype_data.prototypes.duplicate(true)
#				cell_queue[coords] = [get_entropy(coords),coords]


#func update_queue() -> void:
#	for coords in cell_queue:
#		cell_queue[coords] = [get_entropy(coords),coords]
#	sort_queue()

#func is_collapsed() -> bool:
#	return cell_queue.size() == 0


func is_collapsed():
	for item in cell_states:
		if len(cell_states[item]) > 1:
			return false
	return true


func iterate():
	var coords = get_min_entropy_coords()
	print_debug("Iterate cell: %s" % coords)
	collapse_at(coords)
	propagate(coords)
#	update_queue()


func collapse_at(coords : Vector3):
	var possible_prototypes = cell_states[coords]
	var selection_name = weighted_choice(possible_prototypes)
	var prototype = possible_prototypes[selection_name].duplicate(true)
	possible_prototypes = {selection_name : prototype}
	cell_states[coords] = possible_prototypes
#	cell_queue.erase(coords)
#	apply cell
#	print_debug('collapsed coord: %s' % coords)
	set_cell_item(coords.x,coords.y,coords.z,prototype.cell_index,prototype.cell_orientation)


func weighted_choice(prototypes):
	var proto_weights = {}

	for p in prototypes:
		var w = prototypes[p]['count']
		w += rand_range(-1.0, 1.0)
		proto_weights[w] = p
		print_debug('weighted_choice: %s = %s' % [p,w])

	var weight_list = proto_weights.keys()
	weight_list.sort()
	return proto_weights[weight_list[-1]]


#func get_min_entropy_coords() -> Vector3:
##	var queued_cell : Array = cell_queue.values().pop_front()
#	var queue_entropy : float = queued_cell[0]
#	var queue_coords : Vector3 = queued_cell[1]
#	print('queued: %s entropy: %s'  % [queue_coords, queue_entropy])
#	return queue_coords


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


#func sort_queue():
#	print_debug('Sort queue')
#	var entropy_array = cell_queue.values()
#	entropy_array.sort_custom(EntropySorter, "sort_ascending")
##	cell_order.sort_custom(EntropySorter, "sort_ascending")
##	reset queue order
##	TODO: consider using a sorted array, may be easier
#	cell_queue = {}
#	for item in entropy_array:
#		cell_queue[item[1]] = [item[0],item[1]]


func get_entropy(coords : Vector3):
	return len(cell_states[coords])


func propagate(co_ords):
	if co_ords:
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
	var valid_siblings = []
	var direction_name = siblings_offsets[direction]
	var prototypes = get_possibilities(coordinates)
	for item in prototypes:
		var item_valid_siblings = prototypes[item]['valid_siblings']
		var direction_valid_siblings = item_valid_siblings[direction_name]
		for prototype_name in item_valid_siblings:
			if not prototype_name in valid_siblings:
				valid_siblings.append(prototype_name)
	return valid_siblings


func get_possibilities(coords : Vector3):
#	print_debug('get_possibilities at: %s' % coords)
	return cell_states[coords].duplicate(true)

