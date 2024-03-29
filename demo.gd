extends Node


onready var template : WaveFunctionGridMapTemplate = $GridMapTemplate
onready var gridmap : WaveFunctionGridMap = $GridMap
onready var camera_focus := $CamFocus
var cell_data : WaveFunctionCellsResource


func initialize() -> void:
	template.update_prototypes()
	gridmap.initialize()


func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		generate()


func generate():
	gridmap.initialize()
	gridmap.collapse()



func render_cell(coords : Vector3, cell_index: int,cell_orientation : int):
	gridmap.set_cell_item(coords.x, coords.y, coords.z, cell_index, cell_orientation)


func render_gridmap(wfc : WaveFunctionCellsResource):
	for coords in wfc.cells:
		var prototypes = wfc.cells[coords]
		if len(prototypes) > 1:
			continue
		for id in prototypes:
			var prototype = prototypes[id]
			render_cell(coords, prototype.index, prototype.orientation)


func _on_cell_collapsed(coords : Vector3, cell_index: int, cell_orientation : int) -> void:
	render_cell(coords, cell_index, cell_orientation)


func clear_meshes():
	gridmap.clear()


