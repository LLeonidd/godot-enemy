extends KinematicBody2D

const SPEED = 120#180
const GRAVITY = 25
const JUMPFORCE = -500
const SPEED_SLIDE = 70

export var MAX_NUMBER_HIT = 3 #The maximum permissible number of blows, after which death occurs 
export var min_attack_distance = 20
export var max_attack_distance = 30
export var limit_position = 100


var max_attack_speed = 1.6
var velocity = Vector2(0,0) 
var dead_trigger = false
var dead_status = false # Required to complete the animation 
var hit_trigger = false
var hit_status = false # Required to complete the animation  and do not count the blows while it is in a hit state 
var hit_counter = 0

var initial_pos

const ENEMY_AREA = 'EnemyArea'


func _ready():
	initial_pos = self.get_global_position()


func _physics_process(delta):
	velocity = move_and_slide(velocity, Vector2.UP)
	velocity.y +=  GRAVITY
	velocity.x = lerp(velocity.x, 0, 0.3) 
	$curent_health.text = 'health: '+String(MAX_NUMBER_HIT - hit_counter)

func hit():
	hit_counter +=1
	if hit_counter<MAX_NUMBER_HIT:
		# go to the hit state in FSM
		hit_trigger = true
		hit_status = true 
	else:
		dead()
		

func dead(object_collision=null):
	"""
	object_collision - the weapon that killed 
	"""
	dead_trigger = true
	dead_status = true
	get_node(ENEMY_AREA).set_collision_layer_bit(1, false)
	set_collision_layer_bit(1, false)
	# If death came from a distant weapon, we destroy the weapon 
	if object_collision:
		object_collision.queue_free()



func _on_Area2D_body_entered(weapon):
	if weapon.is_in_group("Weapons"):
		dead(weapon)


func _on_EnemyArea_area_entered(weapon):
	if weapon.is_in_group("CloseWeapons") and not hit_status:
		hit()


func _on_Sprite_animation_finished():
	if dead_status:
		dead_status=false
		queue_free()
	if hit_status:
		hit_status=false

		



