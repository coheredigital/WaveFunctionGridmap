tool
extends GridMap
class_name WaveFunctionGridMapTemplate


const FILE_PATH = "res://resources/prototypes.json"
const valid_orientations = [0,22,10,16]
const BLANK_ID = "-1:-1"
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

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions


export var prototypes : Dictionary



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


export var cells : Dictionary = {}


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
	prototypes = {
		BLANK_ID : DEFAULT_PROTOTYPE.duplicate(true)
	}
	var blank_prototype = prototypes[BLANK_ID]
	var directions = orientation_directions[0]
#	default blank can always have blank as sibling
#	for direction in directions:
#		blank_prototype['valid_siblings'][direction].append(BLANK_ID)


	cells = {}
	var used_cells := get_used_cells()
	for coords in used_cells:
		append_cell(coords)
	build_constraints()

func append_cell(coords:Vector3):

	var cell_index : int = get_cell_item(coords.x,coords.y,coords.z)
	var cell_orientation : int = get_cell_item_orientation(coords.x,coords.y,coords.z)
	var cell_id = "%s:%s" % [cell_index,cell_orientation]

#	create default orientations
	for orientation in valid_orientations:
		var orientation_cell_id = "%s:%s" % [cell_index,orientation]
		if not prototypes.has(orientation_cell_id):
			prototypes[orientation_cell_id] = DEFAULT_PROTOTYPE.duplicate(true)
		var orientation_prototype = prototypes[orientation_cell_id]
		orientation_prototype['cell_index'] = cell_index
		orientation_prototype['cell_orientation'] = orientation
		orientation_prototype['weight'] += 1

	#	track used coords on cell_index basis, for each possible orientation
		if not orientation_prototype['used_coordinates'].has(coords):
			orientation_prototype['used_coordinates'].append(coords)

	var normalized_directions : Dictionary = orientation_directions[cell_orientation]

	for direction in normalized_directions:
		var oriented_direction = normalized_directions[direction]
		var sibling_coords = coords + oriented_direction
		var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
		var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
		sibling_cell_orientation = normalize_orientation(cell_orientation, sibling_cell_orientation)
		append_cell_sibling(cell_index, direction, sibling_cell_index, sibling_cell_orientation)


func append_cell_sibling(cell_index: int, direction: Vector3, sibling_cell_index: int, sibling_cell_orientation: int):
	if not cells.has(cell_index):
		cells[cell_index] = {}
	for orientation in valid_orientations:
		var cell_id = "%s:%s" % [cell_index,orientation]
		var prototype = prototypes[cell_id]
		var normalized_direction = get_normalized_direction(orientation,direction)
		var normalized_sibling_orientation = normalize_orientation(orientation,sibling_cell_orientation)
		var sibling_cell_id = "%s:%s" % [sibling_cell_index,normalized_sibling_orientation]
		if not prototype['valid_siblings'][normalized_direction].has(sibling_cell_id):
			prototype['valid_siblings'][normalized_direction].append(sibling_cell_id)


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
	update_prototypes()
#	save to JSON for viewing only
	var file = File.new()
	file.open(FILE_PATH, File.WRITE)
	file.store_line(to_json(prototypes))
	file.close()
