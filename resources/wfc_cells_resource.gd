# WaveFunctionPrototypes
extends Resource
class_name WaveFunctionCellsResource

export var size : Vector3

#export var wave_function : Array  # Grid of cells containing prototypes
export var cell_list : Dictionary = {}
export var cell_stack : Dictionary = {}
export var prototypes : Dictionary = {}
export var cell_states := {}
export var cell_queue := {}
export var bounds : AABB
var stack : Array

class EntropySorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false
	static func sort_descending(a, b):
		if a[0] > b[0]:
			return true
		return false

var siblings_offsets = {
	Vector3.FORWARD : 'forward',
	Vector3.RIGHT : 'right',
	Vector3.BACK : 'back',
	Vector3.LEFT : 'left',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down',
}


func _init(new_size : Vector3, all_prototypes : Dictionary):
	cell_states = {}
	cell_queue = {}
	prototypes = all_prototypes
	bounds = AABB(Vector3.ZERO, size - Vector3(1.0,1.0,1.0))
	initialize_cells()
	update_queue()
	print_debug('cells intialized: %s' % cell_states.size())


func initialize_cells():
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var coords = Vector3(x,y,z)
#				track each unique cell state
				cell_states[coords] = prototypes.duplicate(true)
				cell_queue[coords] = [get_entropy(coords),coords]


func get_entropy(coords : Vector3):
	var available_prototypes = cell_states[coords]
	var entropy = len(available_prototypes)
	entropy += rand_range(-0.1, 0.1)
	return entropy


func update_queue() -> void:
	for coords in cell_queue:
		cell_queue[coords] = [get_entropy(coords),coords]
	sort_queue()

func sort_queue():
	print_debug('Sort queue')
	var entropy_array = cell_queue.values()
	entropy_array.sort_custom(EntropySorter, "sort_ascending")
#	reset queue order
#	TODO: consider using a sorted array, may be easier
	cell_queue = {}
	for item in entropy_array:
		cell_queue[item[1]] = [item[0],item[1]]
