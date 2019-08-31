extends Sprite

const PLAYER_START_HP = 10;

var game;
var tile;
var hp;
var is_dead;
var faction;
var is_ready = false;
var is_danger = false;
var cur_sprite;
var player_has_moved = false;
var vision_range = 4;
var ready_to_calc_fog = false;

# warning-ignore:unused_class_variable
onready var visual = $Visual;
onready var idle_blue = $Visual/idle_blue;
onready var idle_red = $Visual/idle_red;
onready var animate = $Visual/AnimationPlayer;
onready var move_anim = $MoveAnimation;
onready var camera_animation = $Visual/Camera/Animation;
onready var hp_bar = $Visual/HPMax/HP;


func _ready():
	game = get_parent();
	faction = game.Faction.Player;


func start_game():
	hp = PLAYER_START_HP;
	is_dead = false;
	is_ready = false;
	cur_sprite = idle_blue;
	player_has_moved = false;
	self.visible = true;


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


# warning-ignore:unused_argument
func take_damage(game, dmg):
	# Don't go below 0 hp
	hp = max(0, hp - dmg);
	update_health_bar(game);
	camera_animation.play("screen_shake");
	if (hp == 0):
		is_dead = true;


func update_health_bar(game):
	hp_bar.rect_size.x = game.level.TILE_SIZE * hp / PLAYER_START_HP;


func move_to(destination, dir_name):
	
	if (dir_name != "teleport"):
		move_anim.play("move_" + dir_name);
		#move_anim.play("move_right_test");
		#yield(move_anim, "animation_finished");
	tile = destination;


func try_move(dx, dy, dir_name):
	player_has_moved = true;
	game.player.is_danger = false;
	
	turn_sprite(dir_name);
	var target = game.level.entity_try_move(self, dx, dy, dir_name);
	
	# If you try to move onto an Enemy, deal damage to it instead
	# If killed, an enemy will disappear but you'll have to wait a turn to move there
	if (is_instance_valid(target)):
		# Only deals 1 damage each attack for now
		attack(target, 1, dir_name);


func attack(target, dmg, dir_name):
	if (target.faction != faction):
		if (dir_name != "teleport"):
			move_anim.play("attack_" + dir_name);
		target.take_damage(game, dmg);

# warning-ignore:unused_argument
func _on_MoveAnimation_animation_started(anim_name):
	#visual.position = Vector2(0,0);
	game.pause_input = true;
	ready_to_calc_fog = false;


# warning-ignore:unused_argument
func _on_MoveAnimation_animation_finished(anim_name):
	visual.position = Vector2(0,0);
	game.pause_input = false;
	ready_to_calc_fog = true;
	#game.call_deferred("update_visuals");
	#game.update_visuals();
