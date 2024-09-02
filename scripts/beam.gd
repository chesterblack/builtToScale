@tool

class_name Beam extends Node2D

enum BeamColor { WHITE, GOLD, BLUE, PINK, GREEN }

const BEAM_COLORS = [
	Color("#ffffff"),
	Color("#e9b042"),
	Color("#3d89b3"),
	Color("#f0657a"),
	Color("#8beb50")
]

@export var ignored_colliders : Array
@export var length : float = 1000.0
@export var beam_color : BeamColor = BeamColor.WHITE

var color : Color = BEAM_COLORS[BeamColor.WHITE]
var raycast : RayCast2D
var line : Line2D
var is_reflected : bool = false
var reflected_beam : Node2D
var collider : Node2D
var width : float = 2.0
var particle_emitter : GPUParticles2D
var particle_target : Vector2 = Vector2.ZERO
var particle_moving_away : bool = true
var last_line_end : Vector2
var particle_material : ParticleProcessMaterial


func _ready():
	raycast = $RayCast2D
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
	
	#if particle_target:
		#particle_emitter.position += position + (line.points[-1] / 100)
	#else:
		#particle_emitter.position += position - (line.points[-1] / 100)



func _physics_process(_delta):
	raycast.target_position = raycast.target_position.normalized() * length
	
	line.clear_points()
	line.add_point(raycast.position)
	
	if raycast.is_colliding():
		collider = raycast.get_collider()
		#$Label.text = str(collider) + "\n" + str(ignored_colliders)
		line.add_point(to_local(raycast.get_collision_point()))
		
		if collider not in ignored_colliders and collider is Reflector:
			if !is_reflected:
				var sound = load("res://sounds/tink.wav")
				Global.queue_sound(collider.audio_player, sound)
			create_reflection()
		else:
			is_reflected = false
		  
		if collider is Goal:
			collider.in_light.emit(self)
		
		if collider is Player:
			if "child_room" in Global.current_room and Global.current_room.child_room is Room:
				create_subroom_beam()
	else:
		is_reflected = false
		line.add_point(raycast.target_position)
	
	line.width = width
	
	if !is_reflected and reflected_beam:
		reflected_beam.queue_free()
		reflected_beam = null


func create_subroom_beam():
	var collision_point = raycast.get_collision_point()
	
	var collision_x = collision_point.x
	var player_width = collider.get_glass_size().x
	var player_left_side = collider.position.x - (player_width / 2)
	var collision_left = collision_x - player_left_side
	var percentage = (collision_left / player_width) * 100
	var room_width = get_viewport().size.x
	var light_x = (percentage * room_width) / 100
	
	var child_beam = Beam.new()
	
	Global.current_room.child_room.outside_light_location = Vector2(light_x, -50.0)
	Global.current_room.child_room.outside_light_angle = raycast.target_position
	Global.current_room.child_room.outside_light_width = width * 3


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
