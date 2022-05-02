tool
extends GridMap
class_name WaveFunctionGridMap

const FILE_NAME = "res://resources/prototypes.json"

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions

var template : WaveFunctionTemplateResource


func update_prototypes() -> void:

	template = WaveFunctionTemplateResource.new()

	var cells := get_used_cells()
	print_debug("Generate prototype: %s cells in use." % cells.size())

	for cell_coordinates in cells:

		var cell_index := get_cell_item(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_orientation := get_cell_item_orientation(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		template.append_cell_prototype(cell_coordinates, cell_index, cell_orientation)

#		check valid nearby cells
		for direction in template.sibling_directions:
			var sibling_coords = cell_coordinates + direction
			var sibling_cell = get_cell_item(sibling_coords.x, sibling_coords.y, sibling_coords.z)
			var sibling_cell_orientation = get_cell_item_orientation(sibling_coords.x, sibling_coords.y, sibling_coords.z)
			template.append_cell_sibling(cell_index, cell_orientation, direction, sibling_cell, sibling_cell_orientation)
##
#	template.update_symmetry()


func set_clear_canvas(value : bool) -> void:
	if not value:
		return
	clear()


func set_export_definitions(value : bool) -> void:
	if not value:
		return
	print('Update Protypes')
	update_prototypes()
	save_json()


func save_json() -> void:
	var file = File.new()
	file.open(FILE_NAME, File.WRITE)
	file.store_line(to_json(template.prototypes))
	file.close()
