tool
extends GridMap
class_name WaveFunctionGridMap

const FILE_NAME = "res://resources/prototypes.json"
const FILE_TEST = "res://resources/cells.json"

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions

var template : WaveFunctionTemplateResource


var directions = {
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
#	check valid nearby cells
	for direction in template.sibling_directions:
		var sibling_coords = coords + direction
		var sibling_cell = get_cell_item(sibling_coords.x, sibling_coords.y, sibling_coords.z)
		var sibling_cell_orientation = get_cell_item_orientation(sibling_coords.x, sibling_coords.y, sibling_coords.z)
#		template.append_cell_sibling(cell_index, cell_orientation, direction, sibling_cell, sibling_cell_orientation)
		template.add_prototype_sibling(cell_index, cell_orientation, direction, sibling_cell, sibling_cell_orientation)

# (EDITOR ONLY!) override set cell item to ensure active prototype management
#func set_cell_item(x: int, y: int, z: int, item: int, orientation: int = 0) -> void:
#	.set_cell_item(x, y, z, item, orientation)
#	if Engine.editor_hint:
#		var coords = Vector3(x,y,z)
#		update_prototypes()
#		update_cell_state()


func get_cell_siblings(coords) -> Dictionary:
	var siblings = {}
	for direction in template.sibling_directions:
		var direction_name = sibling_directions[direction]
		var sibling_coords = coords + direction
		var sibling_cell = get_cell_item(sibling_coords.x, sibling_coords.y, sibling_coords.z)
		var sibling_cell_orientation = get_cell_item_orientation(sibling_coords.x, sibling_coords.y, sibling_coords.z)
		if not siblings.has(direction):
			siblings[direction_name] = {}
		if not siblings[direction_name].has(sibling_cell):
			siblings[direction_name][sibling_cell] = []
		if not siblings[direction_name][sibling_cell].has(sibling_cell_orientation):
			siblings[direction_name][sibling_cell].append(sibling_cell_orientation)
	return siblings


func update_cell_state() -> void:
	var cells = {}
	var used_cells := get_used_cells()
	for coords in used_cells:
		var item := get_cell_item(coords.x,coords.y,coords.z)
		var orientation := get_cell_item_orientation(coords.x,coords.y,coords.z)

		#track all cells
		if not cells.has(item):
			 cells[item] = {}

		if not cells[item].has(orientation):
			cells[item][orientation] = {}

		cells[item][orientation] = {
			'siblings': get_cell_siblings(coords)
		}


	var file = File.new()
	file.open(FILE_TEST, File.WRITE)
	file.store_line(to_json(cells))
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
	update_cell_state()
	save_json()


func save_json() -> void:
	var file = File.new()
	var prototype_data = {}
	for id in template.prototypes:
		prototype_data[id] = template.prototypes[id].get_dictionary()
	file.open(FILE_NAME, File.WRITE)
	file.store_line(to_json(prototype_data))
	file.close()


func _on_Button_pressed():
	self.export_definitions = true
	print_debug("Exported prototypes")
