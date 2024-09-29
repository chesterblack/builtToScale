@tool

# Deals with the beam itself and reflections and refractions
# The beam has a raycast, and a line2d that copies the raycast path

class_name Beam extends Node2D

enum BeamColor { WHITE, GOLD, BLUE, PINK, GREEN }

const BEAM_COLORS : Array[Color] = [
	Color("#ffffff"),
	Color("#e9b042"),
	Color("#3d89b3"),
	Color("#f0657a"),
	Color("#8beb50")
]

@export var ignored_colliders : Array
@export var length : float = 1600.0
@export var beam_color : BeamColor = BeamColor.WHITE # This can be modified externally

var color : Color = BEAM_COLORS[BeamColor.WHITE] # This is the actual colour
var raycast : RayCast2D
var line : Line2D
var last_line_end : Vector2
var width : float = 2.0
var ray_target : Vector2 = Vector2(0, 1) # This can be changed externally

var particle_emitter : GPUParticles2D
var particle_material : ParticleProcessMaterial
var particle_target : Vector2 = Vector2.ZERO
var particle_moving_away : bool = true

var collider : Node2D

var is_reflected : bool = false
var reflected_beam : Node2D # The other beam when reflecting, this will be a child of this node

var is_refracting : bool = false
var refracted_beams : Array = [] # As reflected_beam above
var refracting_prism : Prism

var is_hitting_char : bool = false
var child_beam : Beam = null # In the next level
var parent_beam : Beam = null # In the previous level


func _ready():
	raycast = $RayCast2D
	raycast.target_position = ray_target
	line = $Line2D
	particle_emitter = $ParticleEmitter
	particle_emitter.process_material = particle_emitter.process_material.duplicate()
	particle_material = particle_emitter.process_material
	
	# TODO: Do some kind of particle scaling dependant on beam width here
	particle_material.scale_min = particle_material.scale_min
	particle_material.scale_max = particle_material.scale_max
	
	for exception in ignored_colliders:
		raycast.add_exception(exception)


func _process(_delta):
	# Update in case stuff has changed since _ready
	color = BEAM_COLORS[beam_color]
	line.default_color = color
	particle_material.color = color
	#
	
	# Slide the particle emitter back and forth along the line so the whole
	# thing emits particles
	var pos = particle_emitter.position
	var line_length = line.points[0].distance_to(line.points[-1])
	
	if pos.distance_to(line.points[-1]) >= line_length - 10:
		particle_moving_away = true
		particle_target = line.points[-1]
	if pos.distance_to(line.points[0]) >= line_length - 10:
		particle_moving_away = false
		particle_target = line.points[0]
	
	if (
			pos.distance_to(line.points[-1]) > (line_length / 2) and
			pos.distance_to(line.points[0]) > (line_length / 2)
		) or (
			last_line_end.distance_to(line.points[-1]) >= 10
		):
		particle_emitter.position = Vector2.ZERO
		particle_moving_away = true
		particle_target = line.points[-1]
	
	last_line_end = line.points[-1]
	
	particle_emitter.position = particle_emitter.position.move_toward(particle_target, _delta * 600)


func _physics_process(_delta):
	# Update the target in case its been changed externally
	raycast.target_position = ray_target.normalized() * length
	
	# Draw the line
	line.clear_points()
	line.add_point(raycast.position)
	
	if raycast.is_colliding():
		collider = raycast.get_collider()
		
		if collider not in ignored_colliders:
			# Draw the end of the line
			line.add_point(to_local(raycast.get_collision_point()))
			
			if collider is Reflector:
				if !is_reflected:
					var sound = load("res://sounds/tink.wav")
					Global.queue_sound(collider.audio_player, sound)
				create_reflection()
			else:
				is_reflected = false
			
			if collider is Prism:
				create_refraction(collider)
			else:
				is_refracting = false
			  
			if collider is Goal:
				collider.in_light.emit(self)
			
			if collider is Player:
				if "child_room" in Global.current_room and Global.current_room.child_room is Room:
					create_subroom_beam()
					is_hitting_char = true
			else:
				is_hitting_char = false
		else:
			line.add_point(raycast.target_position)
	else:
		is_reflected = false
		is_refracting = false
		line.add_point(raycast.target_position)
	
	line.width = width
	
	if !is_reflected and reflected_beam:
		reflected_beam.queue_free()
		reflected_beam = null
	
	if !is_refracting and !refracted_beams.is_empty():
		clear_refracting_beams()
	
	if !is_hitting_char and child_beam and !Engine.is_editor_hint():
		Global.current_room.child_room.outside_lights = []
		child_beam.queue_free()
		child_beam = null


