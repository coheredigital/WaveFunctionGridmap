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
	Vector3.FORWARD : 'forward',
	Vector3.RIGHT : 'right',
	Vector3.BACK : 'back',
	Vector3.LEFT : 'left',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down',
}


func update_prototypes() -> void:
	#	initialize cell list
	var cells := get_used_cells()
	print("Generate prototype: START")
	print("used cells: %s" % cells.size() )

	var blank_prototype = {
		'count' : 0,
		'valid_siblings': {},
		'cell_index': -1,
		'cell_orientation': 0,
	}

	for cell_coordinates in cells:

		var cell_index := get_cell_item(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_orientation := get_cell_item_orientation(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_id = "%s_%s" %  [cell_index,cell_orientation]


		if not prototypes.has(cell_id):
			prototypes[cell_id] = {
			'count' : 0,
			'valid_siblings': {},
			'cell_index': cell_index,
			'cell_orientation': cell_orientation,
		}


		var cell_prototype = prototypes[cell_id]
		var valid_siblings : Dictionary = cell_prototype.valid_siblings
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
				if not blank_prototype['valid_siblings'].has(offset_inverse_name):
					blank_prototype['valid_siblings'][offset_inverse_name] = []
				if not blank_prototype['valid_siblings'][offset_inverse_name].has(cell_id):
					blank_prototype['valid_siblings'][offset_inverse_name].append(cell_id)
				print(offset_inverse_name)

#			init sibling dictionary
			if not offset_name in valid_siblings:
				valid_siblings[offset_name] = []

			var cell_valid_siblings = valid_siblings[offset_name]

#			init valid sibling / orientation

			if not cell_valid_siblings.has(sibling_cell_id):
#				TODO: may not be needed
				cell_valid_siblings.append(sibling_cell_id)

#	add empty prototype
	prototypes['-1_-1'] = blank_prototype

	resource_file.prototypes = prototypes


func set_clear_canvas(value : bool) -> void:
	if not value:
		return
	clear()


func set_export_definitions(value : bool) -> void:
	if not value:
		return
	print('Update Protypes')
	update_prototypes()

