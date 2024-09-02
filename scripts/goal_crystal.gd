@tool

class_name Goal extends Area2D

signal in_light

@export var color : Beam.BeamColor = Beam.BeamColor.WHITE

var sprite : AnimatedSprite2D
var is_lit : bool = false
var beam : Beam


func _ready():
	sprite = $AnimatedSprite2D
	in_light.connect(_on_in_light)
	
	var current_room = Global.current_room
	if current_room:
		while current_room.parent_room is Room:
			current_room = current_room.parent_room
		
		Global.goals.append(self)


func _process(_delta):
	match color:
		Beam.BeamColor.WHITE:
			sprite.sprite_frames = load("res://crystal_frames/white.tres")
		Beam.BeamColor.GOLD:
			sprite.sprite_frames = load("res://crystal_frames/gold.tres")
		Beam.BeamColor.BLUE:
			sprite.sprite_frames = load("res://crystal_frames/blue.tres")
		Beam.BeamColor.PINK:
			sprite.sprite_frames = load("res://crystal_frames/pink.tres")
		Beam.BeamColor.GREEN:
			sprite.sprite_frames = load("res://crystal_frames/green.tres")
	
	is_lit = false
	if is_instance_valid(beam):
		if beam.collider == self and beam.beam_color == color:
			is_lit = true
	
	if is_lit:
		sprite.play("lit")
	else:
		sprite.play("dim")


func _on_in_light(trigger):
	if !is_lit:
		var sound = load("res://sounds/lightup.wav")
		Global.queue_sound($AudioStreamPlayer2D, sound)
	beam = trigger
