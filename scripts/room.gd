class_name Room extends Node2D

signal entered
signal exited

@export_file("*.tscn") var next_level : String

@onready var button_prompt_label : Label = $UI/HUD/ButtonPromptLabel
@onready var audio_player : AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var root : Node = get_node("/root")

var parent_room : Room
var child_room : Room
var goals : Array[Goal] = []

var outside_light : Area2D
var outside_light_location : Vector2 = Vector2.ZERO
var outside_light_angle : Vector2 = Vector2.ZERO
var outside_light_width : float


func _ready():
	button_prompt_label.text = ""
	$UI/HUD/NextLevel.next_level = next_level
	
	if get_parent() is Room:
		parent_room = get_parent()
	
	for child in get_children():
		if child is Room:
			child_room = child
			remove_child(child_room)
	
	entered.connect(_on_entered)
	Global.win.connect(_on_win)


func _process(_delta):
	if Input.is_action_just_pressed("zoom_in") and child_room:
		zoom_in()
	if Input.is_action_just_pressed("zoom_out") and parent_room:
		zoom_out()
	
	var win = true
	if goals:
		for goal in goals:
			if !goal.is_lit:
				win = false
	
	if win:
		Global.win.emit()


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
	Global.current_room = self
	
	if outside_light:
		outside_light.queue_free()
		outside_light = null
	
	if outside_light_location != Vector2.ZERO:
		var light_emitter = load("res://scenes/light_emitter.tscn").instantiate()
		outside_light = light_emitter
		outside_light.beam_angle = outside_light_angle
		outside_light.position = outside_light_location
		outside_light.beam_width = outside_light_width
		add_child(light_emitter)


func _on_win():
	$UI/HUD/WinLabel.visible = true
	$UI/HUD/NextLevel.visible = true
