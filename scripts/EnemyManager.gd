extends Node

const Enemy = preload("Enemy.gd");

enum EnemyType {Basic, Blocker};

var game;
var enemies = [];
var num_enemies = 0;


func _ready():
	game = get_parent();


func tick():
	game.player.is_danger = false;
	for enemy in enemies:
		if (enemy.is_dead):
			enemy.remove();
			enemies.erase(enemy);
			break;
		
		enemy.act(game);
		
		if (enemy.is_next_to_player() && enemy.is_a_danger):
			game.player.is_danger = true;
	
	game.player.update_danger();


func add_to_level(n):
	num_enemies = n;
	
	for enemy in enemies:
		enemy.remove();
	enemies.clear();
	
	# Place enemies in the level
	var enemies_to_place = num_enemies;
	while (enemies_to_place > 0):
		var pos = game.level.get_random_location_for_entity();
		
		# And confirm no enemies are already on the chosen tile
		var blocked = false;
		for enemy in enemies:
			if (enemy.tile.x == pos.x && enemy.tile.y == pos.y):
				blocked = true;
				break;
		
		# If it is blocked, it's skipped. Could change this to re-pick locations until a valid spot is found
		if (!blocked):
			enemies_to_place -= 1;
			var enemy = Enemy.new(game, self, 0, (randi() % EnemyType.size()), pos.x, pos.y);
			enemies.append(enemy);


func get_enemy(x, y):
	for enemy in enemies:
		if (enemy.tile.x == x && enemy.tile.y == y):
			return enemy;
	return null;


func update_enemy_visuals(player_center, space_state):
	# Update enemy sprite locations
	for enemy in enemies:
		enemy.cur_sprite.position = enemy.tile * game.level.TILE_SIZE;
		if (!enemy.cur_sprite.visible):
			var enemy_center = game.tile_to_pixel_center(enemy.tile.x, enemy.tile.y);
			var occlusion = space_state.intersect_ray(player_center, enemy_center);
			if (!occlusion):
				enemy.cur_sprite.visible = true;