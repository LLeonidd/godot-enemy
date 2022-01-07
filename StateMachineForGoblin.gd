extends Node

class_name StateMachineForGoblin

const DEBUG = false
const PATH_TO_PARENT = '../'
const PLAYER_OBJECT = 'Sprite' 
const SATATE_LABEL = 'current_state'
const LEFT_RAY = 'LeftRay'
const RIGHT_RAY = 'RightRay'
const LEFT_DOWN_RAY = 'LeftDownRay'
const RIGHT_DOWN_RAY = 'RightDownRay'
const MIN_VELOCITY_FOR_SLIDE = -500 # The speed at which sliding is available. For example, do not slide on low walls
const MAX_VELOCITY_DEADLY_FALLING = 1000 
const AUDIO = 'MusicEffects'

var state: Object

var history = []

var offset_list = [15,0] # values for offset left (0-index) or right (1-index), for correct direction

var pending_states = ['idle', 'run'] #What states can an object be in while waiting for an attack? 
var pending_status = true #Pending attack state 
var direction = 1


onready var enemy_root = get_node(PATH_TO_PARENT)
onready var enemy = enemy_root.find_node(PLAYER_OBJECT)
onready var state_label = enemy_root.find_node(SATATE_LABEL)
onready var left_ray = enemy_root.find_node(LEFT_RAY)
onready var right_ray = enemy_root.find_node(RIGHT_RAY)
onready var left_down_ray = enemy_root.find_node(LEFT_DOWN_RAY)
onready var right_down_ray = enemy_root.find_node(RIGHT_DOWN_RAY)
onready var audio = enemy_root.find_node(AUDIO)
# user actions
#refs to functions
#onready var move_and_slide = funcref(player_root, "move_and_slide")


func _ready():
	# Set the initial state to the first child node
	state = get_child(0)
	# Allow for all nodes to be ready before calling _enter_state
	call_deferred("_enter_state")


func change_to(new_state):
	history.append(state.name)
	state = get_node(new_state)
	_enter_state()


func back():
	if history.size() > 0:
		state = get_node(history.pop_back())
		_enter_state()

func get_history_back_state():
		return history.pop_back()

func _enter_state():
	if DEBUG:
		state_label.text = state.name
		print("Entering state: ", state.name)
	# Give the new state a reference to it's state machine i.e. this one
	state.fsm = self
	state.enter()


# Route Game Loop function calls to
# current state handler method if it exists
func _process(delta):
	if state.has_method("process"):
		state.process(delta)


func _physics_process(delta):
	if state.has_method("physics_process"):
		state.physics_process(delta)
	if check_dead():
		change_to('dead')
	if check_hit():
		change_to('hit')
	


func _input(event):
	if state.has_method("input"):
		state.input(event)

func _unhandled_input(event):
	if state.has_method("unhandled_input"):
		state.unhandled_input(event)


func _unhandled_key_input(event):
	if state.has_method("unhandled_key_input"):
		state.unhandled_key_input(event)


func _notification(what):
	if state and state.has_method("notification"):
			state.notification(what)

#Custom functions
func direction_bool_to_int(val):
	"""
	Conver bool to int, 
	true to 1
	false to -1
	This function can be useful for setting direction 
	"""
	return -1 + 2*int(val)

func break_is_detect():
	"""
	Break detection 
	"""
	


func player_is_detect(raycast, group='Player'):
	if raycast.is_colliding():
		if raycast.get_collider().is_in_group(group):
			return raycast.get_collider()
		else: return false
	else: return false


func is_player_found():
	"""
	found in sight 
	"""
	return checking_possible_attack_on_side(self.left_ray) or checking_possible_attack_on_side(self.right_ray)

#determine if the player is close 
func checking_possible_attack_on_side(raycast):
	var _player # The player you want to attack. Main player
	"""
	Param:raycast - node, RayCast detector
	"""
	var flipped = false #Direction 
	#Direction of movement by the angle of rotation of the rays 
	# if > 0 then left ray, else right ray
	if raycast.get_rotation_degrees() > 0: flipped = true 
	
	if player_is_detect(raycast):
		_player = player_is_detect(raycast).get_parent()
		if abs(_player.get_global_position()[0]-self.enemy_root.get_global_position()[0])>self.enemy_root.min_attack_distance:
			self.enemy.set_flip_h(flipped)
			self.direction = direction_bool_to_int(not self.enemy.is_flipped_h())
		#The player is in a suitable distance to attack. 
		if (
			self.enemy_root.min_attack_distance < abs(_player.get_global_position()[0]-self.enemy_root.get_global_position()[0])
			and 
			abs(raycast.get_collision_point()[0]-self.enemy_root.get_position()[0])<=self.enemy_root.max_attack_distance
			):
			return true
		else:
			return false
	
	
func player_is_close():
	"""
	Determines if an object is close to launch an attack 
	"""
	if self.is_player_found():
		# Should not return to the starting position, but should remain where the attack occurred 
		self.enemy_root.initial_pos = self.enemy_root.get_global_position()
		return true
	else:
		return false 
	

func exceeding_limit():
	#if there is an excess of the position limit 
	if abs(self.enemy_root.initial_pos[0] - self.enemy_root.get_global_position()[0])>self.enemy_root.limit_position:
		# moves right 
		if self.enemy_root.initial_pos[0] - self.enemy_root.get_global_position()[0]<0 and not self.enemy.is_flipped_h():
			return true
		# moves left 
		elif self.enemy_root.initial_pos[0] - self.enemy_root.get_global_position()[0]>0 and self.enemy.is_flipped_h():
			return true
		else :
			return false
	else:
		return false
		

func break_detector():
	"""
	Determines the presence of a cliff under the left and right rays 
	"""
	var left_direction = self.enemy.is_flipped_h()
	var right_direction = not self.enemy.is_flipped_h()
	var left_break = false
	var right_break = false
	if not left_down_ray.is_colliding() and left_direction: 
		left_break = true
	if not right_down_ray.is_colliding() and right_direction: 
		right_break=true
	return left_break or right_break


func need_direction():
	"""
	Checks if an object needs to change direction 
	"""
	var _exceeding_limit
	var _is_on_wall
	var _player_is_detect
	var _breack_detector
	break_detector()
	_exceeding_limit = exceeding_limit()
	_is_on_wall = self.enemy_root.is_on_wall()
	_player_is_detect = self.player_is_detect(self.left_ray) or self.player_is_detect(self.right_ray)
	_breack_detector = break_detector()
	if (_exceeding_limit and not _player_is_detect) or _is_on_wall  or _breack_detector:
		return true
	else:
		return false

func check_dead():
	if enemy_root.dead_trigger:
		enemy_root.dead_trigger = false
		return true
	else: 
		return false
		
func check_hit():
	if enemy_root.hit_trigger:
		enemy_root.hit_trigger = false
		return true
	else: 
		return false
		
func dead_or_hit_check():
	return check_dead() or check_hit()
		
		
