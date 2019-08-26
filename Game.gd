extends Node2D

# Constants 
const TILE_SIZE = 32;
const LEVEL_SIZES = [
	Vector2(30, 30),
	Vector2(35, 35),
	Vector2(40, 40),
	Vector2(45, 45), 
	Vector2(50, 50), 
];

const LEVEL_ROOM_COUNTS = [5, 7, 9, 12, 15];
const MIN_ROOM_DIMENSION = 5;
const MAX_ROOM_DIMENSION = 8;

# Wall: Perimeter of a room
# Door: Barrier between a room and hallway. Takes one turn to open
# Floor: Inside a room
# Ladder: Connects different levels
# Stone: Default everywhere
enum Tile {Wall, Door, Floor, Ladder, Stone}



# This level
var level_num = 0;
var map = [];
var rooms = [];
var level_size;

# Get nodes but after they exist
onready var tile_map = $TileMap;
onready var player = $Player;

var player_tile;
var score = 0;



# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_size(Vector2(1280, 720));
	randomize();
	build_level();

# Auto called whenever there's an input event
func _input(event):
	# Ignore events that aren't key presses
	if (!event.is_pressed()):
		return;
	
	# If one of our input actions, do that action.
	# Note that key binds are in project settings, these are just the actions those bind to
	if (event.is_action("Left")):
		try_move(-1, 0);
	if (event.is_action("Right")):
		try_move(1, 0);
	if (event.is_action("Up")):
		try_move(0, -1);
	if (event.is_action("Down")):
		try_move(0, 1);


func try_move(dx, dy):
	var x = player_tile.x + dx;
	var y = player_tile.y + dy;
	
	var tile_type = Tile.Stone;
	# Make sure the desired move location is in-bounds for our map array
	if (x >= 0 && x < level_size.x && y >= 0 && y < level_size.y):
		tile_type = map[x][y];
	
	# Match is like a switch/case statement in other languages.
	match tile_type:
		Tile.Floor:
			# If you're trying to move onto Floor, success!
			player_tile = Vector2(x, y);
		
		Tile.Door:
			# If you're trying to open a door, you did it!
			# Next turn you can move to where the door was
			set_tile(x, y, Tile.Floor);
		
		Tile.Ladder:
			# Gain 20 points for each level transition
			level_num += 1;
			score += 20;
			# If there are more levels, go to the next one
			if (level_num < LEVEL_SIZES.size()):
				build_level();
			else:
				# Gain 1000 points for reaching the end of the game
				score += 1000;
				$CanvasLayer/Win.visible = true;
	
	update_visuals();


func build_level():
	rooms.clear();
	map.clear();
	tile_map.clear();
	
	level_size = LEVEL_SIZES[level_num];
	for x in range(level_size.x):
		map.append([]);
		for y in range(level_size.y):
			map[x].append(Tile.Stone);
			tile_map.set_cell(x, y, Tile.Stone);
	
	var free_regions = [Rect2(Vector2(2, 2), level_size - Vector2(4, 4))];
	var num_rooms = LEVEL_ROOM_COUNTS[level_num];
	for i in range(num_rooms):
		add_room(free_regions);
		if (free_regions.empty()):
			break;
	
	connect_rooms();
	
	# Place the player in the level
	var start_room = rooms.front();
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2);
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2);
	player_tile = Vector2(player_x, player_y);
	update_visuals();
	
	# Place end-of-level Ladder, last room used since it's all random
	var end_room = rooms.back();
	var ladder_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2);
	var ladder_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2);
	set_tile(ladder_x, ladder_y, Tile.Ladder);
	
	# Update UI
	$CanvasLayer/Level.text = "LEVEL: " + str(level_num);

func update_visuals():
	# Currently only updates the player position, but more will be here later
	player.position = player_tile * TILE_SIZE;


func connect_rooms():
	# A* graph of Stone tiles & their connecting Stone tiles
	#   These may be converted into a path to connect rooms
	var stone_graph = AStar.new();
	var point_id = 0;
	
	# Loop through each tile in the level, from left to right then top to bottom
	for x in range(level_size.x):
		for y in range(level_size.y):
			# If it's Stone, we'll add it to our graph as a tile that may be used to connect two rooms
			if map[x][y] == Tile.Stone:
				stone_graph.add_point(point_id, Vector3(x, y, 0));
				
				# And add connections to the tile above and to the left of this one
				if (x > 0 && map[x - 1][y] == Tile.Stone):
					var left_point = stone_graph.get_closest_point(Vector3(x - 1, y, 0));
					stone_graph.connect_points(point_id, left_point);
					
				if (y > 0 && map[x][y - 1] == Tile.Stone):
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
	tile_map.set_cell(x, y, type);
	

func _on_ResetBtn_pressed():
	level_num = 0;
	score = 0;
	build_level();
	$CanvasLayer/Win.visible = false;
