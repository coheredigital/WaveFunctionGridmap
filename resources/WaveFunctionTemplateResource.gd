# WaveFunctionCells
extends Resource
class_name WaveFunctionTemplateResource

var prototypes := {}

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

	const directions = {
		Vector3.FORWARD : 'forward',
		Vector3.BACK : 'back',
		Vector3.LEFT : 'left',
		Vector3.RIGHT : 'right',
		Vector3.UP : 'up',
		Vector3.DOWN : 'down'
	}

	var id : String = '-1_-1'
	var index : int = -1
	var orientation : int = -1
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


	func get_id(cell_index: int,cell_orientation: int) -> String:
		return "%s_%s" %  [cell_index,cell_orientation]


	func add_sibling(direction: Vector3,sibling_cell_index: int,sibling_cell_orientation: int):
		var direction_name = directions[direction]
		var sibling_id = get_id(sibling_cell_index,sibling_cell_orientation)
		if not valid_siblings[direction_name].has(sibling_id):
			valid_siblings[direction_name].append(sibling_id)


	func get_dictionary() -> Dictionary:
		return {
			'id' : id,
			'weight' : weight,
			'valid_siblings': valid_siblings,
			'index': index,
			'orientation': orientation,
			'constrain_to': constrain_to,
			'constrain_from': constrain_from,
		}


func _init():
	reset_prototypes()


func reset_prototypes() -> void:
	prototypes = {
		NULL_CELL_ID : get_null_prototype()
	}


func get_prototype(cell_index: int, cell_orientation: int) -> WaveFunctionProtoype:
	var id = "%s_%s" %  [cell_index,cell_orientation]
	if not prototypes.has(id):
		prototypes[id] = WaveFunctionProtoype.new()
	return prototypes[id]


func get_null_prototype() -> WaveFunctionProtoype:
	var null_prototype = get_prototype(-1,-1)
#	null prototype can always have null prototype as siblings
	for direction in sibling_directions:
		var direction_name = sibling_directions[direction]
		null_prototype.valid_siblings[direction_name].append(NULL_CELL_ID)
	null_prototype.weight = 1
	null_prototype.constrain_to = '-1'
	null_prototype.constrain_from = '-1'
	return null_prototype


func add_prototype(coords : Vector3, cell_index: int, cell_orientation: int):
	var prototype = get_prototype(cell_index,cell_orientation)


func add_prototype_sibling(cell_index: int, cell_orientation: int, direction : Vector3, sibling_cell_index: int, sibling_cell_orientation: int):
	var prototype := get_prototype(cell_index,cell_orientation)
	prototype.add_sibling(direction,sibling_cell_index,sibling_cell_orientation)
#	add inverse relationship
	var sibling_prototype := get_prototype(sibling_cell_index,sibling_cell_orientation)
	sibling_prototype.add_sibling(direction * VECTOR_INVERSE,cell_index,cell_orientation)

#func append_cell_prototype(coords : Vector3, cell_index: int, cell_orientation: int) -> void:
#
#	var cell_id = "%s_%s" %  [cell_index,cell_orientation]
#	var prototype = get_prototype(cell_id)
#	prototype.weight += 1
#	prototype.cell_index = cell_index
#	prototype.cell_orientation = cell_orientation
#
##	old vertical constraints
#	if not coords.y == 0.0:
#		prototype.constrain_to = ''
#		prototype.constraints.y.to = -1
#
#	if coords.y == 0.0:
#		prototype.constrain_from = ''
#		prototype.constraints.y.from = -1


#func append_cell_sibling(cell_index: int, cell_orientation: int, direction : Vector3, sibling_cell_index: int, sibling_cell_orientation: int) -> void:
#	var cell_id = "%s_%s" %  [cell_index,cell_orientation]
#	var cell_prototype = get_prototype(cell_id)
#	var sibling_cell_id = "%s_%s" %  [sibling_cell_index,sibling_cell_orientation]
#	var sibling_prototype = get_prototype(sibling_cell_id)
#	var direction_name = sibling_directions[direction]
#	var direction_inverse = direction * VECTOR_INVERSE
#	var direction_inverse_name = sibling_directions[direction_inverse]
#	append to sibling and inverse
#	append_protoype_sibling(cell_prototype,direction,sibling_cell_id)
#	append_protoype_sibling(sibling_prototype,direction_inverse,cell_id)
#
#	track_unique_siblings(cell_prototype,direction,sibling_cell_index, sibling_cell_orientation)
#	track_unique_siblings(sibling_prototype,direction,cell_index, cell_orientation)


#func track_unique_siblings(cell_prototype: Dictionary, direction : Vector3, sibling_cell_index: int, sibling_cell_orientation: int):
#	var direction_name = sibling_directions[direction]
#	if not cell_prototype.siblings.has(direction_name):
#		cell_prototype.siblings[direction_name] = {}
#
#	if not cell_prototype.siblings[direction_name].has(sibling_cell_index):
#		cell_prototype.siblings[direction_name][sibling_cell_index] = []
#	if not cell_prototype.siblings[direction_name][sibling_cell_index].has(sibling_cell_orientation):
#		cell_prototype.siblings[direction_name][sibling_cell_index].append(sibling_cell_orientation)


#func append_protoype_sibling(prototype: Dictionary, direction : Vector3, sibling_cell_id: String) -> void:
#	var direction_name = sibling_directions[direction]
#	if not prototype.valid_siblings[direction_name].has(sibling_cell_id):
#		prototype.valid_siblings[direction_name].append(sibling_cell_id)


#func update_symmetry() -> void:
#
#	for id in prototypes:
#		var prototype = get_prototype(id)
#		var direction_symmetry = Vector3.ZERO
#		for direction in sibling_directions:
#			var direction_name = sibling_directions[direction]
#			var direction_inverse = direction * VECTOR_INVERSE
#			var direction_inverse_name = sibling_directions[direction_inverse]
#
#			var siblings = prototype.valid_siblings[direction_name]
#			var inverse_siblings = prototype.valid_siblings[direction_inverse_name]
#			for cell_id in siblings:
#				if inverse_siblings.has(cell_id):
#					direction_symmetry = direction_symmetry.linear_interpolate(direction.abs(), 1.0)
##					direction_symmetry = max(direction_symmetry, abs(direction))
##					print_debug('symmetry (%s): %s %s = %s %s' % [cell_id, direction_name, direction_inverse_name, direction, direction_symmetry])
#
#			prototype.mirror.x = max(prototype.mirror.x,direction_symmetry.x)
#			prototype.mirror.y = max(prototype.mirror.x,direction_symmetry.y)
#			prototype.mirror.z = max(prototype.mirror.x,direction_symmetry.z)


#func get_prototypes() -> Dictionary:
#	return prototypes


# new prototype structure
#{
#	cell_id
#	0 : {
#		orientation
#		0: {
#			directions
#			'left': {
#				siblings
#				-1: [0],
#				0: [0,16,10,22],
#				10: [0,10],
#			}
#		}
#		16:{
#			-1: [0],
#			0: [0,16,10,22],
#			10: [0,10],
#		}
#	}
#	7 : {
#		0: {
#			-1: [0],
#			0: [0,16,10,22],
#			10: [0,10],
#		}
#		16:{
#			-1: [0],
#			0: [0,16,10,22],
#			10: [0,10],
#		}
#	}
#}
