class_name Goal extends Area2D

signal in_light

var sprite : AnimatedSprite2D
var is_lit : bool = false
var beam : Node2D


func _ready():
	sprite = $AnimatedSprite2D
	in_light.connect(_on_in_light)


func _process(delta):
	is_lit = false
	if is_instance_valid(beam):
		if beam.collider == self:
			is_lit = true
	
	if is_lit:
		sprite.play("lit")
	else:
		sprite.play("dim")


func _on_in_light(trigger):
	beam = trigger
