extends Sprite

const PLAYER_START_HP = 5;

var tile;
var hp;
var is_dead;
var is_ready = false;
var is_danger = false;
var cur_sprite;

onready var idle_blue = $idle_blue;
onready var idle_red = $idle_red;
onready var animate = $AnimationPlayer;


func start_game():
	hp = PLAYER_START_HP;
	is_dead = false;
	is_ready = false;
	cur_sprite = idle_blue;


func update_danger():
	match(is_danger):
		(true):
			switch_sprite(idle_red);
		(false):
			switch_sprite(idle_blue);


func switch_sprite(new_sprite):
	if (cur_sprite == new_sprite):
		return;
	
	new_sprite.flip_h = cur_sprite.flip_h;
	cur_sprite.visible = false;
	new_sprite.visible = true;
	animate.set_current_animation(new_sprite.name);
	cur_sprite = new_sprite;


func turn_sprite(dir_name):
	if (dir_name == "left"):
		#self.flip_h = true;
		cur_sprite.flip_h = true;
	elif (dir_name == "right"):
		#self.flip_h = false;
		cur_sprite.flip_h = false;


func move_to(x, y):
	tile = Vector2(x, y);


func damage_player(game, dmg):
	# Don't go below 0 hp
	hp = max(0, hp - dmg);
	if (hp == 0):
		is_dead = true;
