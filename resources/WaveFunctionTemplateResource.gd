# WaveFunctionCells
extends Resource
class_name WaveFunctionTemplateResource

export var prototypes := {}

const VECTOR_INVERSE = Vector3(-1.0,-1.0,-1.0)
const FILE_NAME = "res://resources/prototypes.json"
const NULL_CELL_ID = "-1_-1"
const DEFAULT_PROTOTYPE = {
	'weight' : 0,
	'siblings': {},
	'valid_siblings': {
		'right' : [],
		'forward' : [],
		'left': [],
		'back': [],
		'up': [],
		'down': []
	},
	'cell_index': -1,
	'cell_orientation': -1,
	'mirror': {
		'x': 0,
		'y': 0,
		'z': 0,
	},
	'constrain_to': 'bot',
	'constrain_from': 'bot',
	'constraints': {
		'x': {
			'to': -1,
			'from': -1,
		},
		'y': {
			'to': 0,
			'from': 0,
		},
		'z': {
			'to': -1,
			'from': -1,
		}
	}
}


const sibling_directions = {
	Vector3.RIGHT : 'right',
	Vector3.FORWARD : 'forward',
	Vector3.LEFT : 'left',
	Vector3.BACK : 'back',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down'
}


class WaveFunctionProtoype:
	var cell_name : String = ''
	var cell_index : int = -1
	var cell_orientation : int = -1
	var weight : int = 1;
	var constrain_to : String = 'bot'
	var constrain_from : String = 'bot'
	var valid_siblings : Dictionary = {
		'right' : [],
		'forward' : [],
		'left': [],
		'back': [],
		'up': [],
		'down': []
	}

	func get_dictionary() -> Dictionary:
		return {
			'weight' : 1,
			'valid_siblings': valid_siblings,
			'cell_index': cell_index,
			'cell_orientation': cell_orientation,
			'constrain_to': constrain_to,
			'constrain_from': constrain_from,
		}


func _init():
	reset_prototypes()


func reset_prototypes() -> void:
	prototypes = {
		NULL_CELL_ID : get_null_prototype()
	}


func get_prototype(cell_id: String) -> Dictionary:
	if not prototypes.has(cell_id):
		prototypes[cell_id] = DEFAULT_PROTOTYPE.duplicate(true)
	return prototypes[cell_id]


func get_cell_prototype(cell_index: int, cell_orientation: int) -> Dictionary:
	var cell_id = "%s_%s" %  [cell_index,cell_orientation]
	return get_prototype(cell_id)


func get_null_prototype() -> Dictionary:
	var null_prototype = get_prototype(NULL_CELL_ID)
	for direction in sibling_directions:
		var direction_name = sibling_directions[direction]
		null_prototype.valid_siblings[direction_name].append(NULL_CELL_ID)
	null_prototype.wieght = 1
	null_prototype.constrain_to = '-1'
	null_prototype.constrain_from = '-1'
	return null_prototype


func append_cell_prototype(coords : Vector3, cell_index: int, cell_orientation: int) -> void:
	var cell_id = "%s_%s" %  [cell_index,cell_orientation]

	var prototype = get_prototype(cell_id)

	prototype.weight += 1
	prototype.cell_index = cell_index
	prototype.cell_orientation = cell_orientation

#	old vertical constraints
	if not coords.y == 0.0:
		prototype.constrain_to = ''
		prototype.constraints.y.to = -1

	if coords.y == 0.0:
		prototype.constrain_from = ''
		prototype.constraints.y.from = -1


func append_cell_sibling(cell_index: int, cell_orientation: int, direction : Vector3, sibling_cell_index: int, sibling_cell_orientation: int) -> void:
	var cell_id = "%s_%s" %  [cell_index,cell_orientation]
	var cell_prototype = get_prototype(cell_id)
	var sibling_cell_id = "%s_%s" %  [sibling_cell_index,sibling_cell_orientation]
	var sibling_prototype = get_prototype(sibling_cell_id)
	var direction_name = sibling_directions[direction]
	var direction_inverse = direction * VECTOR_INVERSE
	var direction_inverse_name = sibling_directions[direction_inverse]
#	append to sibling and inverse
	append_protoype_sibling(cell_prototype,direction,sibling_cell_id)
	append_protoype_sibling(sibling_prototype,direction_inverse,cell_id)

	track_unique_siblings(cell_prototype,direction,sibling_cell_index, sibling_cell_orientation)
	track_unique_siblings(sibling_prototype,direction,cell_index, cell_orientation)


func track_unique_siblings(cell_prototype: Dictionary, direction : Vector3, sibling_cell_index: int, sibling_cell_orientation: int):
	var direction_name = sibling_directions[direction]
	if not cell_prototype.siblings.has(direction_name):
		cell_prototype.siblings[direction_name] = {}

	if not cell_prototype.siblings[direction_name].has(sibling_cell_index):
		cell_prototype.siblings[direction_name][sibling_cell_index] = {}
	if not cell_prototype.siblings[direction_name][sibling_cell_index].has(sibling_cell_orientation):
		cell_prototype.siblings[direction_name][sibling_cell_index][sibling_cell_orientation] = 1

	cell_prototype.siblings[direction_name][sibling_cell_index][sibling_cell_orientation] = cell_prototype.siblings[direction_name][sibling_cell_index][sibling_cell_orientation] + 1



func append_protoype_sibling(prototype: Dictionary, direction : Vector3, sibling_cell_id: String) -> void:
	var direction_name = sibling_directions[direction]
	if not prototype.valid_siblings[direction_name].has(sibling_cell_id):
		prototype.valid_siblings[direction_name].append(sibling_cell_id)




# use some simple logic to progogate siblings in cases where cell are symmetrical
func update_symmetry() -> void:

	for id in prototypes:
		var prototype = get_prototype(id)
		var direction_symmetry = Vector3.ZERO
		for direction in sibling_directions:
			var direction_name = sibling_directions[direction]
			var direction_inverse = direction * VECTOR_INVERSE
			var direction_inverse_name = sibling_directions[direction_inverse]

			var siblings = prototype.valid_siblings[direction_name]
			var inverse_siblings = prototype.valid_siblings[direction_inverse_name]
			for cell_id in siblings:
				if inverse_siblings.has(cell_id):
					direction_symmetry = direction_symmetry.linear_interpolate(direction.abs(), 1.0)
#					direction_symmetry = max(direction_symmetry, abs(direction))
#					print_debug('symmetry (%s): %s %s = %s %s' % [cell_id, direction_name, direction_inverse_name, direction, direction_symmetry])

			prototype.mirror.x = max(prototype.mirror.x,direction_symmetry.x)
			prototype.mirror.y = max(prototype.mirror.x,direction_symmetry.y)
			prototype.mirror.z = max(prototype.mirror.x,direction_symmetry.z)



func get_prototypes() -> Dictionary:
	return prototypes
