extends Node


const unit_size = Vector3(1.0, 1.0, 1.0)
const DATA_FILE = "res://blender/prototype_data_simple.json"
const DATA_FILE_NEW = "res://resources/prototypes.json"

export var size = Vector3(3, 4, 8)
export var prototype_data : Resource

onready var gridmap := $GridMap
var cell_data : WaveFunctionCellsResource
var cell_data_new : WaveFunctionCellsResourceNew
var prototypes : Dictionary
var prototypes_new : Dictionary


func _ready():
	prototypes = load_prototype_data()
	prototypes_new = load_prototype_data_new()


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		generate()


func generate():
	seed(OS.get_unix_time())

	cell_data = WaveFunctionCellsResource.new()
	cell_data.initialize(size, prototypes)
	apply_custom_constraints(cell_data)  # see definition

#	my data structure
	cell_data_new = WaveFunctionCellsResourceNew.new()
#	cell_data_new.initialize(size, prototype_data.prototypes)
	cell_data_new.initialize(size, prototypes_new)


	gridmap.clear()
	while not cell_data.is_collapsed():
		cell_data.iterate()
		print('gridmap')
		yield(get_tree(), "idle_frame")
		generate_gridmap(cell_data)

#	gridmap.clear()
#	while not cell_data_new.is_collapsed():
#		cell_data_new.iterate()
#		print('gridmap')
#		yield(get_tree(), "idle_frame")
#		generate_gridmap(cell_data_new)


func apply_custom_constraints(wfc : WaveFunctionCellsResource):
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
				if not "p-1" in neighs:
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
				if (not "p-1" in neighs) or (custom_constraint == WaveFunctionCellsResource.CONSTRAINT_BOTTOM):
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.x == size.x - 1: # constrain +x
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.pX]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.x == 0: # constrain -x
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.nX]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.z == size.z - 1: # constrain +z
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.nY]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.z == 0: # constrain -z
			for proto in protos.duplicate():
				var neighs  = protos[proto][WaveFunctionCellsResource.SIBLINGS][WaveFunctionCellsResource.pY]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)

	wfc.propagate(Vector3.INF)


func load_prototype_data():
	var file = File.new()
	file.open(DATA_FILE, file.READ)
	var text = file.get_as_text()
	var prototypes = JSON.parse(text).result
	return prototypes


func load_prototype_data_new():
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
			gridmap.set_cell_item(coords.x, coords.y, coords.z, cell_index, cell_orientation)

func clear_meshes():
	gridmap.clear()
