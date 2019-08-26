extends Sprite

const PLAYER_START_HP = 5;

var tile;
var hp;
var is_dead;
var is_ready = false;


func start_game():
	hp = PLAYER_START_HP;
	is_dead = false;
	is_ready = false;


func turn_sprite(dir_name):
	if (dir_name == "left"):
		self.flip_h = true;
	elif (dir_name == "right"):
		self.flip_h = false;


func move_to(x, y):
	tile = Vector2(x, y);


func damage_player(game, dmg):
	# Don't go below 0 hp
	hp = max(0, hp - dmg);
	if (hp == 0):
		is_dead = true;
