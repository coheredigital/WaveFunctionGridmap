extends Node


const size = Vector3(8, 3, 8)
const unit_size = 1.0
const PROTOTYPE_FILE = "res://blender/prototype_data_simple.json"

export var mesh_library_file : PackedScene


var enabled = false
var my_seed = 1

var wfc : WFC3D_Model
var meshes : Array
var mesh_library : MeshLibrary
var coords : Vector3
var gridmap_tiles : Dictionary = {}

onready var module = preload("res://scenes/Module.tscn")
onready var gridmap := $GridMap


func _ready():
	test()


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		my_seed += 1
		test()


func test():
	var update = false  # change to TRUE to re-render every iteration
	clear_meshes()
	seed(my_seed)
	var prototypes = load_prototype_data()
	wfc = WFC3D_Model.new()
	add_child(wfc)
	wfc.initialize(size, prototypes)

	apply_custom_constraints()  # see definition

	if update:
		while not wfc.is_collapsed():
			wfc.iterate()
#			clear_meshes()
#			visualize_wave_function()
			yield(get_tree(), "idle_frame")
#		clear_meshes()
	else:
		regen_no_update()

#	visualize_wave_function()


func regen_no_update():
	while not wfc.is_collapsed():
		wfc.iterate()

	visualize_wave_function()
	if len(meshes) == 0:
		my_seed += 1
		test()


func apply_custom_constraints():
	# This function isn't covered in the video but what we do here is basically
	# go over the wavefunction and remove certain modules from specific places
	# for example in my Blender scene I've marked all of the beach tiles with
	# an attribute called "constrain_to" with the value "bot". This is recalled
	# in this function, and all tiles with this attribute and value are removed
	# from cells that are not at the bottom i.e., if y > 0: constrain.
	var add_to_stack = []

	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				coords = Vector3(x, y, z)
				var protos = wfc.get_possibilities(coords)
				if y == size.y - 1:  # constrain top layer to not contain any uncapped prototypes
					for proto in protos.duplicate():
						var neighs  = protos[proto][WFC3D_Model.NEIGHBOURS][WFC3D_Model.pZ]
						if not "p-1" in neighs:
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)
				if y > 0:  # everything other than the bottom
					for proto in protos.duplicate():
						var custom_constraint = protos[proto][WFC3D_Model.CONSTRAIN_TO]
						if custom_constraint == WFC3D_Model.CONSTRAINT_BOTTOM:
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)
				if y < size.y - 1:  # everything other than the top
					for proto in protos.duplicate():
						var custom_constraint = protos[proto][WFC3D_Model.CONSTRAIN_TO]
						if custom_constraint == WFC3D_Model.CONSTRAINT_TOP:
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)
				if y == 0:  # constrain bottom layer so we don't start with any top-cliff parts at the bottom
					for proto in protos.duplicate():
						var neighs  = protos[proto][WFC3D_Model.NEIGHBOURS][WFC3D_Model.nZ]
						var custom_constraint = protos[proto][WFC3D_Model.CONSTRAIN_FROM]
						if (not "p-1" in neighs) or (custom_constraint == WFC3D_Model.CONSTRAINT_BOTTOM):
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)
				if x == size.x - 1: # constrain +x
					for proto in protos.duplicate():
						var neighs  = protos[proto][WFC3D_Model.NEIGHBOURS][WFC3D_Model.pX]
						if not "p-1" in neighs:
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)
				if x == 0: # constrain -x
					for proto in protos.duplicate():
						var neighs  = protos[proto][WFC3D_Model.NEIGHBOURS][WFC3D_Model.nX]
						if not "p-1" in neighs:
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)
				if z == size.z - 1: # constrain +z
					for proto in protos.duplicate():
						var neighs  = protos[proto][WFC3D_Model.NEIGHBOURS][WFC3D_Model.nY]
						if not "p-1" in neighs:
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)
				if z == 0: # constrain -z
					for proto in protos.duplicate():
						var neighs  = protos[proto][WFC3D_Model.NEIGHBOURS][WFC3D_Model.pY]
						if not "p-1" in neighs:
							protos.erase(proto)
							if not coords in wfc.stack:
								wfc.stack.append(coords)


	wfc.propagate(false, false)


func load_prototype_data():
	var file = File.new()
	file.open(PROTOTYPE_FILE, file.READ)
	var text = file.get_as_text()
	var prototypes = JSON.parse(text).result
	return prototypes


func visualize_wave_function(only_collapsed : bool = true) -> void:

	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				var prototypes = wfc.wave_function[z][y][x]
#
				if only_collapsed:
					if len(prototypes) > 1:
						continue

				for prototype in prototypes:
					var dict = wfc.wave_function[z][y][x][prototype]
					var mesh_rot = dict['mesh_rotation']
					var gridmap_index = dict['gridmap_index']
					var mesh_basis = Basis(Vector3.UP,(PI/2) * mesh_rot)
					var orientation = mesh_basis.get_orthogonal_index()
					gridmap.set_cell_item(x,y,z,gridmap_index, orientation)

#					if gridmap_index < 0:
#						continue

					var inst = module.instance()
					meshes.append(inst)





func clear_meshes():
	for mesh in meshes:
		mesh.queue_free()
	meshes = []
