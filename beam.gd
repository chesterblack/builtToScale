extends Node2D

var is_active : bool = true
var is_reflected : bool = false
var raycast : RayCast2D

func _ready():
	raycast = $RayCast2D


func _process(delta):
	visible = is_active


func _physics_process(delta):
	if is_active:
		var collider = raycast.get_collider()
		is_reflected = false
		
		if collider is Reflector:
			is_reflected = true
			collider.in_light.emit(self)
		
		if collider is Goal:
			print("WIN")
