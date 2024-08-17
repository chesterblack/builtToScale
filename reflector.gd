class_name Reflector extends Area2D

signal in_light

var reflected_beam : Node2D
var reflecting_emitter : Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	reflected_beam = $ReflectedBeam
	
	in_light.connect(_on_in_light)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	reflected_beam.raycast.global_rotation = 0.0
	#reflected_beam.is_active = false
	if reflecting_emitter:
		if reflecting_emitter.is_reflected:
			reflected_beam.is_active = true
			pass


func _on_in_light(emitter, normal, point):
	pass
	#get_node("/root/Node2D/Target").global_position = normal
	#print(normal)
	#reflecting_emitter = emitter
	#reflected_beam.global_position = point
	#reflected_beam.look_at(normal)
