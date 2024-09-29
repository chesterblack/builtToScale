@tool

class_name LightEmitter extends Area2D

@export var beam_angle : Vector2 = Vector2(0, 1)
@export var beam_length : float = 1000.0
@export var beam_width : float = 2.0
@export var beam_color : Beam.BeamColor = Beam.BeamColor.WHITE

var beam : Beam

func _ready():
	beam = $Beam as Beam
	var sprite = $AnimatedSprite2D as AnimatedSprite2D
	sprite.rotation = Vector2.DOWN.angle_to(beam_angle)


func _process(_delta):
	beam.beam_color = beam_color
	if "length" in beam:
		beam.length = beam_length
	if "raycast" in beam:
		beam.ray_target = beam_angle
	if "width" in beam:
		beam.width = beam_width
