tool
extends GridMap
class_name WaveFunctionGridMapTemplate


const FILE_PATH = "res://resources/prototypes.json"
const FILE_CELLS = "res://resources/cells.json"
const FILE_TEST = "res://resources/test.json"
const valid_orientations = [0,22,10,16]
const BLANK_ID = "-1:-1"
const VECTOR_INVERSE = Vector3(-1.0,-1.0,-1.0)
const DEFAULT_PROTOTYPE = {
	'cell_index': -1,
	'cell_orientation': -1,
	'weight' : 0,
	'valid_siblings': {
		Vector3.FORWARD: [],
		Vector3.RIGHT: [],
		Vector3.BACK: [],
		Vector3.LEFT: [],
		Vector3.UP : [],
		Vector3.DOWN : []
	},
	'used_coordinates': [],
	'constraints': {
		'x': {
			'to': -1,
			'from': -1,
		},
		'y': {
			'to': -1,
			'from': -1,
		},
		'z': {
			'to': -1,
			'from': -1,
		}
	}
}
const orientation_directions = {
	-1: {
		Vector3.FORWARD: Vector3.FORWARD,
		Vector3.RIGHT: Vector3.RIGHT,
		Vector3.BACK: Vector3.BACK,
		Vector3.LEFT: Vector3.LEFT,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
	0: {
		Vector3.FORWARD: Vector3.FORWARD,
		Vector3.RIGHT: Vector3.RIGHT,
		Vector3.BACK: Vector3.BACK,
		Vector3.LEFT: Vector3.LEFT,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
	22: {
		Vector3.FORWARD: Vector3.RIGHT,
		Vector3.RIGHT: Vector3.BACK,
		Vector3.BACK: Vector3.LEFT,
		Vector3.LEFT: Vector3.FORWARD,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
	10: {
		Vector3.FORWARD: Vector3.BACK,
		Vector3.RIGHT: Vector3.LEFT,
		Vector3.BACK: Vector3.FORWARD,
		Vector3.LEFT: Vector3.RIGHT,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
	16: {
		Vector3.FORWARD: Vector3.LEFT,
		Vector3.RIGHT: Vector3.FORWARD,
		Vector3.BACK: Vector3.RIGHT,
		Vector3.LEFT: Vector3.BACK,
		Vector3.UP : Vector3.UP,
		Vector3.DOWN : Vector3.DOWN
	},
}

var blank_prototype : Dictionary
var cells : WaveFunctionCells

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions
export var prototypes : Dictionary


class WaveFunctionCells:
	var collection : Dictionary
	func get_cell(index: int) -> WaveFunctionCell:
		if not collection.has(index):
			collection[index] = WaveFunctionCell.new(index)
		return collection[index]


class WaveFunctionCell:
	var index : int
	var valid_siblings = {
		Vector3.FORWARD: {},
		Vector3.RIGHT: {},
		Vector3.BACK: {},
		Vector3.LEFT: {},
		Vector3.UP : {},
		Vector3.DOWN : {}
	}
	var used_coords : Array = []

	func _init(cell_index: int):
		index = cell_index

	func append_sibling(direction: Vector3, index: int, orientation:int):
		if not valid_siblings[direction].has(index):
			valid_siblings[direction][index] = []
		if not valid_siblings[direction][index].has(orientation):
			valid_siblings[direction][index].append(orientation)

	func append_coords(coords: Vector3):
		if not used_coords.has(coords):
			used_coords.append(coords)

func get_normalized_direction(cell_orientation: int, direction: Vector3) -> Vector3:
	var normalized_directions = orientation_directions[cell_orientation]
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


func rotate_orientation(parent_orientation: int, cell_orientation: int) -> int:
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


func initialize():
	update_cells()
	update_prototypes()

func update_cells() -> void:
	prototypes = {
		BLANK_ID : DEFAULT_PROTOTYPE.duplicate(true)
	}
	blank_prototype = prototypes[BLANK_ID]
	var directions = orientation_directions[0]

	cells = WaveFunctionCells.new()

	var used_cells := get_used_cells()
	for coords in used_cells:
		var cell_index : int = get_cell_item(coords.x,coords.y,coords.z)
		var cell_orientation : int = get_cell_item_orientation(coords.x,coords.y,coords.z)

		cells.get_cell(cell_index).append_coords(coords)
		append_coords(coords)
	build_constraints()



func update_prototypes() -> void:
	prototypes = {
		BLANK_ID : DEFAULT_PROTOTYPE.duplicate(true)
	}

	for index in cells.collection:
		var cell = cells.collection[index]
		for orientation in valid_orientations:
			var prototype_id = '%s:%s' % [index,orientation]
			if index == -1:
				prototype_id = BLANK_ID
			if not prototypes.has(prototype_id):
				prototypes[prototype_id] = DEFAULT_PROTOTYPE.duplicate(true)
				prototypes[prototype_id]['cell_index'] = index
				prototypes[prototype_id]['cell_orientation'] = orientation

#			only run on default orientation for BLANK
			if index == -1 and orientation != 0:
				continue

			for direction in cell.valid_siblings:
				var normalized_direction = get_normalized_direction(orientation,direction)
				for sibling_index in cell.valid_siblings[direction]:
					for sibling_orientation in cell.valid_siblings[direction][sibling_index]:
						var rotated_sibling_orientation = rotate_orientation(orientation,sibling_orientation)
						var sibling_id = '%s:%s' % [sibling_index,rotated_sibling_orientation]
						if not prototypes[prototype_id]['valid_siblings'][normalized_direction].has(sibling_id):
							prototypes[prototype_id]['valid_siblings'][normalized_direction].append(sibling_id)



func get_blank_cell() -> WaveFunctionCell:
	var blank_cell = cells.get_cell(-1)
	for direction in orientation_directions[0]:
		blank_cell.append_sibling(direction,-1,-1)
	return blank_cell


func append_coords(coords:Vector3):
	var cell_index : int = get_cell_item(coords.x,coords.y,coords.z)
	var cell_orientation : int = get_cell_item_orientation(coords.x,coords.y,coords.z)
	var blank_cell = get_blank_cell()
	var normalized_directions : Dictionary = orientation_directions[cell_orientation]

	for direction in normalized_directions:
		var oriented_direction = normalized_directions[direction]
		var sibling_coords = coords + oriented_direction
		var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
		var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
		sibling_cell_orientation = normalize_orientation(cell_orientation, sibling_cell_orientation)

#		append cell
		cells.get_cell(cell_index).append_sibling(direction,sibling_cell_index,sibling_cell_orientation)
#		detect and track null siblings cells
		if sibling_cell_index == -1:
			blank_cell.append_sibling(oriented_direction * VECTOR_INVERSE,cell_index,cell_orientation)



func build_constraints() -> void:
	for cell_id in prototypes:
		var prototype = prototypes[cell_id]
		var y_coords : Array = [];
		for coord in prototype['used_coordinates']:
			y_coords.append(coord.y)
#		cell only ever found on bottom
		if y_coords.max() == 0  and y_coords.min() == 0:
			prototype['constraints']['y']['to'] = 0
#		cell NEVER found on bottom
		if not 0 in y_coords:
			prototype['constraints']['y']['from'] = 0


func set_clear_canvas(value : bool) -> void:
	if not value:
		return
	clear()


func set_export_definitions(value : bool) -> void:
	if not value:
		return
	print('Update Protypes!')
	initialize()

#	save to JSON for viewing only
	export_prototypes()

#	export cells
	export_cells()



func export_prototypes() -> void:
	var file = File.new()
	file.open(FILE_PATH, File.WRITE)
	file.store_line(to_json(prototypes))
	file.close()


func export_cells() -> void:
	var cells_data = {}
	for index in cells.collection:
		var cell : WaveFunctionCell = cells.collection[index]
		if not cells_data.has(index):
			cells_data[index] = {
				'siblings': cell.valid_siblings,
				'coords': cell.used_coords
			}
	var file_cells = File.new()
	file_cells.open(FILE_CELLS, File.WRITE)
	file_cells.store_line(to_json(cells_data))
	file_cells.close()