func create_subroom_beam():
	#var collision_point = raycast.get_collision_point()
	var collision_normal = raycast.get_collision_normal()
	
	# Create another beam inside the next level
	var outside_lights = Global.current_room.child_room.outside_lights
	var already_exists = -1
	for i in outside_lights.size():
		if outside_lights[i].parent_beam == self:
			already_exists = i
	if already_exists > -1:
		child_beam = outside_lights[already_exists]
	else:
		child_beam = load("res://misc_scenes/beam.tscn").instantiate()
	
	# Create it in the right spot according to which direction the beam is coming from
	# THIS DOESNT WORK
	# THIS IS THE LAST THING YOU WERE WORKING ON
	# TODO: MAKE THIS WORK 
	var new_beam_target = raycast.target_position.normalized()
	var new_beam_position = Vector2.ZERO
	if collision_normal == collider.orientation:
		# Entering from the front
		new_beam_position = get_child_beam_position("front")
		new_beam_target = new_beam_target.rotated(deg_to_rad(90))
	elif -collision_normal == collider.orientation:
		# Entering from the back
		new_beam_position = get_child_beam_position("back")
		new_beam_target = new_beam_target.rotated(deg_to_rad(-90))
	else:
		# Entering from the top
		new_beam_position = get_child_beam_position("top")
	
	child_beam.parent_beam = self
	child_beam.beam_color = beam_color
	child_beam.global_position = new_beam_position
	child_beam.width = width * 3
	child_beam.ray_target = new_beam_target
	child_beam.name = "OutsideBeam" + str(get_instance_id())
	
	if already_exists < 0:
		outside_lights.append(child_beam)


# THIS DOESNT WORK, IT WAS A WIP LAST TIME YOU TOUCHED THIS
func get_child_beam_position(face) -> Vector2:
	var beam_position = Vector2.ZERO
	
	var player_length
	var collision_point
	var player_position
	

	
	if (
		collider.is_on_wall_only() and (face == "front" or face == "back")
		or
		!collider.is_on_wall_only() and face == "top"
	):
		player_position = collider.position.x
		collision_point = raycast.get_collision_point().x
		
		if face == "front" or face == "back":
			player_length = collider.get_glass_size().y
		
		if face == "top":
			player_length = collider.get_glass_size().x
	else:
		player_position = collider.position.y
		collision_point = raycast.get_collision_point().y
		
		if face == "front" or face == "back":
			player_length = collider.get_glass_size().x
		
		if face == "top":
			player_length = collider.get_glass_size().y
	
	var player_side = player_position - (player_length / 2)
	var collision_distance = collision_point - player_side
	var percentage = (collision_distance / player_length) * 100
	
	match face:
		"front":
			beam_position = Vector2(get_viewport().size.x + 50.0, (percentage * get_viewport().size.y) / 100)
		"back":
			beam_position = Vector2(-50.0, (percentage * get_viewport().size.y) / 100)
		"top":
			beam_position = Vector2((percentage * get_viewport().size.x) / 100, -50.0)
	
	return beam_position

# ALSO DOESNT WORK
func get_back_beam_position() -> Vector2:
	var collision_x = raycast.get_collision_point().x
	var player_height = collider.get_glass_size().y
	var player_bottom_side = collider.position.x - (player_height / 2)
	var collision_bottom = collision_x - player_bottom_side
	var percentage = (collision_bottom / player_height) * 100
	var room_height = get_viewport().size.y
	var light_y = (percentage * room_height) / 100
	
	return Vector2(-50.0, light_y)


