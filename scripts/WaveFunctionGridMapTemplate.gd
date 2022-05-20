tool
extends GridMap
class_name WaveFunctionGridMapTemplate


const FILE_PATH = "res://resources/prototypes.json"
const valid_orientations = [0,22,10,16]
const NULL_CELL_ID = "-1:-1"
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
		append_cell(coords)


func append_cell(coords:Vector3):

	var cell_index : int = get_cell_item(coords.x,coords.y,coords.z)
	var cell_orientation : int = get_cell_item_orientation(coords.x,coords.y,coords.z)
	var cell_id = "%s:%s" % [cell_index,cell_orientation]

	if not cells.has(cell_index):
		cells[cell_index] = {}

#	create default orientations
	for orientation in valid_orientations:
		var orientation_cell_id = "%s:%s" % [cell_index,orientation]
		if not prototypes.has(orientation_cell_id):
			prototypes[orientation_cell_id] = {
				'weight': 0,
				'valid_siblings': {
					Vector3.FORWARD: [],
					Vector3.RIGHT: [],
					Vector3.BACK: [],
					Vector3.LEFT: [],
					Vector3.UP : [],
					Vector3.DOWN : []
				},
				'used_coordinates': [],
			}


	var normalized_directions : Dictionary = get_normalized_directions(cell_orientation)

	for direction in normalized_directions:
		var oriented_direction = normalized_directions[direction]
		var sibling_coords = coords + oriented_direction
		var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
		var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
		sibling_cell_orientation = normalize_orientation(cell_orientation, sibling_cell_orientation)
		append_cell_sibling(cell_index, direction, sibling_cell_index, sibling_cell_orientation)

	var cell_prototype = prototypes[cell_id]

#	track used coords
	if not cell_prototype['used_coordinates'].has(coords):
		cell_prototype['used_coordinates'].append(coords)


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
