extends Reference

# Could create this on a script attached to the Enemy, but this works
# extending Reference means it'll be deallocated from memory once it is no longer referenced
#   though honestly don't 100% understand how it works

# Get a reference to the enemy scene 
const EnemyScene = preload("res://scenes/Enemy.tscn");

var sprite_node;
var tile;
var max_hp;
var hp;
var is_dead = false;


func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _init(game, enemy_level, x, y):
	max_hp = 1 + enemy_level * 2;
	hp = max_hp;
	tile = Vector2(x, y);
	sprite_node = EnemyScene.instance();
	# If using a sprite sheet, this may be different from 0 (ex. a function of enemy_level)
	sprite_node.frame = 0;
	sprite_node.position = tile * game.TILE_SIZE;
	game.add_child(sprite_node);


func remove():
	# Helps with deallocation of the sprite
	sprite_node.queue_free();


func take_damage(game, dmg):
	# Just in case
	if (is_dead):
		return;
	
	hp = max(0, hp - dmg); # doesn't go below 0
	sprite_node.get_node("HP").rect_size.x = game.TILE_SIZE * hp / max_hp;
	
	if (hp == 0):
		is_dead = true;
		game.score += 10 * max_hp;


func act(game):
	# If you can't see it, it can't see you
	if (!sprite_node.visible):
		return;
	var my_point = game.enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y, 0));
	var player_point = game.enemy_pathfinding.get_closest_point(Vector3(game.player_tile.x, game.player_tile.y, 0));
	# Try to find a path between the enemy's location and the player
	var path = game.enemy_pathfinding.get_point_path(my_point, player_point);
	if (path):
		# Must be at least 2 long (enemy tile, *stuff in middle*, player tile)
		assert(path.size() > 1);
		
		# Try to move to the next tile
		var move_tile = Vector2(path[1].x, path[1].y);
		
		if (move_tile == game.player_tile):
			# if next to the player, deal 1 damage to them
			game.damage_player(1);
		else:
			# If not next to the player, check if another enemy is blocking this enemy's movement
			var is_blocked = false;
			for enemy in game.enemies:
				if (enemy.tile == move_tile):
					is_blocked = true;
					break;
			
			# If not blocked, move to that tile
			if (!is_blocked):
				tile = move_tile;