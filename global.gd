extends Node

signal win
signal next_level

signal zoom_in
signal zoom_out

var backing_tracks : Array[AudioStream] = []
var audio_player : AudioStreamPlayer2D
var track_playing : int

var current_room : Room
var goals : Array[Goal] = []
var transition_sprite : AnimatedSprite2D
var playing_forwards : bool
var can_transition : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	backing_tracks.append(load("res://sounds/ambience3.wav"))
	backing_tracks.append(load("res://sounds/ambience2.wav"))
	
	track_playing = 0
	audio_player.stream = backing_tracks[track_playing]
	audio_player.play()
	audio_player.finished.connect(_on_audio_player_finished)
	
	var transition_canvas = CanvasLayer.new()
	transition_sprite = load("res://misc_scenes/transition.tscn").instantiate()
	transition_sprite.visible = false
	transition_canvas.add_child(transition_sprite)
	add_child(transition_canvas)
	
	next_level.connect(_on_next_level)
	zoom_in.connect(_on_zoom_in)
	zoom_out.connect(_on_zoom_out)
	
	for child in get_node("/root").get_children():
		if child is Room:
			current_room = child
			break


func _process(_delta):
	if transition_sprite.is_playing():
		if can_transition and transition_sprite.frame == 20:
			can_transition = false
			if playing_forwards:
				current_room.can_zoom_in.emit()
			else:
				current_room.can_zoom_out.emit()
	
	var can_win = true
	if goals:
		for goal in goals:
			if !goal.is_lit:
				can_win = false
		
		if can_win:
			win.emit()


func _on_audio_player_finished():
	track_playing += 1
	if track_playing >= backing_tracks.size():
		track_playing = 0
	
	audio_player.stream = backing_tracks[track_playing]
	audio_player.play()


func _on_zoom_in():
	can_transition = true
	playing_forwards = true
	transition_sprite.visible = true
	transition_sprite.play("jump")


func _on_zoom_out():
	can_transition = true
	playing_forwards = false
	transition_sprite.visible = true
	transition_sprite.play_backwards("jump")


func _on_next_level(next_scene):
	if !next_scene:
		return
	
	goals = []
	current_room.get_parent().remove_child(current_room)
	current_room.queue_free()
	
	current_room = next_scene.instantiate()
	get_parent().add_child(current_room)


func queue_sound(audio_player : AudioStreamPlayer2D, sound : AudioStream):
	if !audio_player.is_playing():
		audio_player.stream = sound
		audio_player.play()


func force_sound(audio_player : AudioStreamPlayer2D, sound : AudioStream):
	audio_player.stop()
	audio_player.stream = sound
	audio_player.play()
