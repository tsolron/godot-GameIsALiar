extends Node2D

const Enemy = preload("Enemy.gd");

const TILE_SIZE = 32;
const LEVEL_SIZES = [
	Vector2(21, 11),
	Vector2(20, 12),
	Vector2(29, 25),
	Vector2(28, 29),
	Vector2(28, 29),
];

const LEVEL_ROOM_COUNTS = [1, 2, 4, 4, 4];
const LEVEL_ENEMY_COUNTS = [2, 5, 8, 6, 8];
const MIN_ROOM_DIMENSION = 8;
const MAX_ROOM_DIMENSION = 20;

# Wall: Perimeter of a room
# Door: Barrier between a room and hallway. Takes one turn to open
# Floor: Inside a room
# Ladder: Connects different levels
# Stone: Default everywhere
enum Tile {Wall, Door, Floor, Ladder, Stone, Ladder_up, Floor_2, Floor_3};

onready var tile_map = $TileMap;
onready var visibility_map = $VisibilityMap;
onready var player = $"../Player";

var game;
var level_num = 0;
var map = [];
var rooms = [];
var size;
var num_rooms;
var entity_pathfinding_graph = AStar.new();
var ready_to_calc_fog = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_parent();

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func start_game(n):
	level_num = n;
	#build_level();
	load_level(level_num);


func load_level(n):
	ready_to_calc_fog = false;
	level_num = n;
	var loaded_level = get_node("Level_" + str(level_num));
	size = LEVEL_SIZES[level_num];
	#size = Vector2(20, 12);
	#num_rooms = LEVEL_ROOM_COUNTS[level_num];
	
	rooms.clear();
	map.clear();
	tile_map.clear();
	visibility_map.clear();
	entity_pathfinding_graph = AStar.new();
	
	for x in range(size.x):
		map.append([]);
		for y in range(size.y):
			map[x].append(Tile.Stone);
			tile_map.set_cell(x, y, Tile.Stone);
			visibility_map.set_cell(x, y, 0);
	
	for x in range(size.x):
		map.append([]);
		for y in range(size.y):
			var cur_tile = loaded_level.get_cell(x, y);
			set_tile(x, y, cur_tile);
			
	#var free_regions = [Rect2(Vector2(2, 2), size - Vector2(4, 4))];
	
# warning-ignore:unused_variable
	#for i in range(num_rooms):
	#	add_room(free_regions);
	#	if (free_regions.empty()):
	#		break;
	
	#connect_rooms();
	
	# Place the player in the level
	#var start_room = rooms.front();
	#var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2);
	#var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2);
	#player.move_to(player_x, player_y);
	player.move_to(Vector2(9, 5), 'teleport');
	player.is_ready = true;
	
	# Place end-of-level Ladder, last room used since it's all random
	#var end_room = rooms.back();
	#var ladder_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2);
	#var ladder_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2);
	#set_tile(ladder_x, ladder_y, Tile.Ladder);
	
	var enemy_tiles = loaded_level.get_children()[0];
	game.enemy_manager.load_from_tileset(enemy_tiles);
	
	ready_to_calc_fog = true;
	#game.call_deferred("update_visuals");
	#game.update_visuals();


func build_level():
	#size = LEVEL_SIZES[level_num];
	size.x += 2;
	size.y += 2;
	if (level_num < LEVEL_ROOM_COUNTS.size()):
		num_rooms = LEVEL_ROOM_COUNTS[level_num];
	
	rooms.clear();
	map.clear();
	tile_map.clear();
	visibility_map.clear();
	entity_pathfinding_graph = AStar.new();
	
	for x in range(size.x):
		map.append([]);
		for y in range(size.y):
			map[x].append(Tile.Stone);
			tile_map.set_cell(x, y, Tile.Stone);
			visibility_map.set_cell(x, y, 0);
	
	var free_regions = [Rect2(Vector2(2, 2), size - Vector2(4, 4))];
	
