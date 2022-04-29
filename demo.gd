extends Spatial


onready var gridmap := $wfc_gridmap


func _on_ButtonClear_pressed():
	gridmap.clear()


func _on_ButtonGenerate_pressed():
	gridmap.generate()


func _on_ButtonIterate_pressed():
	gridmap.iterate()
