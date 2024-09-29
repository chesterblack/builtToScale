class_name Room extends Node2D

signal entered
signal exited

signal can_zoom_in
signal can_zoom_out

@export_file("*.tscn") var next_level : String

@onready var button_prompt_label : Label = $UI/HUD/ButtonPromptLabel
@onready var audio_player : AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var root : Node = get_node("/root")

var camera : Camera2D

var parent_room : Room
var child_room : Room
var goals : Array[Goal] = []

var outside_lights : Array[Beam] = []


func _ready():
	# For picking stuff up
	button_prompt_label.text = ""
	$UI/HUD/NextLevel.next_level = next_level
	
	if get_parent() is Room:
		parent_room = get_parent()
	
	# On load, store all child rooms in a variable and kick them out of the tree
	for child in get_children():
		if child is Room:
			child_room = child
			remove_child(child_room)
	
	entered.connect(_on_entered)
	can_zoom_in.connect(_on_can_zoom_in)
	can_zoom_out.connect(_on_can_zoom_out)
	Global.win.connect(_on_win)


func _process(_delta):
	if Input.is_action_just_pressed("zoom_in") and child_room:
		zoom_in()
	
	if Input.is_action_just_pressed("zoom_out") and parent_room:
		zoom_out()


func zoom_in():
	Global.zoom_in.emit()


func zoom_out():
	Global.zoom_out.emit()


# This is where the zooming actually happens, theres some awful coupling with the
# Globals script and idk where the responsibility lies bewtween the two for switching rooms
func _on_can_zoom_in():
	exited.emit()
	
	child_room.visible = true
	root.add_child(child_room)
	Global.force_sound(child_room.audio_player, load("res://sounds/zoomin1.wav"))
	root.remove_child(self)
	
	child_room.entered.emit()


func _on_can_zoom_out():
	exited.emit()
	
	parent_room.visible = true
	root.add_child(parent_room)
	Global.force_sound(parent_room.audio_player, load("res://sounds/zoomout1.wav"))
	root.remove_child(self)
	
	parent_room.entered.emit()


# This sets the current room and creates any lights from the next level up that have
# hit the character 
func _on_entered():
	Global.current_room = self
	
	var outside_lights_container = $OutsideLights
	
	for child in outside_lights_container.get_children():
		if child not in outside_lights:
			child.queue_free()
	
	# This is kinda fucked at the moment, you're halfway through sorting out beams
	# coming from directions other than the top of the character
	for i in outside_lights.size():
		var light = outside_lights[i]
		print(light.position)
		if !light.parent_beam.is_hitting_char:
			light.queue_free()
			outside_lights.remove_at(i)
		if !outside_lights_container.has_node(NodePath(light.name)):
			outside_lights_container.add_child(light)


func _on_win():
	$UI/HUD/NextLevel.visible = true
