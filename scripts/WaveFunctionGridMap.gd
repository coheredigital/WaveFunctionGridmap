tool
extends GridMap
class_name WaveFunctionGridMap

const FILE_PROTOTYPES = "res://resources/prototypes.json"
const FILE_CELLS = "res://resources/cells.json"
const FILE_SOCKETS = "res://resources/sockets.json"
const FILE_REGISTRY = "res://resources/sockets_registry.json"
const FILE_TEST = "res://resources/test.json"

export var clear_canvas : bool setget set_clear_canvas
export var export_definitions : bool = false setget set_export_definitions

var template : WaveFunctionTemplateResource


const sibling_directions = {
	Vector3.RIGHT : 'right',
	Vector3.FORWARD : 'forward',
	Vector3.LEFT : 'left',
	Vector3.BACK : 'back',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down'
}

var structure := {}


func get_oriented_directions(cell_orientation: int) -> Dictionary:
	var directions : Dictionary

	match cell_orientation:
		0: # Forward (default)
			return {
				Vector3.FORWARD: Vector3.FORWARD,
				Vector3.RIGHT: Vector3.RIGHT,
				Vector3.BACK: Vector3.BACK,
				Vector3.LEFT: Vector3.LEFT
			}
		22: # Right (90)
			return  {
				Vector3.FORWARD: Vector3.RIGHT,
				Vector3.RIGHT: Vector3.BACK,
				Vector3.BACK: Vector3.LEFT,
				Vector3.LEFT: Vector3.FORWARD
			}
		10: # Back (180)
			return  {
				Vector3.FORWARD: Vector3.BACK,
				Vector3.RIGHT: Vector3.LEFT,
				Vector3.BACK: Vector3.FORWARD,
				Vector3.LEFT: Vector3.RIGHT
			}
		16: # Left (270)
			return  {
				Vector3.FORWARD: Vector3.RIGHT,
				Vector3.RIGHT: Vector3.BACK,
				Vector3.BACK: Vector3.LEFT,
				Vector3.LEFT: Vector3.FORWARD
			}
		_:
			return {}


func update_prototypes() -> void:
	template = WaveFunctionTemplateResource.new()
	var used_cells := get_used_cells()

	for coords in used_cells:
		var cell_index := get_cell_item(coords.x,coords.y,coords.z)
		var cell_orientation := get_cell_item_orientation(coords.x,coords.y,coords.z)
		print("cell: %s_%s" % [cell_index,cell_orientation] )

		if not structure.has(cell_index):
			structure[cell_index] = {}

		if not structure[cell_index].has(cell_orientation):
			structure[cell_index][cell_orientation] = {}


		var oriented_directions : Dictionary = get_oriented_directions(cell_orientation)
		print(oriented_directions)
#		if not structure[cell_index].has()

		for direction in sibling_directions:
			var sibling_coords = coords + direction
			var sibling_cell_index := get_cell_item(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var sibling_cell_orientation := get_cell_item_orientation(sibling_coords.x,sibling_coords.y,sibling_coords.z)
			var direction_name = sibling_directions[direction]
			var oriented_direction = Vector3.ZERO
			var oriented_direction_name = ''

			if oriented_directions.has(direction):
				oriented_direction = oriented_directions[direction]
				oriented_direction_name = sibling_directions[oriented_direction]

			if not oriented_direction_name:
				continue


			if not structure[cell_index][cell_orientation].has(direction_name):
				structure[cell_index][cell_orientation][direction_name] = {}

			if not structure[cell_index][cell_orientation][direction_name].has(sibling_cell_index):
				structure[cell_index][cell_orientation][direction_name][sibling_cell_index] = []

			if not structure[cell_index][cell_orientation][direction_name][sibling_cell_index].has(sibling_cell_orientation):
				structure[cell_index][cell_orientation][direction_name][sibling_cell_index].append(sibling_cell_orientation)

			print('	siblings( %s ): %s' % [direction_name, oriented_direction_name])



	var file = File.new()
	file.open(FILE_TEST, File.WRITE)
	file.store_line(to_json(structure))
	file.close()

#	print_debug("Generated prototype: %s cells in use." % used_cells.size())


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
		'prototypes' : template.prototype_sockets,
		'cells' : template.sockets,
		'registry' : template.socket_registry
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
