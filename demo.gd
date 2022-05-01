extends Node

export var size = Vector3(3, 4, 8)
onready var gridmap := $GridMap
onready var camera_focus := $CamFocus
export var cell_data : Resource


func _ready():
	gridmap.export_definitions = true
	camera_focus.translation = Vector3(0.5,0.5,0.5) * size
	cell_data = WaveFunctionCellsResource.new()
	cell_data.initialize(size, gridmap.prototypes)

func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		generate()


func generate():
	cell_data.reset()
	gridmap.clear()
	while not cell_data.is_collapsed():

		yield(get_tree(), "idle_frame")
		var result = cell_data.step_collapse()

#		render_gridmap(cell_data)
		var coords : Vector3 = result.coords
		var cell_index : int = result.prototype.cell_index
		var cell_orientation : int = result.prototype.cell_orientation
		render_cell(coords,cell_index,cell_orientation)

	render_gridmap(cell_data)

	if cell_data.is_collapsed():
		print('Cells collapsed')



func render_gridmap(data : WaveFunctionCellsResource):
	generate_gridmap(data)


func render_cell(coords : Vector3, cell_index: int,cell_orientation : int):
	gridmap.set_cell_item(coords.x, coords.y, coords.z, cell_index, cell_orientation)


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


func _on_ButtonGenerate_pressed():
	generate()
