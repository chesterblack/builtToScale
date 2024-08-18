class_name Player extends CharacterBody2D

signal pickup_entered
signal pickup_exited

const SPEED = 250.0
const SLOW_SPEED = 15.0
const JUMP_VELOCITY = -400.0
const ROTATE_SPEED = 0.5

var glass_sprite : AnimatedSprite2D
var legs_sprite : AnimatedSprite2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var rotation_locked : bool = false
var control_arm : Node2D
var held_item : Node2D
var held_pickup : Pickup
var pickup_in_range : Pickup


func _ready():
	control_arm = $ControlArm
	glass_sprite = $Sprites/Glass
	legs_sprite = $Sprites/Legs
	
	pickup_entered.connect(_on_pickup_entered)
	pickup_exited.connect(_on_pickup_exited)


func _process(_delta):
	if Input.is_action_just_pressed("pickup"):
		if pickup_in_range:
			pick_up_item(pickup_in_range)
		else:
			drop_item()


func _physics_process(delta):
	movement_control(delta)
	
	if Input.is_action_just_pressed("lock_rotation"):
		rotation_locked = !rotation_locked
	
	if !rotation_locked:
		control_arm.look_at(get_global_mouse_position())


func _on_pickup_entered(item_pickup : Pickup):
	pickup_in_range = item_pickup


func _on_pickup_exited():
	pickup_in_range = null


func pick_up_item(item_pickup : Pickup):
	# Drop whatever you're holding first
	drop_item()
	
	# Swap the actual item from the pickup to the control arm
	var item = item_pickup.item
	item.get_parent().remove_child(item)
	control_arm.add_child(item)
	item.position = Vector2(30, 0)
	item.rotation_degrees = 90
	
	# Orphan the pickup. Don't delete it, as we'll reparent it when dropping
	item_pickup.get_parent().remove_child(item_pickup)
	
	held_pickup = item_pickup
	held_item = item


func drop_item():
	print("dropping ", held_item)
	if !held_item:
		return
	
	# Swap the item from the control arm back to the original pickup
	control_arm.remove_child(held_item)
	held_pickup.add_child(held_item)
	held_item.position = Vector2.ZERO
	held_item.rotation_degrees = 0
	
	# Add the pickup back into the world
	held_pickup.global_position = Vector2(global_position.x, global_position.y - 35)
	get_parent().add_child(held_pickup)
	
	# Lob it
	var throw_vector = global_position.direction_to(get_global_mouse_position()).normalized() * 450
	held_pickup.apply_impulse(throw_vector)
	held_pickup.apply_torque_impulse(throw_vector.normalized().x * randf_range(200, 1000))
	
	held_item = null
	held_pickup = null


func movement_control(delta):
	var move_speed = SPEED
	if Input.is_action_pressed("slow_walk"):
		move_speed = SLOW_SPEED
	
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
	
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
			velocity.y = vertical_direction * move_speed
		else:
			velocity.y = move_toward(velocity.y, 0, move_speed)
	
	if not is_on_floor() or is_on_wall():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()


func get_glass_size() -> Vector2:
	return glass_sprite.sprite_frames.get_frame_texture(glass_sprite.animation, glass_sprite.frame).get_size()
