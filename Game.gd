extends Node2D

#const Player = preload("scripts/Player.gd");

enum EnemyType {Basic, Blocker};

# Get nodes but after they exist
onready var level = $Level;
onready var player = $Player;
onready var ui = $UI;

var score = 0;
var win = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_size(Vector2(1280, 720));
	#player = Player.new();
	randomize();
	# Build first level
	start_game();


# Auto called whenever there's an input event
func _input(event):
	# Ignore events that aren't key presses
	if (!event.is_pressed()):
		return;
	
	if (ui.is_message_open):
		return;
	
	# If one of our input actions, do that action.
	# Note that key binds are in project settings, these are just the actions those bind to
	var did_try_move = false;
	var did_move = false;
	if (event.is_action("Wait")):
		did_try_move = true;
	if (event.is_action("Left")):
		did_move = level.try_move(-1, 0, "left");
		did_try_move = true;
	if (event.is_action("Right")):
		did_move = level.try_move(1, 0, "right");
		did_try_move = true;
	if (event.is_action("Up")):
		did_move = level.try_move(0, -1, "up");
		did_try_move = true;
	if (event.is_action("Down")):
		did_move = level.try_move(0, 1, "down");
		did_try_move = true;
	
	# Whenever the player moves, the game progresses one tick (ex. enemies move)
	if (did_try_move):
		tick();


func tick():
	level.tick();
	
	if (check_for_win()):
		# Gain 1000 points for reaching the end of the game
		score += 1000;
		ui.show_win();
	if (check_for_lose()):
		ui.show_lose();


func check_for_win():
	return win;


func check_for_lose():
	if (player.is_dead):
		return true;
	
	return false;

func start_game():
	score = 0;
	level.start_game();
	player.start_game();
	ui.start_game();


func _on_ResetBtn_pressed():
	start_game();