# warning-ignore:unused_variable
	for i in range(num_rooms):
		add_room(free_regions);
		if (free_regions.empty()):
			break;
	
	connect_rooms();
	
	# Place the player in the level
	var start_room = rooms.front();
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2);
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2);
	player.move_to(Vector2(player_x, player_y), 'teleport');
	player.is_ready = true;
	
	# Place end-of-level Ladder, last room used since it's all random
	var end_room = rooms.back();
	var ladder_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2);
	var ladder_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2);
	set_tile(ladder_x, ladder_y, Tile.Ladder);
	
	if (level_num < LEVEL_ENEMY_COUNTS.size()):
		game.enemy_manager.add_to_level(LEVEL_ENEMY_COUNTS[level_num]);
	else:
		game.enemy_manager.add_to_level(LEVEL_ENEMY_COUNTS[LEVEL_ENEMY_COUNTS.size() - 1] + level_num);
	
	#game.call_deferred("update_visuals");
	#game.update_visuals();


func get_random_location_for_entity():
	# Pick a random room, excluding the first (where the player is placed)
	#var room = rooms[1 + randi() % (rooms.size() - 1)];
	var room = rooms[randi() % rooms.size()];
	# Place in a random location within the room
	var x = room.position.x + 1 + randi() % int(room.size.x - 2);
	var y = room.position.y + 1 + randi() % int(room.size.y - 2);
	return Vector2(x, y);


func update_fog(player_center, space_state):
	#print("Size X: "+str(size.x) + ", Size Y: "+str(size.y));
	for x in range(size.x):
		for y in range(size.y):
			#print("(x: "+str(x) + ", y: "+str(y)+")");
			#if (get_distance_to_player(x, y) > game.player.vision_range):
			#	continue;
			
			if (visibility_map.get_cell(x, y) == 0):
				var x_dir = 0;
				#if (x < game.player.tile.x): x_dir = 1;
				#if (x > game.player.tile.x): x_dir = -1;
				x_dir = (1 if (x < game.player.tile.x) else (-1));
				var y_dir = 0;
				#if (y < game.player.tile.y): y_dir = 1;
				#if (y > game.player.tile.y): y_dir = -1;
				y_dir = (1 if (y < game.player.tile.y) else (-1));
				
# warning-ignore:integer_division
				var test_point = game.tile_to_pixel_center(x, y) + Vector2(x_dir, y_dir)*(TILE_SIZE / 2);
				var test_point_2 = game.tile_to_pixel_center(x, y);
				
				var occlusion = space_state.intersect_ray(player_center, test_point, [self], tile_map.collision_mask);
				var occlusion_2 = space_state.intersect_ray(player_center, test_point_2, [self], tile_map.collision_mask);
				# If no occlusion, or if the object causing occlusion is itself
				if (!occlusion || (occlusion.position - test_point).length() < 1):
					visibility_map.set_cell(x, y, -1);
				if (!occlusion_2 || (occlusion_2.position - test_point_2).length() < 1):
					visibility_map.set_cell(x, y, -1);


func get_distance_to_player(x, y):
	var a = abs(game.player.tile.x - x);
	var b = abs(game.player.tile.y - y);
	var dist = sqrt(pow(a,2)+pow(b,2));
	
	return dist;


func connect_rooms():
	# A* graph of Stone tiles & their connecting Stone tiles
	#   These may be converted into a path to connect rooms
	var stone_graph = AStar.new();
	var point_id = 0;
	
	# Loop through each tile in the level, from left to right then top to bottom
	for x in range(size.x):
		for y in range(size.y):
			# If it's Stone, we'll add it to our graph as a tile that may be used to connect two rooms
			if (is_tile_equal_to(map[x][y], [Tile.Stone])):
				stone_graph.add_point(point_id, Vector3(x, y, 0));
				
				# And add connections to the tile above and to the left of this one
				if (x > 0 && is_tile_equal_to(map[x - 1][y], [Tile.Stone])):
					var left_point = stone_graph.get_closest_point(Vector3(x - 1, y, 0));
					stone_graph.connect_points(point_id, left_point);
					
				if (y > 0 && is_tile_equal_to(map[x][y - 1], [Tile.Stone])):
					var above_point = stone_graph.get_closest_point(Vector3(x, y - 1, 0));
					stone_graph.connect_points(point_id, above_point);
					
				point_id += 1;
	
	# A* graph of the rooms - from any room you should be able to reach all other rooms
	var room_graph = AStar.new();
	point_id = 0;
	for room in rooms:
		var room_center = room.position + room.size / 2;
		room_graph.add_point(point_id, Vector3(room_center.x, room_center.y, 0));
		point_id += 1;
	
	# Until all rooms are connected, keep adding connections
	while (!is_everything_connected(room_graph)):
		add_random_connection(stone_graph, room_graph);


