extends Node2D

# Could create this on a script attached to the Enemy, but this works
# extending Reference means it'll be deallocated from memory once it is no longer referenced
#   though honestly don't 100% understand how it works


onready var mine_sprite = $MineSprite;


# Get a reference to the enemy scene 
#const EnemyScene = preload("res://scenes/EnemyTemplate.tscn");
const INFINITY = 3.402823e+38;

var COOLDOWN_TURNS = 2;

var game;
var manager;
var cur_sprite;
var tile;
var max_hp = 1;
var hp;
var is_dying = false;
var is_dead = false;
var faction = -1;
var did_move = false;
var path_dist_to_player = INFINITY;
var is_a_danger = false;
var action_cooldown = 0;
var type = 0;
var is_blown_up = false;
var move_anim;
var mine_anim;



func _ready():
	pass;

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func init(g, mgr, f, enemy_level, t, x, y):
	game = g;
	manager = mgr;
	faction = f;
	type = t;
	
	cur_sprite = $Sprites;
	cur_sprite.frame = 0;
	self.visible = false;
	move_anim = cur_sprite.get_node("AnimationPlayer");
	
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
			#cur_sprite.frame = 1;
			cur_sprite.visible = false;
			cur_sprite = $MineSprite;
			cur_sprite.visible = true;
			mine_anim = $MineSprite/AnimationPlayer;
			mine_anim.play("mine_flicker");
			self.visible = false;
			self.get_node("HP").visible = false;
			self.get_node("HP_Background").visible = false;
	
	action_cooldown = COOLDOWN_TURNS;
	hp = max_hp;
	tile = Vector2(x, y);
	# If using a sprite sheet, this may be different from 0 (ex. a function of enemy_level)
	self.position = tile * game.level.TILE_SIZE;
	
	manager.add_child(self);


func _process(delta):
	if (type == manager.EnemyType.Trap):
			if (mine_anim.current_animation == ""):
				mine_anim.play("mine_flicker");


func remove():
	# Helps with deallocation of the sprite
	self.queue_free();


func update_health_bar(game):
	if (type == manager.EnemyType.Basic || type == manager.EnemyType.Blocker):
		self.get_node("HP").rect_size.x = game.level.TILE_SIZE * hp / max_hp;


func take_damage(game, dmg):
	# Just in case
	if (is_dead || is_dying):
		return;
	
	hp = max(0, hp - dmg); # doesn't go below 0
	update_health_bar(game);
	
	if (hp == 0):
		is_dying = true;
		move_anim.play("die");
		match(type):
			manager.EnemyType.Basic:
				game.score += 15;
			manager.EnemyType.Blocker:
				game.score += 20;
			manager.EnemyType.Innocent:
				game.score += -100;


func act(game):
	# If you can't see it, it can't see you
	if (!self.visible && type != manager.EnemyType.Trap):
		return;
	
	path_dist_to_player = INFINITY;
	did_move = false;
	action_cooldown -= 1;
	var origin = tile;
	
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
				self.visible = true;
			if (path_dist_to_player == 0):
				attack(game.player, 1, "mine");
		else:
			var dx = path[1].x - tile.x;
			var dy = path[1].y - tile.y;
			
			var dir_name = "";
			if (dx == -1): dir_name = "left";
			if (dx ==  1): dir_name = "right";
			if (dy == -1): dir_name = "up";
			if (dy ==  1): dir_name = "down";
			
			var target = game.level.entity_try_move(self, dx, dy, dir_name);
			#if (is_instance_valid(target) && path.size() == 3):
			#	is_at_player = true;
			if (is_instance_valid(target)):
				# Only deals 1 damage each attack for now
				if (type == manager.EnemyType.Basic || type == manager.EnemyType.Blocker):
					# if next to the player, deal 1 damage to them
					if (action_cooldown <= 0):
						action_cooldown = COOLDOWN_TURNS;
						attack(target, 1, dir_name);
			if (did_move):
				manager.hide_mine_if_over(tile);
				manager.unhide_mine_if_not_over(origin);
				path_dist_to_player -= 1;


# warning-ignore:unused_argument
func move_to(destination, dir):
	if (action_cooldown <= 0):
		tile = destination;
		did_move = true;
		action_cooldown = COOLDOWN_TURNS;


func attack(target, dmg, dir_name):
	if (is_blown_up):
		return;
	if (target.faction != faction):
		if (dir_name != "teleport" && dir_name != "mine"):
			move_anim.play("attack_" + dir_name);
		target.take_damage(game, dmg);
		if (dir_name == "mine"):
			is_blown_up = true;
			cur_sprite.visible = false;
			cur_sprite = $Sprites;
			cur_sprite.visible = true;
			cur_sprite.frame = 2;


func get_distance_to_player():
	return path_dist_to_player;


# warning-ignore:unused_argument
func _on_AnimationPlayer_animation_started(anim_name):
	manager.game.pause_input = true;


# warning-ignore:unused_argument
func _on_AnimationPlayer_animation_finished(anim_name):
	if (is_dying):
		is_dying = false;
		is_dead = true;
	manager.game.pause_input = false;