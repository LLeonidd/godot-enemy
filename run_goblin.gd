extends Node

var fsm: StateMachineForGoblin
var _speed_for_attack = 1 # Factor for changing the speed when attacking 


func enter():
	fsm.enemy.play('run')
	


func exit(next_state):
	fsm.change_to(next_state)


func process(_delta):
	pass



func physics_process(_delta):
	if fsm.need_direction(): 
		fsm.direction = -1 * fsm.direction
		fsm.enemy.set_flip_h(not fsm.enemy.is_flipped_h())
		#Stop when changing direction 
		if not(fsm.player_is_detect(fsm.left_ray) or fsm.player_is_detect(fsm.right_ray)):
			exit('idle')
	fsm.enemy_root.velocity.x = fsm.direction * fsm.enemy_root.SPEED*_speed_for_attack
	
	if fsm.player_is_detect(fsm.left_ray) or fsm.player_is_detect(fsm.right_ray):
		_speed_for_attack = min(fsm.enemy_root.max_attack_speed, _speed_for_attack +_delta*1.2)
	else:
		_speed_for_attack = 1
	
	# if nearlest Player
	if fsm.player_is_close():
		_speed_for_attack = 1
		exit('close_attack') 
	


	
func input(_event):
	pass
	

func unhandled_input(_event):
	pass

func unhandled_key_input(_event):
	pass

func notification(_what, _flag = false):
	pass
