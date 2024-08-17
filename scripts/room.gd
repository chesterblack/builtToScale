class_name Room extends Node2D

signal entered
signal exited

var root : Node
var parent_room : Room
var child_room : Room
var level : Node2D

var outside_light : Area2D
var outside_light_location : Vector2 = Vector2.ZERO
var outside_light_angle : float = 0.0


func _ready():
	root = get_node("/root")
	
	if get_parent() is Room:
		parent_room = get_parent()
	
	for child in get_children():
		if child is Room:
			child_room = child
			remove_child(child_room)
	
	entered.connect(_on_entered)


func _process(delta):
	if Input.is_action_just_pressed("zoom_in") and child_room:
		zoom_in()
	if Input.is_action_just_pressed("zoom_out") and parent_room:
		zoom_out()


func zoom_in():
	exited.emit()
	
	child_room.visible = true
	root.add_child(child_room)
	root.remove_child(self)
	
	child_room.entered.emit()


func zoom_out():
	exited.emit()
	
	parent_room.visible = true
	root.add_child(parent_room)
	root.remove_child(self)
	
	parent_room.entered.emit()


func _on_entered():
	if outside_light:
		outside_light.queue_free()
		outside_light = null
	
	if outside_light_location != Vector2.ZERO:
		var light_emitter = load("res://scenes/light_emitter.tscn").instantiate()
		outside_light = light_emitter
		outside_light.beam_angle = outside_light_angle
		outside_light.position = outside_light_location
		add_child(light_emitter)
		
