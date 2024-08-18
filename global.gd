extends Node

signal win
signal next_level

var current_room : Room

# Called when the node enters the scene tree for the first time.
func _ready():
	next_level.connect(_on_next_level)
	for child in get_node("/root").get_children():
		if child is Room:
			current_room = child
			break
	print(current_room)


func _on_next_level():
	pass


func queue_sound(audio_player : AudioStreamPlayer2D, sound : AudioStream):
	if !audio_player.is_playing():
		audio_player.stream = sound
		audio_player.play()


func force_sound(audio_player : AudioStreamPlayer2D, sound : AudioStream):
	audio_player.stop()
	audio_player.stream = sound
	audio_player.play()
