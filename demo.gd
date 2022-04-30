extends Spatial


onready var gridmap := $Gridmap


func _on_ButtonClear_pressed():
	gridmap.clear()


func _on_ButtonGenerate_pressed():
	gridmap.generate()


func _on_ButtonIterate_pressed():
	gridmap.iterate()
