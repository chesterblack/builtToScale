class_name Lens extends Prism

@export var color_preset : Beam.BeamColor


func _ready():
	if color_preset:
		if color_preset == Beam.BeamColor.WHITE:
			color_splits = [
				Beam.BeamColor.GOLD,
				Beam.BeamColor.BLUE,
				Beam.BeamColor.PINK,
				Beam.BeamColor.GREEN
			]
		else:
			color_splits = [ color_preset ]
	
	match color_preset:
		Beam.BeamColor.WHITE:
			sprite.texture = load("res://sprites/white_lens.png")
		Beam.BeamColor.GOLD:
			sprite.texture = load("res://sprites/gold_lens.png")
		Beam.BeamColor.BLUE:
			sprite.texture = load("res://sprites/blue_lens.png")
		Beam.BeamColor.PINK:
			sprite.texture = load("res://sprites/pink_lens.png")
		Beam.BeamColor.GREEN:
			sprite.texture = load("res://sprites/green_lens.png")
