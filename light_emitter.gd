extends Area2D

@export var beam_angle : float = 0.0

var beam : Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	beam = $Beam


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	beam.rotation_degrees = beam_angle
