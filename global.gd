extends Node

var current_room : Room

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_node("/root").get_children():
		if child is Room:
			current_room = child
			break
	print(current_room)


func win():
	print("YOU WIN")
