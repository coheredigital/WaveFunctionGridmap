# WaveFunctionCells
extends Resource
class_name WaveFunctionTemplateResource

var sockets := {}
var socket_registry := {}
var prototypes := {}
var prototype_sockets := {}

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

	var coordinates : PoolVector3Array

	func get_id(cell_index: int,cell_orientation: int) -> String:
		return "%s_%s" %  [cell_index,cell_orientation]


	func add_coordinates(coords: Vector3) -> void:
#		apply constraints
		if not coords.y == 0.0:
			constrain_to = ''
		if coords.y == 0.0:
			constrain_from = ''
		coordinates.append(coords)


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

	var prototype = prototypes[id]
	prototype.index = cell_index
	prototype.orientation = cell_orientation
	return prototype


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
	var id = "%s_%s" %  [cell_index,cell_orientation]
#	get socket
	prototype.add_coordinates(coords)
	add_sockets(coords, cell_index, cell_orientation)


func add_sockets(coords : Vector3, cell_index: int, cell_orientation: int):

	for socket_direction in sibling_directions:
		if not get_socket_id(cell_index, cell_orientation):
			set_socket_id(coords,socket_direction,prototype_id)

	for direction in sibling_directions:
		var sibling_coords = coords + direction
		var direction_inverse = direction * VECTOR_INVERSE
		var sibling_socket_id = get_socket_id(sibling_coords, direction_inverse)

#	prototype_sockets[prototype_id] = sockets[coords]


func get_socket_id(coords: Vector3, direction: Vector3):
	if not sockets.has(coords):
		return ''
	var socket = sockets[coords]
	if not socket.has(direction):
		return ''
	return socket[direction]



func set_socket_id(coords: Vector3, direction: Vector3, id: String):

	var default_sockets = {
		Vector3.FORWARD : 'F%s' % id,
		Vector3.BACK : 'B%s' % id,
		Vector3.LEFT : 'L%s' % id,
		Vector3.RIGHT : 'R%s' % id,
		Vector3.UP : 'U%s' % id,
		Vector3.DOWN : 'D%s' % id
	}

	var socket_id = default_sockets[direction]

	if not sockets.has(coords):
		sockets[coords] = default_sockets.duplicate()

	var socket = sockets[coords]
	if not socket.has(direction):
		socket[direction] = default_sockets[direction]

	if not socket_registry.has(socket_id):
		socket_registry[socket_id] = {
			Vector3.FORWARD : [],
			Vector3.BACK : [],
			Vector3.LEFT : [],
			Vector3.RIGHT : [],
			Vector3.UP : [],
			Vector3.DOWN : []
		}

	if not socket_registry[socket_id][direction].has(id):
		socket_registry[socket_id][direction].append(id)


func add_prototype_sibling(cell_index: int, cell_orientation: int, direction : Vector3, sibling_cell_index: int, sibling_cell_orientation: int):
	var prototype := get_prototype(cell_index,cell_orientation)
	prototype.add_sibling(direction,sibling_cell_index,sibling_cell_orientation)
#	add inverse relationship
	var sibling_prototype := get_prototype(sibling_cell_index,sibling_cell_orientation)
	sibling_prototype.add_sibling(direction * VECTOR_INVERSE,cell_index,cell_orientation)

	var id = "%s_%s" %  [cell_index,cell_orientation]
	var sibling_id = "%s_%s" %  [sibling_cell_index,sibling_cell_orientation]
