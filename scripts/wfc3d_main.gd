extends Node


const DATA_FILE = "res://blender/prototype_data_simple.json"
const DATA_FILE_NEW = "res://resources/prototypes.json"
const BLANK_CELL_ID = "-1_-1"

export var size = Vector3(3, 4, 8)
export var prototype_data : Resource

onready var gridmap := $GridMap
var cell_data : WaveFunctionCellsResource
var prototypes : Dictionary


func _ready():
	prototypes = load_prototype_data()

	cell_data = WaveFunctionCellsResource.new()

#	cell_data.connect("cell_collapsed" , self, "_on_cell_collapsed")


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		generate()



func generate():
	seed(OS.get_unix_time())

	var data = get_cell_data()

	gridmap.clear()
	while not data.is_collapsed():

		yield(get_tree(), "idle_frame")
		var result = data.step_collapse()

#		render_gridmap(cell_data)
		var coords : Vector3 = result.coords
		var cell_index : int = result.prototype.cell_index
		var cell_orientation : int = result.prototype.cell_orientation
#		yield(cell_data, "cell_collapsed")
#		render_cell(coords, cell_index,cell_orientation)

		render_gridmap(data)

	if data.is_collapsed():
		print('Cells collapsed')


func get_cell_data():
#	cell_data.initialize(size, prototype_data.prototypes)
	cell_data.initialize(size, prototypes)
#	apply_custom_constraints(cell_data, "p-1")
	apply_custom_constraints(cell_data, '-1_-1')
	return cell_data


func render_gridmap(data : WaveFunctionCellsResource):

	generate_gridmap(data)


func render_cell(coords : Vector3, cell_index: int,cell_orientation : int):
	gridmap.set_cell_item(coords.x, coords.y, coords.z, cell_index, cell_orientation)



func apply_custom_constraints(wfc : WaveFunctionCellsResource, blank_name : String):
	# This function isn't covered in the video but what we do here is basically
	# go over the wavefunction and remove certain modules from specific places
	# for example in my Blender scene I've marked all of the beach tiles with
	# an attribute called "constrain_to" with the value "bot". This is recalled
	# in this function, and all tiles with this attribute and value are removed
	# from cells that are not at the bottom i.e., if y > 0: constrain.

	var add_to_stack = []

	for coords in wfc.cell_states:

		var protos = wfc.get_possibilities(coords)
		if coords.y == size.y - 1:  # constrain top layer to not contain any uncapped prototypes
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.pZ]
				if not blank_name in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.y > 0:  # everything other than the bottom
			for proto in protos.duplicate():
				var custom_constraint = protos[proto][WaveFunctionCellsResource.CONSTRAIN_TO]
				if custom_constraint == WaveFunctionCellsResource.CONSTRAINT_BOTTOM:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.y < size.y - 1:  # everything other than the top
			for proto in protos.duplicate():
				var custom_constraint = protos[proto][WaveFunctionCellsResource.CONSTRAIN_TO]
				if custom_constraint == WaveFunctionCellsResource.CONSTRAINT_TOP:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.y == 0:  # constrain bottom layer so we don't start with any top-cliff parts at the bottom
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.nZ]
				var custom_constraint = protos[proto][WaveFunctionCellsResource.CONSTRAIN_FROM]
				if (not blank_name in neighs) or (custom_constraint == WaveFunctionCellsResource.CONSTRAINT_BOTTOM):
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.x == size.x - 1: # constrain +x
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.pX]
				if not blank_name in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.x == 0: # constrain -x
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.nX]
				if not blank_name in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.z == size.z - 1: # constrain +z
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.nY]
				if not blank_name in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.z == 0: # constrain -z
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.pY]
				if not blank_name in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)

	wfc.propagate(Vector3.INF)


func load_prototype_data():
	var file = File.new()
	file.open(DATA_FILE_NEW, file.READ)
	var text = file.get_as_text()
	var prototypes = JSON.parse(text).result
	return prototypes



func generate_gridmap(wfc : WaveFunctionCellsResource):
	for coords in wfc.cell_states:

		var prototypes = wfc.cell_states[coords]

		if len(prototypes) > 1:
			continue

		for prototype in prototypes:
			var dict = wfc.cell_states[coords][prototype]
			var cell_index = dict['cell_index']
			if cell_index == -1:
				continue

			var cell_orientation = dict['cell_orientation']
			render_cell(coords, cell_index, cell_orientation)


func _on_cell_collapsed(coords : Vector3, cell_index: int, cell_orientation : int) -> void:
	render_cell(coords, cell_index, cell_orientation)


func clear_meshes():
	gridmap.clear()
