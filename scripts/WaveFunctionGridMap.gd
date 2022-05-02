tool
extends GridMap
class_name WaveFunctionGridMap

const FILE_NAME = "res://resources/prototypes.json"
const BLANK_CELL_ID = "-1_-1"
const PROTOTYPE_DEFINITION = {
	'weight' : 1,
	'valid_siblings': {
		'right' : [],
		'forward' : [],
		'left': [],
		'back': [],
		'up': [],
		'down': []
	},
	'cell_index': -1,
	'cell_orientation': 0,
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
#export var resource_file : Resource
export var prototypes := {}

var template : WaveFunctionTemplateResource
var wave_function : Array  # Grid of cells containing prototypes
var cell_states := {}
var stack : Array
var bounds : AABB

export var export_definitions : bool = false setget set_export_definitions

class WaveFunctionProtoype:
	var cell_name := ''
	var cell_index := -1
	var cell_orientation := -1
	var valid_siblings = []


var siblings_offsets = {
	Vector3.RIGHT : 'right',
	Vector3.FORWARD : 'forward',
	Vector3.LEFT : 'left',
	Vector3.BACK : 'back',
	Vector3.UP : 'up',
	Vector3.DOWN : 'down'
}


func get_template() -> Dictionary:
	var prototypes_template = {}
	var blank_prototype = PROTOTYPE_DEFINITION.duplicate(true)

	for direction in siblings_offsets:
		var direction_name = siblings_offsets[direction]
		blank_prototype['valid_siblings'][direction_name].append(BLANK_CELL_ID)

	blank_prototype.constrain_to = '-1'
	blank_prototype.constrain_from = '-1'

	prototypes_template[BLANK_CELL_ID] = blank_prototype

	return prototypes_template


func update_prototypes() -> void:

	var time_start = OS.get_ticks_msec()
	print_debug("Generate prototype: START")

	#	initialize cell list
	var cells := get_used_cells()
	print("used cells: %s" % cells.size() )

#	clear existing definitions
	prototypes = get_template()

	var blank_prototype = prototypes[BLANK_CELL_ID]


	for cell_coordinates in cells:

		var contrain_to = 'bot'
		var contrain_from = 'bot'

		if cell_coordinates.y != 0.0:
			contrain_to = ''

		if cell_coordinates.y == 0.0:
			contrain_from = ''

		var cell_index := get_cell_item(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_orientation := get_cell_item_orientation(cell_coordinates.x,cell_coordinates.y,cell_coordinates.z)
		var cell_id = "%s_%s" %  [cell_index,cell_orientation]
		var valid_siblings = {}

		if not prototypes.has(cell_id):
			prototypes[cell_id] = PROTOTYPE_DEFINITION.duplicate(true)

		var cell_prototype = prototypes[cell_id]
		cell_prototype.weight += 1

#		vertical constraints
		if cell_coordinates.y != 0.0:
			cell_prototype.constraints.y.to = -1

		if cell_coordinates.y == 0.0:
			cell_prototype.constraints.y.from = -1

#		check valid nearby cells
		for offset in siblings_offsets:
			var offset_id = siblings_offsets[offset]
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

#			init sibling dictionary
			if not offset_id in cell_prototype.valid_siblings:
				cell_prototype.valid_siblings[offset_id] = []

			var cell_valid_siblings = cell_prototype.valid_siblings[offset_id]

#			init valid sibling / orientation

			if not cell_valid_siblings.has(sibling_cell_id):
#				TODO: may not be needed
				cell_valid_siblings.append(sibling_cell_id)

#			a different way to track siblings potentially
#			if not cell_prototype.has('siblings'):
#				cell_prototype['siblings'] = {}
#			if not cell_prototype['siblings'].has(offset_id):
#				cell_prototype['siblings'][offset_id] = {}
#			if not cell_prototype['siblings'][offset_id].has(sibling_cell):
#				cell_prototype['siblings'][offset_id][sibling_cell] = {}
#			cell_prototype['siblings'][offset_id][sibling_cell][sibling_cell_orientation] = 1

#		cap the weight
		cell_prototype.weight = min(cell_prototype.weight, 1.0)



	var total_time = OS.get_ticks_msec() - time_start
	print("Time taken: " + str(total_time))


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
#	save
#	resource_file.prototypes = prototypes
	save_json()