func is_everything_connected(graph):
	var points = graph.get_points();
	# Select any room
	var start = points.pop_back();
	for point in points:
		# If no path exists between the start room and any other room, return false
		var path = graph.get_point_path(start, point);
		if (!path):
			return false;
	
	# Otherwise each room has a path to every other
	return true;


func add_random_connection(stone_graph, room_graph):
	# Find two rooms to connect
	var start_room_id = get_least_connected_point(room_graph);
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id);
	
	# Pick door locations
	var start_position = pick_random_door_location(rooms[start_room_id]);
	var end_position = pick_random_door_location(rooms[end_room_id]);
	
	# Create a path between those doors
	var closest_start_point = stone_graph.get_closest_point(start_position);
	var closest_end_point = stone_graph.get_closest_point(end_position);
	
	var path = stone_graph.get_point_path(closest_start_point, closest_end_point);
	# If it fails, let us know
	assert(path);
	
	# Modify the map with the new path
	set_tile(start_position.x, start_position.y, Tile.Door);
	set_tile(end_position.x, end_position.y, Tile.Door);
	
	for position in path:
		set_tile(position.x, position.y, Tile.Floor);
	
	# Update the room graph
	room_graph.connect_points(start_room_id, end_room_id);


func get_least_connected_point(graph):
	var point_ids = graph.get_points();
	
	# We'll track the least # of connections and a list of points/rooms which have that many connections
	var least;
	var tied_for_least = [];
	
	# Search through all points/rooms
	for point in point_ids:
		# And update our vars as needed
		var count = graph.get_point_connections(point).size();
		# On our first point we'll initialize least and our list (!least condition)
		if (!least || count < least):
			least = count;
			tied_for_least = [point];
		elif (count == least):
			tied_for_least.append(point);
	
	# We then pick a random point/room which has the least # of connections
	return tied_for_least[randi() % tied_for_least.size()];


# Works the same way as get_least_connected_point() but with tracking distance to the target_point
func get_nearest_unconnected_point(graph, target_point):
	var target_position = graph.get_point_position(target_point);
	var point_ids = graph.get_points();
	
	var nearest;
	var tied_for_nearest = [];
	
	for point in point_ids:
		# Ignore when we get to target_point in the list of points
		if (point == target_point):
			continue;
		
		# If a path already exists, we'll skip this point/room
		var path = graph.get_point_path(point, target_point);
		if (path):
			continue;
		
		# Update vars as needed
		var dist = (graph.get_point_position(point) - target_position).length();
		if (!nearest || dist < nearest):
			nearest = dist;
			tied_for_nearest = [point];
		elif (dist == nearest):
			tied_for_nearest.append(point);
	
	return tied_for_nearest[randi() % tied_for_nearest.size()];


func pick_random_door_location(room):
	var options = [];
	
	# Add all upper and lower walls as options for the door (ignores corners)
	for x in range(room.position.x + 1, room.end.x - 2):
		options.append(Vector3(x, room.position.y, 0));
		options.append(Vector3(x, room.end.y - 1, 0));
		
	# Add all side walls as options for the door (ignores corners)
	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector3(room.position.x, y, 0));
		options.append(Vector3(room.end.x - 1, y, 0));
		
	# Select the door from our list of options at random
	return options[randi() % options.size()];


