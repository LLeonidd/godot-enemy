extends Node

var fsm: StateMachineForGoblin


func enter():
	fsm.enemy.play('idle')
	if not fsm.is_player_found():
		yield(get_tree().create_timer(1), "timeout")
	if not fsm.enemy_root.dead_status:
		exit('run')
		


func exit(next_state):
	fsm.change_to(next_state)


func process(_delta):
	if fsm.player_is_close():
		exit('close_attack')


func physics_process(_delta):
	pass

	
func input(_event):
	pass
	

func unhandled_input(_event):
	pass

func unhandled_key_input(_event):
	pass

func notification(_what, _flag = false):
	pass
