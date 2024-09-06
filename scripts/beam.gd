@tool

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
@export var beam_color : BeamColor = BeamColor.WHITE

var color : Color = BEAM_COLORS[BeamColor.WHITE]
var raycast : RayCast2D
var line : Line2D
var last_line_end : Vector2
var width : float = 2.0
var ray_target : Vector2 = Vector2(0, 1)

var particle_emitter : GPUParticles2D
var particle_material : ParticleProcessMaterial
var particle_target : Vector2 = Vector2.ZERO
var particle_moving_away : bool = true

var collider : Node2D

var is_reflected : bool = false
var reflected_beam : Node2D

var is_refracting : bool = false
var refracted_beams : Array = []
var refracting_lens : Lens

var is_hitting_char : bool = false
var child_beam : Beam = null
var parent_beam : Beam = null


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
	color = BEAM_COLORS[beam_color]
	line.default_color = color
	particle_material.color = color
	
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
	raycast.target_position = raycast.target_position.normalized() * length
	
	line.clear_points()
	line.add_point(raycast.position)
	
	if raycast.is_colliding():
		collider = raycast.get_collider()
		
		if collider not in ignored_colliders:
			line.add_point(to_local(raycast.get_collision_point()))
			
			if collider is Reflector:
				if !is_reflected:
					var sound = load("res://sounds/tink.wav")
					Global.queue_sound(collider.audio_player, sound)
				create_reflection()
			else:
				is_reflected = false
			
			if collider is Lens:
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
	var collision_point = raycast.get_collision_point()
	
	var collision_x = collision_point.x
	var player_width = collider.get_glass_size().x
	var player_left_side = collider.position.x - (player_width / 2)
	var collision_left = collision_x - player_left_side
	var percentage = (collision_left / player_width) * 100
	var room_width = get_viewport().size.x
	var light_x = (percentage * room_width) / 100
	
	var outside_lights = Global.current_room.child_room.outside_lights
	var already_exists = -1
	for i in outside_lights.size():
		if outside_lights[i].parent_beam == self:
			already_exists = i
	if already_exists > -1:
		child_beam = outside_lights[already_exists]
	else:
		child_beam = load("res://misc_scenes/beam.tscn").instantiate()
	
	child_beam.parent_beam = self
	child_beam.beam_color = beam_color
	child_beam.global_position = Vector2(light_x, -50.0)
	child_beam.width = width * 3
	child_beam.ray_target = raycast.target_position.normalized()
	child_beam.name = "OutsideBeam" + str(get_instance_id())
	
	if already_exists < 0:
		outside_lights.append(child_beam)


func create_reflection():
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


func reflect_beam(collision_point, reflection):
	global_position = collision_point
	raycast.target_position = reflection


func clear_refracting_beams():
	for beam in refracted_beams:
		beam.queue_free()
	refracted_beams = []


func create_refraction(lens : Lens):
	if is_refracting and refracting_lens != lens:
		clear_refracting_beams()
	
	is_refracting = true
	refracting_lens = lens
	
	var valid_colors = lens.color_splits.filter(func(lens_color):
		return lens_color == beam_color or lens_color == BeamColor.WHITE or beam_color == BeamColor.WHITE
	)
	
	var collision_point = raycast.get_collision_point()
	var collision_normal = raycast.get_collision_normal().normalized()
	
	var reflection_target = raycast.target_position.bounce(collision_normal).normalized()
	#var reflection_angle = collision_normal.angle_to(reflection_target)

	var lens_collider_width = 1
	if lens.collider.shape.has_method('get_radius'):
		lens_collider_width = lens.collider.shape.get_radius()
	elif lens.collider.shape.has_method('get_width'):
		lens_collider_width = lens.collider.shape.get_width()
	var refraction_origin = collision_point - (collision_normal * lens_collider_width)
	
	var refracted_target = -collision_normal
	var step = Vector2.ZERO
	if valid_colors.size() > 1:
		var min_beam = refracted_target.rotated(deg_to_rad(20))
		var max_beam = refracted_target.rotated(deg_to_rad(-20))
		step = (max_beam - min_beam) / (lens.color_splits.size() - 1)
		refracted_target = min_beam
	
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
		refracted_beam.ignored_colliders.append(lens)
		refracted_beam.width = width
		refracted_beam.beam_color = split_color
		
		if new_beam:
			add_child(refracted_beam)
		
		refracted_beam.reflect_beam(refraction_origin, refracted_target)
		refracted_target += step
