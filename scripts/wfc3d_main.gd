extends Node


const unit_size = Vector3(1.0, 1.0, 1.0)
const DATA_FILE = "res://blender/prototype_data_simple.json"

export var size = Vector3(3, 4, 8)

onready var mesh_container = $Meshes
onready var wfc := $WFC
onready var gridmap := $GridMap


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		generate()


func generate():
	seed(OS.get_unix_time())
	var prototypes = load_prototype_data()
	wfc.initialize(size, prototypes)
	apply_custom_constraints()  # see definition
	clear_meshes()
	while not wfc.is_collapsed():
		wfc.iterate()
		yield(get_tree(), "idle_frame")
		visualize_wave_function()


func apply_custom_constraints():
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
				var neighs  = protos[proto][WFC3D_Model.SIBLINGS][WFC3D_Model.pZ]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.y > 0:  # everything other than the bottom
			for proto in protos.duplicate():
				var custom_constraint = protos[proto][WFC3D_Model.CONSTRAIN_TO]
				if custom_constraint == WFC3D_Model.CONSTRAINT_BOTTOM:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.y < size.y - 1:  # everything other than the top
			for proto in protos.duplicate():
				var custom_constraint = protos[proto][WFC3D_Model.CONSTRAIN_TO]
				if custom_constraint == WFC3D_Model.CONSTRAINT_TOP:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.y == 0:  # constrain bottom layer so we don't start with any top-cliff parts at the bottom
			for proto in protos.duplicate():
				var neighs  = protos[proto][WFC3D_Model.SIBLINGS][WFC3D_Model.nZ]
				var custom_constraint = protos[proto][WFC3D_Model.CONSTRAIN_FROM]
				if (not "p-1" in neighs) or (custom_constraint == WFC3D_Model.CONSTRAINT_BOTTOM):
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.x == size.x - 1: # constrain +x
			for proto in protos.duplicate():
				var neighs  = protos[proto][WFC3D_Model.SIBLINGS][WFC3D_Model.pX]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.x == 0: # constrain -x
			for proto in protos.duplicate():
				var neighs  = protos[proto][WFC3D_Model.SIBLINGS][WFC3D_Model.nX]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.z == size.z - 1: # constrain +z
			for proto in protos.duplicate():
				var neighs  = protos[proto][WFC3D_Model.SIBLINGS][WFC3D_Model.nY]
				if not "p-1" in neighs:
					protos.erase(proto)
					if not coords in wfc.stack:
						wfc.stack.append(coords)
		if coords.z == 0: # constrain -z
			for proto in protos.duplicate():
				var neighs  = protos[proto][WFC3D_Model.SIBLINGS][WFC3D_Model.pY]
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


func visualize_wave_function():
	for coords in wfc.cell_states:

		var prototypes = wfc.cell_states[coords]

		if len(prototypes) > 1:
			continue

		for prototype in prototypes:
			var dict = wfc.cell_states[coords][prototype]
			var mesh_rot = dict[wfc.MESH_ROT]
			var mesh_index = dict[wfc.MESH_INDEX]

			if mesh_index == -1:
				continue

			var cell_orientation = Basis(Vector3.UP,(PI/2) * mesh_rot).get_orthogonal_index()
			gridmap.set_cell_item(coords.x,coords.y,coords.z,mesh_index, cell_orientation)


func clear_meshes():
	gridmap.clear()
