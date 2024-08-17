class_name Beam extends Node2D

@export var ignored_colliders : Array
@export var length : float = 1000.0

var raycast : RayCast2D
var line : Line2D
var is_reflected : bool = false
var reflected_beam : Node2D
var collider : Node2D


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
		collider = raycast.get_collider()
		#$Label.text = str(collider) + "\n" + str(ignored_colliders)
		line.add_point(to_local(raycast.get_collision_point()))
		
		if collider not in ignored_colliders and collider is Reflector:
			create_reflection()
		
		if collider is Goal:
			collider.in_light.emit(self)
		
		if collider is Player:
			var this_room = get_node("/root/Room")
			if this_room and "child_room" in this_room:
				var collision_point = raycast.get_collision_point()
				var collision_x = collision_point.x
				var player_width = collider.get_glass_size().x
				var player_left_side = collider.position.x - (player_width / 2)
				var collision_left = collision_x - player_left_side
				var percentage = (collision_left / player_width) * 100
				var room_width = get_viewport().size.x
				var light_x = (percentage * room_width) / 100
				
				this_room.child_room.outside_light_location = Vector2(light_x, -50.0)
				
				if rotation_degrees:
					this_room.child_room.outside_light_angle = rotation_degrees
				else:
					if Input.is_action_just_pressed("debug"):
						var collision_marker = Sprite2D.new()
						collision_marker.set_texture(load("res://sprites/crosshair.png"))
						collision_marker.position = collision_point
						get_node("/root").add_child(collision_marker)
						
						collision_marker = Sprite2D.new()
						collision_marker.set_texture(load("res://sprites/crosshair.png"))
						collision_marker.position = global_position
						get_node("/root").add_child(collision_marker)
						
						collision_marker = Sprite2D.new()
						collision_marker.set_texture(load("res://sprites/crosshair.png"))
						collision_marker.position = Vector2(global_position.x, collision_point.y)
						get_node("/root").add_child(collision_marker)
						
						var short_side_length = collision_point.x - global_position.x
						var long_side_length = collision_point.y - global_position.y
						
						var angle = atan(short_side_length / long_side_length)
						print("angle: ", angle)
						
						print("---")
						print("collision_point: ", collision_point)
						print("beam.position: ", global_position)
						print("target: ", to_global(raycast.target_position))
						print("normal: ", to_global(raycast.get_collision_normal()))

	else:
		line.add_point(raycast.target_position)
	
	if !is_reflected and reflected_beam:
		reflected_beam.queue_free()
		reflected_beam = null


func create_reflection():
	if !reflected_beam:
		reflected_beam = load("res://scenes/beam.tscn").instantiate()
		reflected_beam.ignored_colliders = []
		reflected_beam.ignored_colliders.append(collider)
		add_child(reflected_beam)
	
	is_reflected = true
	var collision_point = raycast.get_collision_point()
	var collision_normal = raycast.get_collision_normal().normalized()
	var forward = collision_point - raycast.global_position
	var reflection = forward.reflect(collision_normal).normalized() * length
	
	reflected_beam.reflect_beam(collision_point, reflection)


func reflect_beam(collision_point, reflection):
	global_position = collision_point
	raycast.target_position = -reflection
