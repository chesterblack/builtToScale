extends Node

signal win
signal next_level

signal zoom_in
signal zoom_out

var backing_tracks : Array[AudioStream] = []
var audio_player : AudioStreamPlayer2D
var track_playing : int

var current_level : int = 1
var current_room : Room = null
var goals : Array[Goal] = []
var transition_sprite : AnimatedSprite2D
var playing_forwards : bool
var can_transition : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Music
	# This happens here cos ive got to load it, probs a better way of doing this
	backing_tracks.append(load("res://sounds/ambience3.wav"))
	backing_tracks.append(load("res://sounds/ambience2.wav"))
	
	# Play the first track and set up the queueing for the next one
	track_playing = 0
	audio_player.stream = backing_tracks[track_playing]
	audio_player.play()
	audio_player.finished.connect(_on_audio_player_finished)
	
	# This is for zooming in and out, its loading in the jumping animation for later
	# and then hiding it so we can just show/hide it when needed
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
	#current_room.get_node("LevelLabel").text = str(current_level)
	
	# This gets triggered by THIS SCRIPTs _on_zoom_in, and triggers the ROOMs zoom_in
	# idk why im  doing it like this where no one script is responsible but it
	# throws the ball back and forth, sorry
	if transition_sprite.is_playing():
		if can_transition and transition_sprite.frame == 20:
			can_transition = false
			if playing_forwards:
				current_room.can_zoom_in.emit()
			else:
				current_room.can_zoom_out.emit()
	
	# Assume we're winning and change that as soon as we find an inactive goal
	var can_win = true
	if goals:
		for goal in goals:
			if !goal.is_lit:
				can_win = false
		
		if can_win:
			win.emit()


# Alternate through each available backing track
func _on_audio_player_finished():
	track_playing += 1
	if track_playing >= backing_tracks.size():
		track_playing = 0
	
	audio_player.stream = backing_tracks[track_playing]
	audio_player.play()


# The actual zoom in/out happesn in _process, cos we're waiting for the transition
# animation to finish playing (bad way of doing it)
func _on_zoom_in():
	can_transition = true
	playing_forwards = true
	transition_sprite.visible = true
	transition_sprite.play("jump")
	current_level += 1


func _on_zoom_out():
	can_transition = true
	playing_forwards = false
	transition_sprite.visible = true
	transition_sprite.play_backwards("jump")
	current_level -= 1


# Remove the current room from the tree and swap in the child room
func _on_next_level(next_scene):
	if !next_scene:
		return
	
	goals = []
	current_room.get_parent().remove_child(current_room)
	current_room.queue_free()
	
	current_room = next_scene.instantiate()
	get_parent().add_child(current_room)
	
	#current_room.get_node("LevelLabel").text = str(current_level)


# These two are used by loads of nodes to play sounds on their own audio player
func queue_sound(player : AudioStreamPlayer2D, sound : AudioStream):
	if !player.is_playing():
		player.stream = sound
		player.play()

func force_sound(player : AudioStreamPlayer2D, sound : AudioStream):
	player.stop()
	player.stream = sound
	player.play()
