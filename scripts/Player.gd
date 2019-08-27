extends Sprite

const PLAYER_START_HP = 5;

var game;
var tile;
var hp;
var is_dead;
var is_ready = false;
var is_danger = false;
var cur_sprite;

onready var idle_blue = $idle_blue;
onready var idle_red = $idle_red;
onready var animate = $AnimationPlayer;


func _ready():
	game = get_parent();


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


func try_move(dx, dy, dir_name):
	var x = tile.x + dx;
	var y = tile.y + dy;
	
	var did_move = false;
	
	var tile_type = game.level.Tile.Stone;
	# Make sure the desired move location is in-bounds for our map array
	if (x >= 0 && x < game.level.size.x && y >= 0 && y < game.level.size.y):
		tile_type = game.level.map[x][y];
	
	turn_sprite(dir_name);
	
	# Match is like a switch/case statement in other languages.
	match tile_type:
		game.level.Tile.Floor:
			# If you try to move onto an Enemy, deal damage to it instead
			# If killed, an enemy will disappear but you'll have to wait a turn to move there
			var is_blocked = false;
			var enemy = game.enemy_manager.get_enemy(x, y);
			if (is_instance_valid(enemy)):
				is_blocked = true;
				# Only deals 1 damage each attack for now
				attack(enemy, 1);
			
			# If you're trying to move onto Floor and there are no enemies, success!
			if (!is_blocked):
				move_to(x, y);
				did_move = true;
		
		game.level.Tile.Door:
			# If you're trying to open a door, you did it!
			# Next turn you can move to where the door was
			game.level.set_tile(x, y, game.level.Tile.Floor);
		
		game.level.Tile.Ladder:
			# Gain 20 points for each level transition
			game.level.level_num += 1;
			game.score += 20;
			# If there are more levels, go to the next one
			if (game.level.level_num < game.level.LEVEL_SIZES.size()):
				game.level.build_level();
			else:
				game.win = true;
	
	return did_move;

func attack(enemy, dmg):
	enemy.take_damage(game, dmg);