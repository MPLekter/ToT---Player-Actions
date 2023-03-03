extends KinematicBody2D

const STATES = {idle = "idle", moving = "moving", jumping = "jumping", sliding = "sliding", godmode = "debug_GODMODE"}
const UP_DIRECTION := Vector2.UP

export var state = "idle"
export var gravity := 230
export var jump_speed := 40
export var double_jump_speed := 25
export var maximum_jumps := 2
export var move_speed := 50

#export var acceleration := 15.0
#export var float_horizon_acceleration = 50


var velocity := Vector2.ZERO
var jumps_made := 0

func _physics_process(delta):
	#possible states
	var is_falling := velocity.y > 0.0 and not is_on_floor()
	var is_double_jumping := Input.is_action_just_released("player_jump") and is_falling
	var is_idling := is_on_floor() and is_zero_approx(velocity.x)
	var is_running := is_on_floor() and not is_zero_approx(velocity.x) 
	var is_sliding := is_on_floor() and Input.is_action_pressed("player_crouch") and is_running
	var is_jumping := Input.is_action_just_released("player_jump") and is_on_floor() and not is_sliding
	
	#make gravity work all time when needed
	if not is_on_floor():
		_gravity(delta)
	#working side movement 
	_sideMovement(delta)
	#working jumping
	_jump()
	_resetJumps(is_idling, is_running)
	#working sliding 
	_slide(is_sliding)

func _resetSlide():
		get_child(0).shape.radius = 30
	
func _slide(is_sliding): #TODO: fix it. Still jumping like the space was released (but it wasn't)
	if is_sliding:
		get_child(0).shape.radius = 10.0
		yield(get_tree().create_timer(2.0), "timeout") #maybe yield when stopped sliding or sth
		_resetSlide()
		
func _resetJumps(is_idling, is_running):
	if is_idling or is_running:
		jumps_made = 0
		
func _jump() -> void:
	if Input.is_action_just_pressed("player_jump"):
		jumps_made += 1
		if jumps_made == 1:
			velocity.y -= double_jump_speed
		elif jumps_made == 0:
			velocity.y -= jump_speed
		

func _sideMovement(delta) -> void:
	var horizontal_direction = (
	Input.get_action_strength("player_right") - Input.get_action_strength("player_left")
	)
	
	velocity.x = horizontal_direction * move_speed
	velocity = move_and_slide(velocity, UP_DIRECTION)

func _gravity(delta) -> void:
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, UP_DIRECTION)



#func _statesOfMovement(state: String, delta) -> void:
#	var dir := Input.get_action_strength("player_right") - Input.get_action_strength("player_left")
#	match state:
#		STATES.idle, STATES.moving:
#			velocity.x = lerp(velocity.x , dir * move_speed , delta * acceleration)
#			velocity = move_and_slide_with_snap(velocity,Vector2.DOWN if velocity.y >= 0 else Vector2.ZERO, Vector2.UP)
#			state = STATES.idle
#
#		STATES.jumping:
#			velocity.y += jump_speed
#			velocity.x = lerp(velocity.x , dir * move_speed, delta * float_horizon_acceleration)
#			velocity = move_and_slide(velocity,Vector2.UP)
#			state = STATES.idle
