extends Node


export var size = Vector3(8, 3, 8)
onready var gridmap := $Map/GridMap
onready var camera_focus := $CamFocus
var cell_data : WaveFunctionCellsResource


func _ready():
	camera_focus.translation = Vector3(0.5,0.5,0.5) * size
	cell_data = WaveFunctionCellsResource.new()
	gridmap.update_prototypes()
	cell_data.initialize(size, gridmap.prototypes)


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		generate()


func generate():
	cell_data.reset()
	gridmap.clear()
	cell_data.collapse()
	render_gridmap(cell_data)


func render_cell(coords : Vector3, cell_index: int,cell_orientation : int):
	gridmap.set_cell_item(coords.x, coords.y, coords.z, cell_index, cell_orientation)


func render_gridmap(wfc : WaveFunctionCellsResource):
	for coords in wfc.states:
		var prototypes = wfc.states[coords]
		if len(prototypes) > 1:
			continue
		for id in prototypes:
			var prototype = prototypes[id]
			render_cell(coords, prototype.index, prototype.orientation)


func _on_cell_collapsed(coords : Vector3, cell_index: int, cell_orientation : int) -> void:
	render_cell(coords, cell_index, cell_orientation)


func clear_meshes():
	gridmap.clear()
