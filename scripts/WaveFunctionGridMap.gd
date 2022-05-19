tool
extends GridMap
class_name WaveFunctionGridMap


const FILE_PROTOTYPES = "res://resources/prototypes.json"
const FILE_CELLS = "res://resources/cells.json"
const FILE_SOCKETS = "res://resources/sockets.json"
const FILE_REGISTRY = "res://resources/sockets_registry.json"
const FILE_TEST = "res://resources/test.json"
const orientation_directions = {
	0 : {
		Vector3.FORWARD: Vector3.FORWARD,
		Vector3.RIGHT: Vector3.RIGHT,
		Vector3.BACK: Vector3.BACK,
		Vector3.LEFT: Vector3.LEFT,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
	22 : {
		Vector3.FORWARD: Vector3.RIGHT,
		Vector3.RIGHT: Vector3.BACK,
		Vector3.BACK: Vector3.LEFT,
		Vector3.LEFT: Vector3.FORWARD,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
	10 : {
		Vector3.FORWARD: Vector3.BACK,
		Vector3.RIGHT: Vector3.LEFT,
		Vector3.BACK: Vector3.FORWARD,
		Vector3.LEFT: Vector3.RIGHT,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
	16 : {
		Vector3.FORWARD: Vector3.LEFT,
		Vector3.RIGHT: Vector3.FORWARD,
		Vector3.BACK: Vector3.RIGHT,
		Vector3.LEFT: Vector3.BACK,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
}

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions
var prototypes : Dictionary

func get_normalized_directions(cell_orientation: int) -> Dictionary:
	match cell_orientation:
		22: # Right (90)
			return  {
				Vector3.FORWARD: Vector3.RIGHT,
				Vector3.RIGHT: Vector3.BACK,
				Vector3.BACK: Vector3.LEFT,
				Vector3.LEFT: Vector3.FORWARD,
				Vector3.UP : Vector3.UP,
				Vector3.DOWN : Vector3.DOWN
			}
		10: # Back (180)
			return  {
				Vector3.FORWARD: Vector3.BACK,
				Vector3.RIGHT: Vector3.LEFT,
				Vector3.BACK: Vector3.FORWARD,
				Vector3.LEFT: Vector3.RIGHT,
				Vector3.UP : Vector3.UP,
				Vector3.DOWN : Vector3.DOWN
			}
		16: # Left (270)
			return  {
				Vector3.FORWARD: Vector3.LEFT,
				Vector3.RIGHT: Vector3.FORWARD,
				Vector3.BACK: Vector3.RIGHT,
				Vector3.LEFT: Vector3.BACK,
				Vector3.UP : Vector3.UP,
				Vector3.DOWN : Vector3.DOWN
			}
		_: # Forward ( 0:default)
			return {
				Vector3.FORWARD: Vector3.FORWARD,
				Vector3.RIGHT: Vector3.RIGHT,
				Vector3.BACK: Vector3.BACK,
				Vector3.LEFT: Vector3.LEFT,
				Vector3.UP : Vector3.UP,
				Vector3.DOWN : Vector3.DOWN
			}


func get_normalized_direction(cell_orientation: int, direction: Vector3) -> Vector3:
	var normalized_directions = get_normalized_directions(cell_orientation)
	return normalized_directions[direction]


#class WaveFunctionPrototypes:
#	var list = {}
#
#	func get_cell(cell_index:int) -> WaveFunctionPrototype:
#		if not list.has(cell_index):
#			list[cell_index] = WaveFunctionPrototype.new(cell_index)
#		return list[cell_index]
#
#	func get_dictionary() -> Dictionary:
#		var data = {}
#		for cell_index in list:
#			var current_cell : WaveFunctionCell = get_cell(cell_index)
#			data[cell_index] = current_cell.get_dictionary()
#		return data


class WaveFunctionPrototype:
	const valid_orientations = [0,22,10,16]
	var index : int
	var sockets = WaveFunctionSockets
	var used_coordinates = []

	func _init(cell_index:int):
		index = cell_index
		sockets = WaveFunctionSockets.new()

	func register_socket(direction: Vector3, sibling_cell_index: int, sibling_cell_orientation : int ):
		var socket : WaveFunctionSocket  = sockets.get_socket(direction)
		socket.append_sibling(sibling_cell_index,sibling_cell_orientation)

	func track_coords(coords: Vector3):
		if not used_coordinates.has(coords):
			used_coordinates.append(coords)

	func get_dictionary() -> Dictionary:
		var data = {
			'valid_orientations': valid_orientations,
			'used_coordinates': used_coordinates,
			'weight': len(used_coordinates),
			'valid_siblings': sockets.get_dictionary()
		}
		return data


class WaveFunctionSockets:

	var directions = {
		Vector3.FORWARD : WaveFunctionSocket.new(),
		Vector3.BACK : WaveFunctionSocket.new(),
		Vector3.LEFT : WaveFunctionSocket.new(),
		Vector3.RIGHT : WaveFunctionSocket.new(),
		Vector3.UP : WaveFunctionSocket.new(),
		Vector3.DOWN : WaveFunctionSocket.new()
	}

	func get_socket(direction: Vector3) -> WaveFunctionSocket:
		return directions[direction]

	func get_dictionary() -> Dictionary:
		var data = {}
		for direction in directions:
			var direction_name = direction_names[direction]
			var socket = directions[direction]
			data[direction_name] = socket.get_dictionary()
		return data


class WaveFunctionSocket:
	var siblings = {}
	func append_sibling(sibling_cell_index: int, sibling_cell_orientation: int):
		if not siblings.has(sibling_cell_index):
			siblings[sibling_cell_index] = []
		if not siblings[sibling_cell_index].has(sibling_cell_orientation):
			siblings[sibling_cell_index].append(sibling_cell_orientation)

	func get_dictionary() -> Dictionary:
		return siblings


const direction_names = {
	Vector3.RIGHT : 'right',
	Vector3.FORWARD : 'forward',
	Vector3.LEFT : 'left',
	Vector3.BACK : 'back',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down'
}

var structure := {}


func get_normalized_orientation(parent_orientation: int, cell_orientation: int) -> int:
	match parent_orientation:
		22:
			match cell_orientation:
				0:
					return 16
				22:
					return 0
				10:
					return 22
				16:
					return 10
		10:
			match cell_orientation:
				0:
					return 10
				22:
					return 16
				10:
					return 0
				16:
					return 22
		16:
			match cell_orientation:
				0:
					return 22
				22:
					return 10
				10:
					return 16
				16:
					return 0

	return cell_orientation


func get_offset_orientation(original_orientation: int, offset_orientation: int) -> int:
	match offset_orientation:
		22:
			match original_orientation:
				0:
					return 22
				22:
					return 10
				10:
					return 16
				16:
					return 0
		10:
			match original_orientation:
				0:
					return 10
				22:
					return 16
				10:
					return 0
				16:
					return 22
		16:
			match original_orientation:
				0:
					return 16
				22:
					return 0
				10:
					return 22
				16:
					return 10

	return original_orientation


func update_prototypes() -> void:
	prototypes = {}

	var used_cells := get_used_cells()

	for coords in used_cells:
		var cell_index : int = get_cell_item(coords.x,coords.y,coords.z)
		var cell_orientation : int = get_cell_item_orientation(coords.x,coords.y,coords.z)

		if not prototypes.has(cell_index):
			prototypes[cell_index] = WaveFunctionPrototype.new(cell_index)

		var cell : WaveFunctionPrototype = prototypes[cell_index]
		cell.track_coords(coords)

		var normalized_directions : Dictionary = orientation_directions[cell_orientation]

		for direction in normalized_directions:
			var oriented_direction = normalized_directions[direction]
			var sibling_coords = coords + oriented_direction
			var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var normalized_sibling_cell_orientation = get_normalized_orientation(cell_orientation, sibling_cell_orientation)
			cell.register_socket(direction,sibling_cell_index,normalized_sibling_cell_orientation)

#	export to JSON to view structure
	var prototypes_json : Dictionary = {}
	for proto in prototypes:
		prototypes_json[proto] = prototypes[proto].get_dictionary()

	var file = File.new()
	file.open(FILE_PROTOTYPES, File.WRITE)
	file.store_line(to_json(prototypes_json))
	file.close()


func set_clear_canvas(value : bool) -> void:
	if not value:
		return
	clear()


func set_export_definitions(value : bool) -> void:
	if not value:
		return
	print('Update Protypes!')
	update_prototypes()
