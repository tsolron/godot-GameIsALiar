extends Reference

# Could create this on a script attached to the Enemy, but this works
# extending Reference means it'll be deallocated from memory once it is no longer referenced
#   though honestly don't 100% understand how it works

# Get a reference to the enemy scene 
const EnemyScene = preload("res://scenes/Enemy.tscn");
const INFINITY = 3.402823e+38

var COOLDOWN_TURNS = 2;

var game;
var manager;
var cur_sprite;
var tile;
var max_hp = 1;
var hp;
var is_dead = false;
var faction = -1;
var did_move = false;
var path_dist_to_player = 0;
var is_a_danger = false;
var action_cooldown = 0;
var type = 0;


func _ready():
	pass;

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _init(g, mgr, f, enemy_level, t, x, y):
	game = g;
	manager = mgr;
	faction = f;
	type = t;
	
	cur_sprite = EnemyScene.instance();
	cur_sprite.frame = 0;
	cur_sprite.visible = true;
	
	match(type):
		manager.EnemyType.Basic:
			is_a_danger = true;
			COOLDOWN_TURNS = 1;
			max_hp = 1 + 1*enemy_level;
		manager.EnemyType.Blocker:
			is_a_danger = true;
			COOLDOWN_TURNS = 2;
			max_hp = 4 + 2*enemy_level;
		manager.EnemyType.Innocent:
			is_a_danger = false;
			COOLDOWN_TURNS = 2;
			max_hp = 1;
		manager.EnemyType.Trap:
			is_a_danger = true;
			COOLDOWN_TURNS = 1;
			#max_hp
			cur_sprite.frame = 1;
			cur_sprite.visible = false;
			cur_sprite.get_node("HP").visible = false;
			cur_sprite.get_node("HP_Background").visible = false;
	
	action_cooldown = COOLDOWN_TURNS;
	hp = max_hp;
	tile = Vector2(x, y);
	# If using a sprite sheet, this may be different from 0 (ex. a function of enemy_level)
	cur_sprite.position = tile * game.level.TILE_SIZE;
	
	manager.add_child(cur_sprite);


func remove():
	# Helps with deallocation of the sprite
	cur_sprite.queue_free();


func update_health_bar(game):
	if (type == manager.EnemyType.Basic || type == manager.EnemyType.Blocker):
		cur_sprite.get_node("HP").rect_size.x = game.level.TILE_SIZE * hp / max_hp;


func take_damage(game, dmg):
	# Just in case
	if (is_dead):
		return;
	
	hp = max(0, hp - dmg); # doesn't go below 0
	update_health_bar(game);
	
	if (hp == 0):
		is_dead = true;
		game.score += 10 * max_hp;


func act(game):
	# If you can't see it, it can't see you
	if (!cur_sprite.visible && type != manager.EnemyType.Trap):
		return;
	
	path_dist_to_player = INFINITY;
	did_move = false;
	action_cooldown -= 1;
	
	var my_point = game.level.entity_pathfinding_graph.get_closest_point(Vector3(tile.x, tile.y, 0));
	var player_point = game.level.entity_pathfinding_graph.get_closest_point(Vector3(game.player.tile.x, game.player.tile.y, 0));
	
	# Try to find a path between the enemy's location and the player
	var path = game.level.entity_pathfinding_graph.get_point_path(my_point, player_point);
	if (path):
		# Must be at least 2 long (enemy tile, *stuff in middle*, player tile)
		#   Unless it's a trap, then you can be on it
		if (type != manager.EnemyType.Trap):
			assert(path.size() > 1);
		
		path_dist_to_player = path.size() - 1;
		
		if (type == manager.EnemyType.Trap):
			if (path_dist_to_player == 1):
				cur_sprite.visible = true;
			if (path_dist_to_player == 0):
				attack(game.player, 1);
		else:
			var dx = path[1].x - tile.x;
			var dy = path[1].y - tile.y;
			
			var target = game.level.entity_try_move(self, dx, dy);
			#if (is_instance_valid(target) && path.size() == 3):
			#	is_at_player = true;
			if (is_instance_valid(target)):
				# Only deals 1 damage each attack for now
				if (type == manager.EnemyType.Basic):
					# if next to the player, deal 1 damage to them
					if (action_cooldown <= 0):
						action_cooldown = COOLDOWN_TURNS;
						attack(target, 1);
			if (did_move):
				path_dist_to_player -= 1;


func move_to(x, y):
	if (action_cooldown <= 0):
		tile = Vector2(x, y);
		did_move = true;
		action_cooldown = COOLDOWN_TURNS;


func attack(target, dmg):
	if (target.faction != faction):
		target.take_damage(game, dmg);


func get_distance_to_player():
	return path_dist_to_player;