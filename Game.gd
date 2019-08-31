extends Node2D

#const Player = preload("scripts/Player.gd");
#const EnemyManager = preload("scripts/EnemyManager.gd");

# 0 is the first level
const LEVEL_START = 0;

enum Faction {Player, Enemy};

# Get nodes but after they exist
onready var level = $Level;
onready var enemy_manager = $EnemyManager;
onready var player = $Player;
onready var ui = $UI;
onready var audio = $Audio;

var score = 0;
var win = false;
var pause_input = false;
#var enemy_manager = EnemyManager.new();
var ready_to_calc_fog = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	#OS.set_window_size(Vector2(1280, 720));
	randomize();
	# Build first level
	start_game();
	#update_visuals();


# Auto called whenever there's an input event
func _input(event):
	# Ignore events that aren't key presses
	if (!event.is_pressed()):
		return;
	
	if (event.is_action("Exit")):
		ui.show_exit();
	
	if (ui.is_message_open || pause_input):
		return;
	# If one of our input actions, do that action.
	# Note that key binds are in project settings, these are just the actions those bind to
	var did_try_move = false;
# warning-ignore:unused_variable
	var did_move = false;
	if (event.is_action("Wait")):
		did_try_move = true;
	if (event.is_action("Left")):
		did_move = player.try_move(-1, 0, "left");
		did_try_move = true;
	if (event.is_action("Right")):
		did_move = player.try_move(1, 0, "right");
		did_try_move = true;
	if (event.is_action("Up")):
		did_move = player.try_move(0, -1, "up");
		did_try_move = true;
	if (event.is_action("Down")):
		did_move = player.try_move(0, 1, "down");
		did_try_move = true;
	
	# Whenever the player moves, the game progresses one tick (ex. enemies move)
	if (did_try_move):
		tick();


# warning-ignore:unused_argument
func _process(delta):
	update_visuals();


func tick():
	if (player.player_has_moved):
		enemy_manager.tick();
	
	if (check_for_win()):
		#score += 1000;
		ui.show_win();
	if (check_for_lose()):
		ui.show_lose();
	
	#call_deferred("update_visuals");
	#update_visuals();


func update_visuals():
	if (!is_instance_valid(player)):
		return;
	if (player.move_anim.current_animation == ""):
		player.position = player.tile * level.TILE_SIZE;
		player.ready_to_calc_fog = true;
	
	ui.update(self);
	
	var player_center = tile_to_pixel_center(player.tile.x, player.tile.y);
	var space_state = get_world_2d().direct_space_state;
	
	enemy_manager.update_enemy_visuals(player_center, space_state);
	
	if (check_if_fog_ready()):
		level.update_fog(player_center, space_state);

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
	audio.start_game();
	# Waits one frame before calling update_visuals() so all objects exist at first run
	#update_visuals();
	call_deferred("update_visuals");


func tile_to_pixel_center(x, y):
	return Vector2((x + 0.5) * level.TILE_SIZE, (y + 0.5) * level.TILE_SIZE);


func check_if_fog_ready():
	ready_to_calc_fog = true;
	if (!player.ready_to_calc_fog):
		ready_to_calc_fog = false;
	if (!level.ready_to_calc_fog):
		ready_to_calc_fog = false;
	return ready_to_calc_fog;


func _on_ResetBtn_pressed():
	start_game();

