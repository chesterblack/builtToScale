class_name Prism extends Area2D

@onready var collider : CollisionShape2D = $CollisionShape2D
@onready var sprite : Sprite2D = $Sprite2D

# Which beams are created from this prism
@export var color_splits : Array[Beam.BeamColor] = [
	Beam.BeamColor.GOLD,
	Beam.BeamColor.BLUE,
	Beam.BeamColor.PINK,
	Beam.BeamColor.GREEN
]

# All the code for refractions happens in the beam code

# Stupid system really, there should be an interface that the beam calls and the action
# happens in here
