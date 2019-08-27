extends Reference

# Could create this on a script attached to the Enemy, but this works
# extending Reference means it'll be deallocated from memory once it is no longer referenced
#   though honestly don't 100% understand how it works

# Get a reference to the enemy scene 
const EnemyScene = preload("res://scenes/Enemy.tscn");

var COOLDOWN_TURNS = 2;

var manager;
var cur_sprite;
var tile;
var max_hp;
var hp;
var is_dead = false;
var is_at_player = false;
var is_a_danger = false;
var action_cooldown = 0;
var type = 0;


func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _init(game, mgr, enemy_level, t, x, y):
	manager = mgr;
	type = t;
	match(type):
		manager.EnemyType.Basic:
			COOLDOWN_TURNS = 2;
			is_a_danger = true;
		manager.EnemyType.Blocker:
			COOLDOWN_TURNS = 1;
		
	max_hp = 1 + 2*enemy_level + max(0,pow(2, (type*2))-1);
	hp = max_hp;
	tile = Vector2(x, y);
	cur_sprite = EnemyScene.instance();
	# If using a sprite sheet, this may be different from 0 (ex. a function of enemy_level)
	cur_sprite.frame = type;
	cur_sprite.position = tile * game.level.TILE_SIZE;
	game.add_child(cur_sprite);


func remove():
	# Helps with deallocation of the sprite
	cur_sprite.queue_free();


func take_damage(game, dmg):
	# Just in case
	if (is_dead):
		return;
	
	hp = max(0, hp - dmg); # doesn't go below 0
	cur_sprite.get_node("HP").rect_size.x = game.level.TILE_SIZE * hp / max_hp;
	
	if (hp == 0):
		is_dead = true;
		game.score += 10 * max_hp;


func act(game):
	# If you can't see it, it can't see you
	if (!cur_sprite.visible):
		return;
	
	is_at_player = false;
	action_cooldown -= 1;
	
	var my_point = game.level.entity_pathfinding_graph.get_closest_point(Vector3(tile.x, tile.y, 0));
	var player_point = game.level.entity_pathfinding_graph.get_closest_point(Vector3(game.player.tile.x, game.player.tile.y, 0));
	
	# Try to find a path between the enemy's location and the player
	var path = game.level.entity_pathfinding_graph.get_point_path(my_point, player_point);
	if (path):
		# Must be at least 2 long (enemy tile, *stuff in middle*, player tile)
		assert(path.size() > 1);
		
		# Try to move to the next tile
		var move_tile = Vector2(path[1].x, path[1].y);

		# Check if next to the player
		if (move_tile == game.player.tile):
			is_at_player = true;
			if (type == manager.EnemyType.Basic):
				# if next to the player, deal 1 damage to them
				if (action_cooldown <= 0):
					game.player.damage_player(game, 1);
					action_cooldown = COOLDOWN_TURNS;
		# Not next to the player
		else:
			# If not next to the player, check if another enemy is blocking this enemy's movement
			var is_blocked = false;
			for enemy in game.enemy_manager.enemies:
				if (enemy.tile == move_tile):
					is_blocked = true;
					break;
			
			# If not blocked, move to that tile
			if (!is_blocked):
				if (action_cooldown <= 0):
					tile = move_tile;
					action_cooldown = COOLDOWN_TURNS;
					if (path.size() == 3):
						is_at_player = true;


func is_next_to_player():
	return is_at_player;