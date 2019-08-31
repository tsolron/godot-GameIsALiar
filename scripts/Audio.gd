extends Node2D

onready var music = $AudioStreamPlayer;

var play_music = false;
var is_muted = false;


func _ready():
	pass # Replace with function body.


# warning-ignore:unused_argument
func _process(delta):
	if (!music.playing && play_music && !is_muted):
		music.play();
	if (music.playing && is_muted):
		music.stop();


func start_game():
		play_music = true;


func mute():
	is_muted = true;


func unmute():
	is_muted = false;