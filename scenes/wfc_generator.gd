# A little test combining Martin Donald's work with WFC with Godots Gridmap
tool
extends GridMap

const FILE_NAME = "res://resources/prototypes.json"

export var save_name : String
export var prototype_data : Resource
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
	var cell_list := mesh_library.get_item_list()
	var default_cell_data := {
			'count' : 0,
			'valid_siblings': {}
		}


	var cells := get_used_cells()
	for cell_coordinates in cells:

		var cell_index := get_cell_item(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_orientation := get_cell_item_orientation(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_id = "%s_%s" %  [cell_index,cell_orientation]

		if not prototypes.has(cell_id):
			prototypes[cell_id] = default_cell_data.duplicate()


		var cell_prototype = prototypes[cell_id]
		var valid_siblings : Dictionary = cell_prototype.valid_siblings
		cell_prototype.count += 1

#		check valid nearby cells
		for offset in siblings_offsets:
			var offset_name = siblings_offsets[offset]
			var cell_offset = cell_coordinates + offset
			var sibling_cell = get_cell_item(cell_offset.x, cell_offset.y, cell_offset.z)
			var sibling_cell_orientation = get_cell_item_orientation(cell_offset.x, cell_offset.y, cell_offset.z)

#			init sibling dictionary
			if not offset_name in valid_siblings:
				valid_siblings[offset_name] = {}

			var cell_valid_siblings = valid_siblings[offset_name]
			var sibling_cell_id = "%s_%s" %  [sibling_cell,sibling_cell_orientation]
#			init valid sibling / orientation

			if not cell_valid_siblings.has(sibling_cell_id):
				cell_valid_siblings[sibling_cell_id] = {
					'cell' : sibling_cell,
					'orientation' : sibling_cell_orientation,
				}


	prototype_data.prototypes = prototypes


func set_export_definitions(value : bool) -> void:
	update_prototypes()

