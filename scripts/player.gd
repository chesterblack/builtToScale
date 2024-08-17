class_name Player extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const ROTATE_SPEED = 0.5

var glass_sprite : AnimatedSprite2D
var legs_sprite : AnimatedSprite2D
var reflector_arm : Node2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	reflector_arm = $ReflectorArm
	glass_sprite = $Sprites/Glass
	legs_sprite = $Sprites/Legs


func get_glass_size() -> Vector2:
	return glass_sprite.sprite_frames.get_frame_texture(glass_sprite.animation, glass_sprite.frame).get_size()


func _physics_process(delta):
	movement_control(delta)
	
	reflector_arm.look_at(get_global_mouse_position())
	#var rotation_direction = Input.get_axis("rotate_left", "rotate_right")
	#var rotation_velocity = 0
	#if rotation_direction:
		#rotation_velocity = rotation_direction * ROTATE_SPEED
	#
	#reflector_arm.rotation_degrees += rotation_velocity


func movement_control(delta):
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if is_on_wall_only():
		var wall_normal = get_wall_normal()
		if wall_normal.x > 0:
			$Sprites.rotation_degrees = 90
		else:
			$Sprites.rotation_degrees = -90
	else:
		$Sprites.rotation_degrees = 0
		
	if is_on_wall():
		var vertical_direction = Input.get_axis("move_up", "move_down")
		if vertical_direction:
			velocity.y = vertical_direction * SPEED
		else:
			velocity.y = move_toward(velocity.y, 0, SPEED)
	
	if not is_on_floor() or is_on_wall():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()
