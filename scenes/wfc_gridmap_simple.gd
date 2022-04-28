tool
extends GridMap

var prototypes := {}

export var export_definitions : bool = false setget set_export_definitions


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_export_definitions(value : bool) -> void:

#	initialize cell list
	var cell_list := mesh_library.get_item_list()
	for item in cell_list:
		prototypes[item] = {
			'count' : 0,
			'valid_simblings': []
		}

	var cells := get_used_cells()
	for cell in cells:

		var cell_index := get_cell_item(cell.x,cell.y,cell.z)
		if not prototypes.has(cell_index):
			continue

		var cell_prototype = prototypes[cell_index]

		cell_prototype.count += 1

	print(prototypes)
