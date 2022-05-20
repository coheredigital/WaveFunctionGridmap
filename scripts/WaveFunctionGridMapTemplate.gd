tool
extends GridMap
class_name WaveFunctionGridMapTemplate


const FILE_PROTOTYPES = "res://resources/prototypes.json"
const FILE_CELLS = "res://resources/cells.json"
const FILE_SOCKETS = "res://resources/sockets.json"
const FILE_REGISTRY = "res://resources/sockets_registry.json"
const FILE_TEST = "res://resources/test.json"
const valid_orientations = [0,22,10,16]
const normalized_directions = {
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


func normalize_orientation(parent_orientation: int, cell_orientation: int) -> int:
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


export var cells : Dictionary = {}

func append_cell(cell_index: int):
	if not cells.has(cell_index):
		cells[cell_index] = {}

func append_cell_sibling(cell_index: int, direction: Vector3, sibling_cell_index: int, sibling_cell_orientation: int):
	if not cells.has(cell_index):
		cells[cell_index] = {}

	for orientation in valid_orientations:
		var oriented_siblings = {}
		var oriented_valid_siblings = {}
		var normalized_direction = get_normalized_direction(orientation,direction)
		var normalized_sibling_orientation = normalize_orientation(orientation,sibling_cell_orientation)

		if not cells[cell_index].has(orientation):
			cells[cell_index][orientation] = {}

		if not cells[cell_index][orientation].has(normalized_direction):
			cells[cell_index][orientation][normalized_direction] = []

		if not cells[cell_index][orientation][normalized_direction].has(normalized_sibling_orientation):
			cells[cell_index][orientation][normalized_direction].append(normalized_sibling_orientation)


class WaveFunctionPrototype:
	var valid_orientations = [0,22,10,16]
	var index : int
	var sockets = WaveFunctionSockets
	var orientations := {}
	var used_coordinates = []

	func normalize_orientation(parent_orientation: int, cell_orientation: int) -> int:
		match parent_orientation:
			22:
				match cell_orientation:
					0:
						return 22
					22:
						return 10
					10:
						return 16
					16:
						return 0
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
						return 16
					22:
						return 0
					10:
						return 22
					16:
						return 10

		return cell_orientation

	func _init(cell_index:int):
		index = cell_index
		sockets = WaveFunctionSockets.new()

	func register_sibling(direction: Vector3, sibling_cell_index: int, sibling_cell_orientation : int ):

		var sibling : WaveFunctionSocket  = sockets.get_socket(direction)
		sibling.append_cell(sibling_cell_index,sibling_cell_orientation)

		for orientation in valid_orientations:
			var oriented_siblings = {}
			var oriented_directions = normalized_directions[orientation]
			var oriented_valid_siblings = {}

			for direction in sockets.directions:
				var socket : WaveFunctionSocket = sockets.directions[direction]
				var oriented_direction = oriented_directions[direction]
				var oriented_sibling_prototype = {}
				for sibling_cell_index in socket.siblings:
					var sibling_cell_orientations = socket.siblings[sibling_cell_index]
					var normalized_sibling_orientations = []
					for orient in sibling_cell_orientations:
						var normalized_orientation = normalize_orientation(orientation,orient)
						normalized_sibling_orientations.append(normalized_orientation)
					oriented_sibling_prototype[sibling_cell_index] = normalized_sibling_orientations
				oriented_valid_siblings[oriented_direction] = oriented_sibling_prototype
			orientations[orientation] = oriented_valid_siblings


	func track_coords(coords: Vector3):
		if not used_coordinates.has(coords):
			used_coordinates.append(coords)


	func get_dictionary() -> Dictionary:

		var orientation_variations = {}
		var valid_siblings = sockets.get_dictionary()

		for orientation in valid_orientations:

			var oriented_siblings = {}
			var oriented_directions = normalized_directions[orientation]
			var oriented_valid_siblings = {}

			for direction in valid_siblings:
				var sibling_prototype = valid_siblings[direction]
				var oriented_direction = oriented_directions[direction]
				var oriented_sibling_prototype = {}
				for sibling_cell_index in sibling_prototype:
					var sibling_cell_orientations = sibling_prototype[sibling_cell_index]
					var normalized_sibling_orientations = []
					for orient in sibling_cell_orientations:
						var normalized_orientation = normalize_orientation(orientation,orient)
						normalized_sibling_orientations.append(normalized_orientation)
					oriented_sibling_prototype[sibling_cell_index] = normalized_sibling_orientations

				oriented_valid_siblings[oriented_direction] = oriented_sibling_prototype

			orientation_variations[orientation] = oriented_valid_siblings
#
		return {
			'valid_siblings': valid_siblings,
			'used_coordinates': used_coordinates,
			'valid_orientations': orientation_variations,
			'orientations': orientations,
			'weight': len(used_coordinates)
		}


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
			var socket = directions[direction]
			data[direction] = socket.get_dictionary()
		return data


class WaveFunctionSocket:
	var siblings = {}
	func append_cell(sibling_cell_index: int, sibling_cell_orientation: int):
		if not siblings.has(sibling_cell_index):
			siblings[sibling_cell_index] = []
		if not siblings[sibling_cell_index].has(sibling_cell_orientation):
			siblings[sibling_cell_index].append(sibling_cell_orientation)

	func get_dictionary() -> Dictionary:
		return siblings


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
	cells = {}

	var used_cells := get_used_cells()

	for coords in used_cells:
		var cell_index : int = get_cell_item(coords.x,coords.y,coords.z)
		var cell_orientation : int = get_cell_item_orientation(coords.x,coords.y,coords.z)

		append_cell(cell_index)

#		if not prototypes.has(cell_index):
#			prototypes[cell_index] = WaveFunctionPrototype.new(cell_index)

#		var cell : WaveFunctionPrototype = prototypes[cell_index]
#		cell.track_coords(coords)

		var directions : Dictionary = normalized_directions[cell_orientation]

		for direction in directions:
			var oriented_direction = directions[direction]
			var sibling_coords = coords + oriented_direction
			var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var normalized_sibling_cell_orientation = normalize_orientation(cell_orientation, sibling_cell_orientation)
#			cell.register_sibling(direction,sibling_cell_index,normalized_sibling_cell_orientation)
			append_cell_sibling(cell_index, direction, sibling_cell_index, normalized_sibling_cell_orientation)


#	export to JSON to view structure
#	var prototypes_json : Dictionary = {}
#	for proto in prototypes:
#		prototypes_json[proto] = prototypes[proto].get_dictionary()

#	var file = File.new()
#	file.open(FILE_PROTOTYPES, File.WRITE)
#	file.store_line(to_json(prototypes_json))
#	file.close()

	var test_file = File.new()
	test_file.open(FILE_TEST, File.WRITE)
	test_file.store_line(to_json(cells))
	test_file.close()


func update_json() -> void:
	var data = {}

	for cell_index in prototypes:
		var prototype : WaveFunctionPrototype = prototypes[cell_index]


	var file = File.new()
	file.open(FILE_TEST, File.WRITE)
	file.store_line(to_json(data))
	file.close()


func set_clear_canvas(value : bool) -> void:
	if not value:
		return
	clear()


func get_dictionary() -> Dictionary:
	var prototypes_dictionary : Dictionary = {}
	for proto in prototypes:
		prototypes_dictionary[proto] = prototypes[proto].get_dictionary()
	return prototypes_dictionary



func set_export_definitions(value : bool) -> void:
	if not value:
		return
	print('Update Protypes!')
	update_prototypes()
	update_json()
