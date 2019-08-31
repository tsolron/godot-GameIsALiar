extends Node

#const EnemyTemplate = preload("Enemy.gd");
const EnemyTemplate = preload("res://scenes/EnemyTemplate.tscn");
#onready var EnemyTemplate = $EnemyTemplate;

enum EnemyType {Basic, Blocker, Innocent, Trap};

var game;
var enemies = [];
var num_enemies = 0;


func _ready():
	game = get_parent();


# warning-ignore:unused_argument
func _process(delta):
	for enemy in enemies:
		if (enemy.is_dead):
			enemy.remove();
			enemies.erase(enemy);
			break;


func tick():
	#game.player.is_danger = false;
	for enemy in enemies:
		if (enemy.is_dead):
			enemy.remove();
			enemies.erase(enemy);
			break;
		
		if (!enemy.is_dying):
			enemy.act(game);
			
			if (enemy.is_a_danger && enemy.get_distance_to_player() <= 1):
				game.player.is_danger = true;
	
	game.player.update_danger();


func load_from_tileset(tileset):
	num_enemies = 0;
	
	for enemy in enemies:
		enemy.remove();
	enemies.clear();
	
	# Place enemies in the level
	for x in range(game.level.size.x):
		for y in range(game.level.size.y):
			var cur_tile = tileset.get_cell(x, y);
			if (cur_tile >= 0):
				var pos = Vector2(x, y);
				
				if (cur_tile == 4):
					game.player.move_to(pos, 'teleport');
					game.player.visible = true;
				
				# And confirm no enemies are already on the chosen tile
				var blocked = false;
				for enemy in enemies:
					if (enemy.tile.x == pos.x && enemy.tile.y == pos.y):
						blocked = true;
						break;
				if (game.player.tile.x == pos.x && game.player.tile.y == pos.y):
					blocked = true;
				
				# If it is blocked, it's skipped. Could change this to re-pick locations until a valid spot is found
				if (!blocked):
					#var enemy = Enemy.new(game, self, game.Faction.Enemy, 0, (randi() % EnemyType.size()), pos.x, pos.y);
					#var enemy = EnemyTemplate.instance();
					#var enemy = EnemyTemplate.new(game, self, game.Faction.Enemy, 0, cur_tile, pos.x, pos.y);
					var enemy = EnemyTemplate.instance();
					enemy.init(game, self, game.Faction.Enemy, 0, cur_tile, pos.x, pos.y);
					enemies.append(enemy);
	
	tileset.visible = false;

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
		
		if (game.player.tile.x == pos.x && game.player.tile.y == pos.y):
			blocked = true;
		
		# If it is blocked, it's skipped. Could change this to re-pick locations until a valid spot is found
		if (!blocked):
			enemies_to_place -= 1;
			#var enemy = EnemyTemplate.new(game, self, game.Faction.Enemy, 0, (randi() % EnemyType.size()), pos.x, pos.y);
			var enemy = EnemyTemplate.instance();
			enemy.init(game, self, game.Faction.Enemy, 0, (randi() % EnemyType.size()), pos.x, pos.y);
			enemies.append(enemy);


func get_enemy_blocking_movement(x, y):
	for enemy in enemies:
		if (enemy.tile.x == x && enemy.tile.y == y):
			if (enemy.type != EnemyType.Trap):
				return enemy;
	return null;


func update_enemy_visuals(player_center, space_state):
	# Update enemy sprite locations
	for enemy in enemies:
		enemy.cur_sprite.position = enemy.tile * game.level.TILE_SIZE;
		if (!enemy.cur_sprite.visible && enemy.type != EnemyType.Trap):
			var enemy_center = game.tile_to_pixel_center(enemy.tile.x, enemy.tile.y);
			var occlusion = space_state.intersect_ray(player_center, enemy_center, [game.player], game.level.tile_map.collision_mask);
			if (!occlusion):
				enemy.cur_sprite.visible = true;