func add_room(free_regions):
	# Pick a remaining free region at random
	var region = free_regions[randi() % free_regions.size()];
	
	# Define the size of this room, within constraints
	var size_x = MIN_ROOM_DIMENSION;
	if (region.size.x > MIN_ROOM_DIMENSION):
		size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION);
		
	var size_y = MIN_ROOM_DIMENSION;
	if (region.size.y > MIN_ROOM_DIMENSION):
		size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION);
	
	size_x = min(size_x, MAX_ROOM_DIMENSION);
	size_y = min(size_y, MAX_ROOM_DIMENSION);
	
	# Where to place the room within the region
	var start_x = region.position.x;
	if (region.size.x > size_x):
		start_x += randi() % int(region.size.x - size_x);
	
	var start_y = region.position.y;
	if (region.size.y > size_y):
		start_y += randi() % int(region.size.y - size_y);
	
	# Create the room and add it to our list of rooms
	var room = Rect2(start_x, start_y, size_x, size_y);
	rooms.append(room);
	
	# Place tiles for the room's walls
	for x in range(start_x, start_x + size_x):
		# top row
		set_tile(x, start_y, Tile.Wall);
		# bottom row
		set_tile(x, start_y + size_y - 1, Tile.Wall);
		
	for y in range(start_y + 1, start_y + size_y - 1):
		# left side
		set_tile(start_x, y, Tile.Wall);
		# right side
		set_tile(start_x + size_x - 1, y, Tile.Wall);
		
		# Place the floor inside the room
		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x, y, Tile.Floor);
	
	# Remove the newly created room from the free region list
	cut_regions(free_regions, room);


func cut_regions(free_regions, region_to_remove):
	# Use queues since we'll be adding/removing from an array and we need to iterate through
	# to determine which to add/remove
	var removal_queue = [];
	var addition_queue = [];
	
	for region in free_regions:
		# If region intersects with the room we just made, we'll remove this region
		#   and add new regions where space is sufficient
		if (region.intersects(region_to_remove)):
			removal_queue.append(region);
			
			# How much of a gap we have on each side
			var leftover_left = region_to_remove.position.x - region.position.x - 1;
			var leftover_right = region.end.x - region_to_remove.end.x - 1;
			var leftover_above = region_to_remove.position.y - region.position.y - 1;
			var leftover_below = region.end.y - region_to_remove.end.y - 1;
			
			# Add new regions, one for each side. Note that they overlap
			#   (to allow future rooms to be created in that overlap)
			if (leftover_left >= MIN_ROOM_DIMENSION):
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)));
			if (leftover_right >= MIN_ROOM_DIMENSION):
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)));
			if (leftover_above >= MIN_ROOM_DIMENSION):
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)));
			if (leftover_below >= MIN_ROOM_DIMENSION):
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)));
	
	# Actually perform the additions and removals
	for region in removal_queue:
		free_regions.erase(region);
	for region in addition_queue:
		free_regions.append(region);


func set_tile(x, y, type):
	map[x][y] = type;
	if (is_tile_equal_to(type, [Tile.Floor])):
		tile_map.set_cell(x, y, select_tile_from_group(Tile.Floor));
	else:
		tile_map.set_cell(x, y, type);
	
	#if (type == Tile.Floor):
		#tile_map.get_cell(x, y).Region.x = ((randi() % 2) * TILE_SIZE);
	
	if (is_passable_tile(x, y)):
		add_tile_to_pathfinding_graph(Vector2(x, y));


func is_passable_tile(x, y):
	var is_passable = false;
	if (is_tile_equal_to(map[x][y], [Tile.Floor, Tile.Ladder, Tile.Ladder_up])):
		is_passable = true;
	return is_passable;


