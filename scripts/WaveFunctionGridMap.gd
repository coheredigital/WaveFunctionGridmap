tool
extends GridMap
class_name WaveFunctionGridMap

const FILE_PROTOTYPES = "res://resources/prototypes.json"
const FILE_CELLS = "res://resources/cells.json"
const FILE_SOCKETS = "res://resources/sockets.json"
const FILE_REGISTRY = "res://resources/sockets_registry.json"
const FILE_TEST = "res://resources/test.json"

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions

var template : WaveFunctionTemplateResource

var orientations = [0,22,10,16]

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
	template = WaveFunctionTemplateResource.new()
	structure = {}
	var used_cells := get_used_cells()

	for coords in used_cells:
		var cell_index := get_cell_item(coords.x,coords.y,coords.z)
		var cell_orientation := get_cell_item_orientation(coords.x,coords.y,coords.z)
		var normalized_cell_orientation = 0
		var normalized_directions : Dictionary = orientation_directions[cell_orientation]

		if not structure.has(cell_index):
			structure[cell_index] = {}

		var cell = structure[cell_index];

		for direction in normalized_directions:
#
			var oriented_direction = normalized_directions[direction]
			var sibling_coords = coords + oriented_direction
			var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var normalized_sibling_cell_orientation = get_normalized_orientation(cell_orientation, sibling_cell_orientation)
			var normalized_direction_name = direction_names[direction]

			if not cell.has(normalized_direction_name):
				cell[normalized_direction_name] = {}

			if not cell[normalized_direction_name].has(sibling_cell_index):
				cell[normalized_direction_name][sibling_cell_index] = []

			if not cell[normalized_direction_name][sibling_cell_index].has(normalized_sibling_cell_orientation):
				cell[normalized_direction_name][sibling_cell_index].append(normalized_sibling_cell_orientation)


	var file = File.new()
	file.open(FILE_TEST, File.WRITE)
	file.store_line(to_json(structure))
	file.close()

#	print("Generated prototype: %s cells in use." % used_cells.size())


func update_sockets() -> void:
	var sockets := {}

	var used_cells := get_used_cells()

	for coords in used_cells:
		var cell_index := get_cell_item(coords.x,coords.y,coords.z)
		var cell_orientation := get_cell_item_orientation(coords.x,coords.y,coords.z)

		for direction in direction_names:
			var sibling_coords = coords + direction
			var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)

			register_cell_sibling(cell_index, cell_orientation, direction, sibling_cell_index, sibling_cell_orientation)

#		var normalized_cell_orientation = 0
#		var normalized_directions : Dictionary = orientations[cell_orientation]

#		if not structure.has(cell_index):
#			structure[cell_index] = {}
#
#		var cell = structure[cell_index];
#
#		if not cell.has(normalized_cell_orientation):
#			cell[normalized_cell_orientation] = {}
#
#		var orientation = cell[normalized_cell_orientation]
#
#		for direction in normalized_directions:
#
#			var oriented_direction = normalized_directions[direction]
#			var sibling_coords = coords + oriented_direction
#			var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
#			var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
#			var normalized_sibling_cell_orientation = get_normalized_orientation(cell_orientation, sibling_cell_orientation)
#			var oriented_direction_name = sibling_directions[direction]
#
#			if not orientation.has(oriented_direction_name):
#				orientation[oriented_direction_name] = {}
#
#			if not orientation[oriented_direction_name].has(sibling_cell_index):
#				orientation[oriented_direction_name][sibling_cell_index] = []
#
#			if not orientation[oriented_direction_name][sibling_cell_index].has(normalized_sibling_cell_orientation):
#				orientation[oriented_direction_name][sibling_cell_index].append(normalized_sibling_cell_orientation)


#	var file = File.new()
#	file.open(FILE_TEST, File.WRITE)
#	file.store_line(to_json(structure))
#	file.close()


func register_cell_sibling(cell_index: int, cell_orientation: int, direction: Vector3, sibling_cell_index: int, sibling_cell_orientation: int) -> void:

	var normalized_sibling_cell_orientation = get_normalized_orientation(cell_orientation, sibling_cell_orientation)

	if not structure.has(cell_index):
		structure[cell_index] = {}

	var cell = structure[cell_index];

	for o in orientation_directions:
#		var oriented_directions = orientation_directions[o]
		var orient = get_normalized_orientation(o, normalized_sibling_cell_orientation)
		var oriented_directions := get_normalized_directions(orient)
		var normalized_direction := get_normalized_direction(orient,direction)
		var direction_name = direction_names[direction]
		var normalized_direction_name = direction_names[normalized_direction]

		if not cell.has(o):
			cell[o] = {}
#
		var orientation = cell[o]
#
		if not orientation.has(normalized_direction_name):
			orientation[normalized_direction_name] = {}

		if not orientation[normalized_direction_name].has(sibling_cell_index):
			orientation[normalized_direction_name][sibling_cell_index] = []


func set_clear_canvas(value : bool) -> void:
	if not value:
		return
	clear()


func set_export_definitions(value : bool) -> void:
	if not value:
		return
	print('Update Protypes!')
	update_prototypes()
	update_sockets()
#	save_json()


func save_json() -> void:
	var file_prototypes = File.new()
	var prototype_data = {}
	for id in template.prototypes:
		prototype_data[id] = template.prototypes[id].get_dictionary()
	file_prototypes.open(FILE_PROTOTYPES, File.WRITE)
	file_prototypes.store_line(to_json(prototype_data))
	file_prototypes.close()

	var file_sockets = File.new()
	var sockets = {
		'prototypes' : template.prototype_sockets,
		'cells' : template.sockets,
		'registry' : template.socket_registry
	}
	file_sockets.open(FILE_SOCKETS, File.WRITE)
	file_sockets.store_line(to_json(sockets))
	file_sockets.close()

	var file_registry = File.new()
	file_registry.open(FILE_REGISTRY, File.WRITE)
	file_registry.store_line(to_json(template.socket_registry))
	file_registry.close()

#	var file_cells = File.new()
#	file_cells.open(FILE_PROTOTYPES, File.WRITE)
#	file_cells.store_line(to_json(template.cells))
#	file_cells.close()
