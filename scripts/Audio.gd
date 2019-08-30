extends Node2D

onready var music = $AudioStreamPlayer;

var play_music = false;


func _ready():
	pass # Replace with function body.


# warning-ignore:unused_argument
func _process(delta):
	if (!music.playing && play_music):
		music.play();


func start_game():
	play_music = true;