extends CanvasLayer


func start_game():
	$Win.visible = false;
	$Lose.visible = false;


func show_lose():
	$Lose.visible = true;


func show_win():
	$Win.visible = true;


func update(game):
	$Level.text = "LEVEL: " + str(game.level.level_num);
	$HP.text = "HP: " + str(game.player.hp);
	$Score.text = "SCORE: " + str(game.score);