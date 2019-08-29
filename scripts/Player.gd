extends Sprite

const PLAYER_START_HP = 9;

var game;
var tile;
var hp;
var is_dead;
var faction;
var is_ready = false;
var is_danger = false;
var cur_sprite;

onready var idle_blue = $idle_blue;
onready var idle_red = $idle_red;
onready var animate = $AnimationPlayer;


func _ready():
	game = get_parent();
	faction = game.Faction.Player;


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


func take_damage(game, dmg):
	# Don't go below 0 hp
	hp = max(0, hp - dmg);
	if (hp == 0):
		is_dead = true;


func try_move(dx, dy, dir_name):
	turn_sprite(dir_name);
	var target = game.level.entity_try_move(self, dx, dy);
	
	# If you try to move onto an Enemy, deal damage to it instead
	# If killed, an enemy will disappear but you'll have to wait a turn to move there
	if (is_instance_valid(target)):
		# Only deals 1 damage each attack for now
		attack(target, 1);


func attack(target, dmg):
	if (target.faction != faction):
		target.take_damage(game, dmg);