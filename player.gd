extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var sprite : AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	sprite = $AnimatedSprite2D


func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var horizontal_direction = Input.get_axis("ui_left", "ui_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if is_on_wall_only():
		var wall_normal = get_wall_normal()
		if wall_normal.x > 0:
			sprite.rotation_degrees = 90
		else:
			sprite.rotation_degrees = -90
	else:
		sprite.rotation_degrees = 0
		
	if is_on_wall():
		var vertical_direction = Input.get_axis("ui_up", "ui_down")
		if vertical_direction:
			velocity.y = vertical_direction * SPEED
		else:
			velocity.y = move_toward(velocity.y, 0, SPEED)
	
		# Add the gravity.
	if not is_on_floor() or is_on_wall():
		velocity.y += gravity * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()
