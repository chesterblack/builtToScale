extends Button

var next_level : String


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():
	Global.next_level.emit(load(next_level))