# ALSO DOESNT WORK
func get_top_beam_position() -> Vector2:
	var collision_x = raycast.get_collision_point().x
	var player_width = collider.get_glass_size().x
	var player_left_side = collider.position.x - (player_width / 2)
	var collision_left = collision_x - player_left_side
	var percentage = (collision_left / player_width) * 100
	var room_width = get_viewport().size.x
	var light_x = (percentage * room_width) / 100
	
	return Vector2(light_x, -50.0)


# Creates a new beam and childs it, angled off of a reflector
func create_reflection():
	# There might already be a reflected beam. If there is, change the angle etc.
	# otherwise create a new one
	if !reflected_beam:
		reflected_beam = load("res://misc_scenes/beam.tscn").instantiate()
		reflected_beam.ignored_colliders = []
		reflected_beam.ignored_colliders.append(collider)
		reflected_beam.width = width
		reflected_beam.beam_color = beam_color
		add_child(reflected_beam)
	
	is_reflected = true
	var collision_point = raycast.get_collision_point()
	var collision_normal = raycast.get_collision_normal().normalized()
	var reflection = raycast.target_position.bounce(collision_normal).normalized() * length
	
	reflected_beam.reflect_beam(collision_point, reflection)


# Misnamed, this is called once a child beam has been created (on the child)
func reflect_beam(collision_point, reflection):
	global_position = collision_point
	ray_target = reflection


func clear_refracting_beams():
	for beam in refracted_beams:
		beam.queue_free()
	refracted_beams = []


# Creates a load of coloured child beams from this beam
func create_refraction(prism : Prism):
	# Start afresh every frame
	if is_refracting and refracting_prism != prism:
		clear_refracting_beams()
	
	is_refracting = true
	refracting_prism = prism
	
	# Prisms only split certain colours
	var valid_colors = prism.color_splits.filter(func(prism_color):
		return prism_color == beam_color or prism_color == BeamColor.WHITE or beam_color == BeamColor.WHITE
	)
	
	var collision_point = raycast.get_collision_point()
	var collision_normal = raycast.get_collision_normal().normalized()
	
	#var reflection_target = raycast.target_position.bounce(collision_normal).normalized()
	#var reflection_angle = collision_normal.angle_to(reflection_target)

	# Where to fire all the coloured beams from
	var prism_collider_width = 1
	if prism.collider.shape.has_method('get_radius'):
		prism_collider_width = prism.collider.shape.get_radius()
	elif prism.collider.shape.has_method('get_width'):
		prism_collider_width = prism.collider.shape.get_width()
	
	# Fire them from the middle of the prism on the same axis as the collision point
	# That didnt make any goddamn sense, just refract something and youll see
	var refraction_origin = collision_point - (collision_normal * prism_collider_width)
	
	# Fire it forwards always (opposite of the where the beam has come in from)
	var refracted_target = -collision_normal
	var step = Vector2.ZERO
	if valid_colors.size() > 1:
		# Split the beams evenly between -20deg and 20deg of the main firing angle
		var min_beam = refracted_target.rotated(deg_to_rad(20))
		var max_beam = refracted_target.rotated(deg_to_rad(-20))
		step = (max_beam - min_beam) / (prism.color_splits.size() - 1)
		refracted_target = min_beam
	
	# Create the beams
	for i in valid_colors.size():
		var split_color = valid_colors[i]
		var refracted_beam
		var new_beam = false
		
		if refracted_beams.size() <= i:
			refracted_beam = load("res://misc_scenes/beam.tscn").instantiate()
			refracted_beams.append(refracted_beam)
			new_beam = true
		else:
			refracted_beam = refracted_beams[i]
		
		refracted_beam.ignored_colliders = []
		refracted_beam.ignored_colliders.append(prism)
		refracted_beam.width = width
		refracted_beam.beam_color = split_color
		
		if new_beam:
			add_child(refracted_beam)
		
		refracted_beam.reflect_beam(refraction_origin, refracted_target)
		refracted_target += step
