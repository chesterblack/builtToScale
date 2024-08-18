@tool

class_name LightEmitter extends Area2D

@export var beam_angle : Vector2 = Vector2(0, 1)
@export var beam_length : float = 1000.0
@export var beam_width : float = 2.0

var beam : Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	beam = $Beam


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if "length" in beam:
		beam.length = beam_length
	if "raycast" in beam:
		beam.raycast.target_position = beam_angle
	if "width" in beam:
		beam.width = beam_width
