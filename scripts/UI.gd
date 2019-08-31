extends CanvasLayer


onready var game = self.get_parent();

var is_message_open = false;


func start_game():
	$Win.visible = false;
	$Lose.visible = false;
	#$Dialog.visible = true;
	$MainMenu.visible = false;
	is_message_open = false;


func show_lose():
	$Lose.visible = true;
	is_message_open = true;


func show_win():
	$Win.visible = true;
	is_message_open = true;


func show_dialog():
	$Dialog.visible = true;
	is_message_open = true;


func show_continue():
	$Continue.visible = true;
	is_message_open = true;


func show_exit():
	$Paused.visible = true;
	is_message_open = true;


func show_main_menu():
	$MainMenu.visible = true;
	is_message_open = true;


func update(game):
	$HUD/Level.text = "FLOOR: " + str(game.level.level_num);
	$HUD/HP.text = "HP: " + str(game.player.hp);
	$HUD/Score.text = "SCORE: " + str(game.score);


func _on_OKBtn_pressed():
	$Dialog.visible = false;
	is_message_open = false;


func _on_ContinueBtn_pressed():
	$Continue.visible = false;
	is_message_open = false;


func _on_NoBtn_pressed():
	$Paused.visible = false;
	is_message_open = false;


func _on_PlayBtn_pressed():
	game.start_game();


func _on_MuteBtn_pressed():
	if (!game.audio.is_muted):
		game.audio.mute();
		$MainMenu/MuteBtn.text = "Unmute";
		$Paused/MuteBtn.text = "Unmute";
	elif (game.audio.is_muted):
		game.audio.unmute();
		$MainMenu/MuteBtn.text = "Mute";
		$Paused/MuteBtn.text = "Mute";


func _on_ExitBtn_pressed():
	game.shutdown();
