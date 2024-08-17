extends Node2D

@export var is_active : bool = true
@export var ignored_colliders : Array[Area2D]

var is_reflected : bool = false
var raycast : RayCast2D
var line : Line2D

func _ready():
	raycast = $RayCast2D
	line = $Line2D


func _process(delta):
	visible = is_active
	line.clear_points()
	line.add_point(raycast.position)
	line.add_point(raycast.target_position)


func _physics_process(delta):
	if is_active:
		var collider = raycast.get_collider()
		if collider:
			if collider not in ignored_colliders:
				is_reflected = false
				
				if collider is Reflector:
					var reflected_raycast = collider.reflected_beam.raycast as RayCast2D
					
					is_reflected = true
					var laser_coll_point = raycast.get_collision_point()
					var laser_coll_normal = raycast.get_collision_normal()
					collider.reflected_beam.global_position = laser_coll_point
					var forward = laser_coll_point - raycast.global_position
					var reflection = forward.reflect(laser_coll_normal)
					
					reflected_raycast.target_position = -reflection
					#collider.reflected_beam = reflection.angle()
				
				if collider is Goal:
					print("WIN")