# Whenever a Floor tile is set, add the new connections between it and existing Floors
func add_tile_to_pathfinding_graph(tile):
	# Make a new point for "tile"
	var new_point = entity_pathfinding_graph.get_available_point_id();
	entity_pathfinding_graph.add_point(new_point, Vector3(tile.x, tile.y, 0));
	
	# List of points connecting  to "tile"
	var points_to_connect = [];
	
	# Check Left
	if (tile.x > 0 && is_passable_tile(tile.x - 1, tile.y)):
		points_to_connect.append(entity_pathfinding_graph.get_closest_point(Vector3(tile.x - 1, tile.y, 0)));
	# Check Up
	if (tile.y > 0 && is_passable_tile(tile.x, tile.y - 1)):
		points_to_connect.append(entity_pathfinding_graph.get_closest_point(Vector3(tile.x, tile.y - 1, 0)));
	# Check Right
	if (tile.x < game.level.size.x - 1 && is_passable_tile(tile.x + 1, tile.y)):
		points_to_connect.append(entity_pathfinding_graph.get_closest_point(Vector3(tile.x + 1, tile.y, 0)));
	# Check Down
	if (tile.y < game.level.size.y - 1 && is_passable_tile(tile.x, tile.y + 1)):
		points_to_connect.append(entity_pathfinding_graph.get_closest_point(Vector3(tile.x, tile.y + 1, 0)));
	
	# Create the connections between "tile" and existing Floors
	for point in points_to_connect:
		entity_pathfinding_graph.connect_points(point, new_point);


func entity_try_move(entity, dx, dy, dir_name):
	var x = entity.tile.x + dx;
	var y = entity.tile.y + dy;
	var move_tile = Vector2(x, y);
	
	var blocker = null;
	
	var tile_type = Tile.Stone;
	# Make sure the desired move location is in-bounds for our map array
	if (x >= 0 && x < size.x && y >= 0 && y < size.y):
		tile_type = map[x][y];
	
	# Match is like a switch/case statement in other languages.
	#match tile_type:
	if (is_tile_equal_to(tile_type, [Tile.Floor, Tile.Ladder, Tile.Ladder_up])):
		var is_blocked = false;
		
		# Enemy is blocking movement
		var blocking_enemy = game.enemy_manager.get_enemy_blocking_movement(x, y);
		if (is_instance_valid(blocking_enemy)):
			is_blocked = true;
			blocker = blocking_enemy;
		
		# Player is blocking movement
		# If entity is the player, this conditional will be false
		if (move_tile == game.player.tile):
			is_blocked = true;
			blocker = game.player;
		
		# If you're trying to move onto Floor and there are no enemies, success!
		if (!is_blocked):
			#if (tile_type == Tile.Ladder && entity.faction == 0):
			if (is_tile_equal_to(tile_type, [Tile.Ladder]) && entity.faction == 0):
				go_to_next_level();
				return null;
			else:
				entity.move_to(Vector2(x, y), dir_name);
	
	if (is_tile_equal_to(tile_type, [Tile.Door])):
		# If you're trying to open a door, you did it!
		# Next turn you can move to where the door was
		set_tile(x, y, Tile.Floor);
	
	return blocker;


func go_to_next_level():
	# Gain 20 points for each level transition
	level_num += 1;
	player.player_has_moved = false;
	game.score += 25;
	ready_to_calc_fog = false;
	# If there are more levels, go to the next one
	if (level_num < LEVEL_SIZES.size()):
		load_level(level_num);
		#build_level();
	else:
		#if (level_num == LEVEL_SIZES.size()):
		#	game.ui.show_continue();
		game.win = true;
		#build_level();


func is_tile_equal_to(tile, type):
	for i in range(type.size()):
		match(type[i]):
			Tile.Wall, Tile.Door, Tile.Ladder, Tile.Stone, Tile.Ladder_up:
				if (tile == type[i]):
					return true;
			Tile.Floor:
				if (tile == Tile.Floor):
					return true;
				if (tile == Tile.Floor_2):
					return true;
				if (tile == Tile.Floor_3):
					return true;
	return false;


func select_tile_from_group(group):
	return group;
	if (is_tile_equal_to(group, [Tile.Floor])):
		var floor_tile = null;
		var random_n = randi() % 3;
		match(random_n):
			0: floor_tile = Tile.Floor;
			1: floor_tile = Tile.Floor_2;
			2: floor_tile = Tile.Floor_3;
		return floor_tile;
	else:
		return group;