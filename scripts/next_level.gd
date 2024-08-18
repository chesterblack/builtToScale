extends Button

var next_level : String


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():
	var next_scene = load(next_level)
	var next_scene_instance = next_scene.instantiate()
	get_node("/root").add_child(next_scene_instance)
	
	Global.current_room.get_parent().remove_child(Global.current_room)
	Global.current_room.queue_free()
	
	Global.current_room = next_scene_instance
