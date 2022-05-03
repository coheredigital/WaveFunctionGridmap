tool
extends GridMap
class_name WaveFunctionGridMap

const FILE_PROTOTYPES = "res://resources/prototypes.json"
const FILE_CELLS = "res://resources/cells.json"
const FILE_SOCKETS = "res://resources/sockets.json"
const FILE_REGISTRY = "res://resources/sockets_registry.json"

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions

var template : WaveFunctionTemplateResource


const orientations = {
	Vector3.FORWARD: 0,
	Vector3.RIGHT: 22,
	Vector3.BACK: 10,
	Vector3.LEFT: 16
}

const sibling_directions = {
	Vector3.RIGHT : 'right',
	Vector3.FORWARD : 'forward',
	Vector3.LEFT : 'left',
	Vector3.BACK : 'back',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down'
}


func update_prototypes() -> void:
	template = WaveFunctionTemplateResource.new()
	var used_cells := get_used_cells()

	for cell_coordinates in used_cells:
		var cell_index := get_cell_item(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_orientation := get_cell_item_orientation(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		add_cell_prototype(cell_coordinates,cell_index, cell_orientation)

	print_debug("Generated prototype: %s cells in use." % used_cells.size())


func add_cell_prototype(coords: Vector3, cell_index: int, cell_orientation: int):
#	template.append_cell_prototype(coords, cell_index, cell_orientation)
	template.add_prototype(coords,cell_index,cell_orientation)
#	check sibling cells
	for direction in template.sibling_directions:
		var sibling_coords = coords + direction
		var sibling_cell = get_cell_item(sibling_coords.x, sibling_coords.y, sibling_coords.z)
		var sibling_cell_orientation = get_cell_item_orientation(sibling_coords.x, sibling_coords.y, sibling_coords.z)
		template.add_prototype_sibling(cell_index, cell_orientation, direction, sibling_cell, sibling_cell_orientation)



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
	var file_prototypes = File.new()
	var prototype_data = {}
	for id in template.prototypes:
		prototype_data[id] = template.prototypes[id].get_dictionary()
	file_prototypes.open(FILE_PROTOTYPES, File.WRITE)
	file_prototypes.store_line(to_json(prototype_data))
	file_prototypes.close()

	var file_sockets = File.new()
	var sockets = {
		'protypes' : template.prototype_sockets,
		'coords' : template.sockets
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
