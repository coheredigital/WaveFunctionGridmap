# A little test combining Martin Donald's work with WFC with Godots Gridmap
tool
extends GridMap

const FILE_NAME = "res://resources/prototypes.json"

export var clear_canvas : bool setget set_clear_canvas
export var resource_file : Resource
var prototypes := {}

var wave_function : Array  # Grid of cells containing prototypes
var cell_states := {}
var stack : Array
var bounds : AABB

export var export_definitions : bool = false setget set_export_definitions

enum CellStates {
	READY,
	COLLAPSED = -2
}


var siblings_offsets = {
	Vector3.RIGHT : 'right',
	Vector3.FORWARD : 'forward',
	Vector3.LEFT : 'left',
	Vector3.BACK : 'back',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down'
}

var siblings_index = {
	Vector3.RIGHT : 0,
	Vector3.FORWARD : 1, # should be 3?
	Vector3.LEFT : 2,
	Vector3.BACK : 3, # should be 1?
	Vector3.UP : 4,
	Vector3.DOWN : 5
}


func update_prototypes() -> void:
	#	initialize cell list
	var cells := get_used_cells()
	print("Generate prototype: START")
	print("used cells: %s" % cells.size() )

	var blank_prototype = {
		'count' : 0,
		'valid_siblings_dictionary': {},
		'cell_index': -1,
		'cell_orientation': 0,
	}

	for cell_coordinates in cells:

		var cell_index := get_cell_item(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_orientation := get_cell_item_orientation(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_id = "%s_%s" %  [cell_index,cell_orientation]
		var valid_siblings = {}

		if not prototypes.has(cell_id):
			prototypes[cell_id] = {
			'count' : 0,
			'valid_siblings_dictionary': {},
			'cell_index': cell_index,
			'cell_orientation': cell_orientation,
		}


		var cell_prototype = prototypes[cell_id]
		cell_prototype.count += 1

#		check valid nearby cells
		for offset in siblings_offsets:
			var offset_name = siblings_offsets[offset]
			var cell_offset = cell_coordinates + offset
			var sibling_cell = get_cell_item(cell_offset.x, cell_offset.y, cell_offset.z)
			var sibling_cell_orientation = get_cell_item_orientation(cell_offset.x, cell_offset.y, cell_offset.z)
			var sibling_cell_id = "%s_%s" %  [sibling_cell,sibling_cell_orientation]

			if sibling_cell_id == '-1_-1':
				var offset_inverse = offset * Vector3(-1.0,-1.0,-1.0)
				var offset_inverse_name = siblings_offsets[offset_inverse]
				if not blank_prototype['valid_siblings_dictionary'].has(offset_inverse_name):
					blank_prototype['valid_siblings_dictionary'][offset_inverse_name] = []
				if not blank_prototype['valid_siblings_dictionary'][offset_inverse_name].has(cell_id):
					blank_prototype['valid_siblings_dictionary'][offset_inverse_name].append(cell_id)


#			init sibling dictionary
			if not offset_name in cell_prototype.valid_siblings_dictionary:
				cell_prototype.valid_siblings_dictionary[offset_name] = []

			var cell_valid_siblings = cell_prototype.valid_siblings_dictionary[offset_name]

#			init valid sibling / orientation

			if not cell_valid_siblings.has(sibling_cell_id):
#				TODO: may not be needed
				cell_valid_siblings.append(sibling_cell_id)

#		conver valid siblings to arrays only
		for offset_name in valid_siblings:
			cell_prototype.valid_siblings_dictionary.append(valid_siblings[offset_name])


#	add empty prototype
	prototypes['-1_-1'] = blank_prototype

#	convert valid_sibling dictionaries to arrays
	for prototype in prototypes:
		var siblings_copy = prototypes[prototype].valid_siblings_dictionary.duplicate()
		prototypes[prototype].valid_siblings = []
		for direction in siblings_offsets:
			var direction_name = siblings_offsets[direction]
			prototypes[prototype].valid_siblings.append(siblings_copy[direction_name])

#	unset dictionary
	 prototypes[prototype].erase('valid_siblings_dictionary')

#	save
	resource_file.prototypes = prototypes
	save_json()

func save_json() -> void:
	var file = File.new()
	file.open(FILE_NAME, File.WRITE)
	file.store_line(to_json(prototypes))
	file.close()

func set_clear_canvas(value : bool) -> void:
	if not value:
		return
	clear()


func set_export_definitions(value : bool) -> void:
	if not value:
		return
	print('Update Protypes')
	update_prototypes()

