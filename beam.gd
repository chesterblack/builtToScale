class_name Beam extends Node2D

@export var ignored_colliders : Array
@export var length : float = 1000.0

var is_reflected : bool = false
var raycast : RayCast2D
var line : Line2D
var reflected_beam : Node2D


func _ready():
	raycast = $RayCast2D
	line = $Line2D
	
	for exception in ignored_colliders:
		raycast.add_exception(exception)


func test_function():
	return "exists"


func _physics_process(delta):
	is_reflected = false
	raycast.target_position = raycast.target_position.normalized() * length
	
	line.clear_points()
	line.add_point(raycast.position)
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		# $Label.text = str(collider) + "\n" + str(ignored_colliders)
		line.add_point(to_local(raycast.get_collision_point()))
		
		if collider not in ignored_colliders and collider is Reflector:
			if !reflected_beam:
				reflected_beam = load("res://beam.tscn").instantiate()
				reflected_beam.ignored_colliders = []
				reflected_beam.ignored_colliders.append(collider)
				add_child(reflected_beam)
			
			is_reflected = true
			var collision_point = raycast.get_collision_point()
			var collision_normal = raycast.get_collision_normal().normalized()
			var forward = collision_point - raycast.global_position
			var reflection = forward.reflect(collision_normal).normalized() * length
			
			reflected_beam.reflect_beam(collision_point, reflection)
		
		if collider is Goal:
			print("WIN")
	else:
		line.add_point(raycast.target_position)
	
	if !is_reflected and reflected_beam:
		reflected_beam.queue_free()
		reflected_beam = null


func reflect_beam(collision_point, reflection):
	global_position = collision_point
	raycast.target_position = -reflection
