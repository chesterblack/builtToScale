class_name Prism extends Area2D

@onready var sprite : Sprite2D = $Sprite2D
@export var color_splits : Array[Beam.BeamColor] = [
	Beam.BeamColor.GOLD,
	Beam.BeamColor.BLUE,
	Beam.BeamColor.PINK,
	Beam.BeamColor.GREEN
]
