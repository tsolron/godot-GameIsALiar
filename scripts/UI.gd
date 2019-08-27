extends CanvasLayer


var is_message_open = false;


func start_game():
	$Win.visible = false;
	$Lose.visible = false;
	$Dialog.visible = true;
	is_message_open = true;


func show_lose():
	$Lose.visible = true;
	is_message_open = true;


func show_win():
	$Win.visible = true;
	is_message_open = true;


func update(game):
	$Level.text = "LEVEL: " + str(game.level.level_num);
	$HP.text = "HP: " + str(game.player.hp);
	$Score.text = "SCORE: " + str(game.score);


func _on_OKBtn_pressed():
	$Dialog.visible = false;
	is_message_open = false;
