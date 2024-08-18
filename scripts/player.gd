class_name Player extends CharacterBody2D

signal pickup_entered
signal pickup_exited

const SPEED = 250.0
const SLOW_SPEED = 15.0
const JUMP_VELOCITY = -400.0
const ROTATE_SPEED = 0.5

@onready var audio_player : AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var glass_sprite : AnimatedSprite2D = $Sprites/Glass
@onready var legs_sprite : AnimatedSprite2D = $Sprites/Legs
@onready var control_arm : Node2D = $ControlArm

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_move : bool = true
var rotation_locked : bool = false
var is_walking : bool = false
var footstep : bool = false
var grounded : bool = true

var held_item : Node2D
var held_pickup : Pickup
var pickup_in_range : Pickup


func _ready():
	pickup_entered.connect(_on_pickup_entered)
	pickup_exited.connect(_on_pickup_exited)
	Global.win.connect(_on_win)


func _process(_delta):
	if is_on_floor() or is_on_wall():
		if !grounded:
			var land_sound = load("res://sounds/land.wav")
			Global.force_sound(audio_player, land_sound)
		grounded = true
	else:
		grounded = false
	
	if Input.is_action_just_pressed("pickup"):
		if pickup_in_range:
			pick_up_item(pickup_in_range)
		else:
			drop_item()
	
	if is_walking:
		var footstep_sound
		if footstep:
			footstep_sound = load("res://sounds/footstep_shaker.wav")
		else:
			footstep_sound = load("res://sounds/footstep2_shaker.wav")
		
		if !audio_player.is_playing():
			footstep = !footstep
		
		Global.queue_sound(audio_player, footstep_sound)


func _physics_process(delta):
	movement_control(delta)
	
	if Input.is_action_just_pressed("lock_rotation") and can_move:
		rotation_locked = !rotation_locked
	
	if !rotation_locked:
		control_arm.look_at(get_global_mouse_position())


func _on_pickup_entered(item_pickup : Pickup):
	pickup_in_range = item_pickup
	
	var action_events = InputMap.action_get_events("pickup")[0]
	var key_string = OS.get_keycode_string(action_events.physical_keycode)
	Global.current_room.button_prompt_label.text = "Press " + key_string + " to pick up " + item_pickup.item.name


func _on_pickup_exited():
	pickup_in_range = null
	
	Global.current_room.button_prompt_label.text = ""


func _on_win():
	immobilise()


func immobilise():
	rotation_locked = true
	can_move = false


func mobilise():
	rotation_locked = false
	can_move = true


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
	if !held_item:
		return
	
	Global.force_sound(audio_player, load("res://sounds/throw.wav"))
	
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
	is_walking = false
	
	if !can_move:
		return
	
	var move_speed = SPEED
	if Input.is_action_pressed("slow_walk"):
		move_speed = SLOW_SPEED
	
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	if horizontal_direction:
		velocity.x = horizontal_direction * move_speed
		if is_on_floor_only():
			is_walking = true
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
			if is_on_wall_only():
				is_walking = true
		else:
			velocity.y = move_toward(velocity.y, 0, move_speed)
	
	if not is_on_floor() or is_on_wall():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var jump_sound = load("res://sounds/jump.wav")
		Global.force_sound(audio_player, jump_sound)
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()


func get_glass_size() -> Vector2:
	return glass_sprite.sprite_frames.get_frame_texture(glass_sprite.animation, glass_sprite.frame).get_size()
