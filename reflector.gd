class_name Reflector extends Area2D

signal in_light

var reflection_point : Node2D
var reflecting_emitter : Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	reflection_point = $ReflectionPoint
	
	in_light.connect(_on_in_light)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	reflection_point.is_active = false
	if reflecting_emitter:
		if reflecting_emitter.is_reflected:
			reflection_point.is_active = true


func _on_in_light(emitter):
	reflecting_emitter = emitter
