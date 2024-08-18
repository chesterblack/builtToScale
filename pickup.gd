class_name Pickup extends RigidBody2D

@export var item : Node2D
var pickup_radius : Area2D

func _ready():
	pickup_radius = $PickupRadius
	
	pickup_radius.body_entered.connect(_on_body_entered)
	pickup_radius.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body is Player:
		body.pickup_entered.emit(self)


func _on_body_exited(body):
	if body is Player:
		body.pickup_exited.emit()
