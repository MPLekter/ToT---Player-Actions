extends KinematicBody2D

#constants
const UP := Vector2.UP
const DOWN := Vector2.DOWN
const LEFT := Vector2.LEFT
const RIGHT := Vector2.RIGHT

#jumping related
export var gravity := 15
export var maxFallSpeed := 140
export var jumpForce := 500
export var maxJumps := 2
var jumps := 0
var canDoubleJump := false

export var superJump := false
export var superJumpMultiplier := 1.99

export var coyote_time := false
export var coyote_time_value := 0.4

#slide related 
export var slideTimer := 2.2
var isTraversing := false
var isSlowing := false
var isSliding := false

#movement related
export var maxSpeed := 100
export var accelerationForce := 20
export var slowingFactor_sliding := 0.030
export var slowingFactor_running := 1.000

var motion := Vector2()
var direction := Vector2()
var traverseMotionValue := 0

#shooting related
export var shootCoolDown := 0.6
var canShoot := true
onready var bullet = preload("res://Resources/Bullet.tscn")

#dropping through related
var canDrop := false

#animation related
onready var ani = $AnimatedSprite

#state logic related
const possibleStates = ["IDLE", "RUNNING", "JUMP_UP", "JUMP_DOWN", "SLIDING"]
var IDLE = possibleStates[0]
var RUNNING = possibleStates[1]
var JUMP_UP = possibleStates[2]
var JUMP_DOWN = possibleStates[3]
var SLIDING = possibleStates[4]

var playerState = IDLE

#debug related 
var timestamp = Time.get_datetime_string_from_system()

func _ready():
	direction = RIGHT
	applyTraversePointsLogic()
	
func applyTraversePointsLogic():
	var allTraversePoints = get_tree().get_nodes_in_group("TraversePoint")
	print_debug("There are ", allTraversePoints.size(), " traverse points in ", get_tree().get_current_scene().get_name())
	for traversePoint in allTraversePoints:
		traversePoint.connect("body_entered", self, "changeisTraversingState")
		traversePoint.connect("body_exited", self, "changeisTraversingState")

func _physics_process(delta):
	applyGravity()
	getDirection()
	movementLogic()
	slideLogic()
	jumpLogic()
	superjumpLogic()
	applyMotion()
	applyGunRotation()
	shootLogic()
	dropThroughLogic()
	
	handlePlayerState()
	handlePlayerAnimation(playerState)
		

func handlePlayerState():
	#idling state 
	if is_on_floor() and is_zero_approx(motion.x):
		playerState = IDLE
	#running state
	elif is_on_floor() and !is_zero_approx(motion.x) and isSliding != true:
		playerState = RUNNING
	#sliding state
	elif is_on_floor() and !is_zero_approx(motion.x) and isSliding == true:
		playerState = SLIDING
	#jumping state TODO: check if going up or down, apply animation
	elif not is_on_floor() and !is_zero_approx(motion.y):
		playerState = JUMP_UP
		
func handlePlayerAnimation(playerState):
	#play anim
	ani.play(playerState)
	#direction logic
	if direction == RIGHT:
		ani.set_flip_h(false)
	elif direction == LEFT:
		ani.set_flip_h(true)
	#special logic for sliding rotation
	if playerState == SLIDING:
		ani.set_rotation_degrees(-80)
		ani.set_position(Vector2(-15, 15))
	else:
		ani.set_rotation_degrees(0)
		ani.set_position(Vector2(0, -8))
	
func dropThroughLogic():
	if canDrop == true:
		if Input.is_action_pressed("player_down") and Input.is_action_just_pressed("player_crouch"):
				set_collision_layer_bit(2, false)
				set_collision_mask_bit(2, false)

func shootLogic():
	if Input.is_action_pressed("player_shoot"):
		if canShoot:
			var spawnPoint = $GunShape/ShootStartPoint.get_global_position()
			var newBullet = bullet.instance()
			newBullet.init(direction, spawnPoint)
			#print_debug(timestamp, " initialized a bullet going ", direction, " @ ", spawnPoint)
			get_tree().get_root().add_child(newBullet)
			#print_debug(timestamp, " spawned a bullet going ", direction, " @ ", spawnPoint)
			newBullet.position = spawnPoint
			#print_debug(timestamp, " bullet position is now ", spawnPoint)
			canShoot = false
			yield(get_tree().create_timer(shootCoolDown), "timeout")
			canShoot = true
			
func applyGunRotation():
	var gun = $GunShape
	match direction:
		RIGHT:
			gun.set_rotation_degrees(-90)
		LEFT:
			gun.set_rotation_degrees(90)
		UP:
			gun.set_rotation_degrees(180)
		DOWN:
			gun.set_rotation_degrees(0)
	
func getDirection():
	var lastdirection = direction
	if Input.is_action_just_pressed("player_left"):
		direction = LEFT
	elif Input.is_action_just_pressed("player_right"):
		direction = RIGHT
	elif Input.is_action_just_pressed("player_down"):
		direction = DOWN
	elif Input.is_action_just_pressed("player_up"):
		direction = UP
	if direction != lastdirection:
		#print_debug(timestamp, direction)
		pass
	
func changeisTraversingState(body):
	if body == self:
		print_debug(timestamp, " STATE: isTraversing is now ", !isTraversing)
		isTraversing = !isTraversing
		if isTraversing == false:
			playerCollisionStandUp()
		else:
			traverseMotionValue = motion.x
			playerCollisionSlide()

func playerCollisionStandUp():
	$SlidingCollisionShape.set_disabled(true)
	$StandingCollisionShape.set_disabled(false)

func playerCollisionSlide():
	$SlidingCollisionShape.set_disabled(false)
	$StandingCollisionShape.set_disabled(true)

func superjumpLogic():
	if Input.is_action_just_released("player_superjump_toggle"):
		superJump = !superJump
		print_debug(timestamp, " superjump is now ", superJump)
	
func movementLogic():
	if isSlowing:
		slowingLogic(slowingFactor_sliding)
	else:
		#move no faster than maxSpeed
		motion.x = clamp(motion.x, -maxSpeed, maxSpeed)
		
		if !isTraversing:
			#only if not currently traversing
			if Input.is_action_pressed("player_right"):
				motion.x += accelerationForce
			elif Input.is_action_pressed("player_left"):
				motion.x -= accelerationForce
			else:
				#if not holding movement buttons, slow down
				slowingLogic(slowingFactor_running)
		elif isTraversing:
			motion.x = traverseMotionValue
		
func slowingLogic(slowingFactor):
	#slow down gradually
	motion.x = lerp(motion.x, 0, slowingFactor)
	isSlowing = false
	playerCollisionStandUp()
		
func applyGravity():
	if not is_on_floor(): #turn this line off if should slide down every slope.
		motion.y += gravity
		if motion.y > maxFallSpeed:
			motion.y = maxFallSpeed

func slideLogic():
	#use smaller collision shape
	#when holding action, start slowing down gradually until no motion at all
	#keep sliding position
	#if isTraversing, don't do that, just keep sliding
	
	var isMoving = not is_zero_approx(motion.x)
	#logic with slowing down
	if Input.is_action_pressed("player_crouch"): 
		if is_on_floor() and isMoving and not isSlowing:
			#print_debug(timestamp, " STATE: started sliding")
			while Input.is_action_pressed("player_crouch"):
				playerCollisionSlide()
				isSliding = true
#				#Keep checking for this as long as its pressed
				if not isTraversing:
					isSlowing = true
					#print_debug(timestamp, " STATE: finished sliding")
					break
				else:
					#keep current speed. don't accelerate, don't slow down.
					isSlowing = false
					#print_debug(timestamp, " STATE: trying to stand up but still under a platform!")
					break
	if !Input.is_action_pressed("player_crouch") and not isTraversing:
		isSliding = false
				

			
func jumpLogic():
	#2 phase animation
	#full mobility while in air
	
	#You can jump if you are on the floor, in coyote time or still have double jump
	if is_on_floor() or coyote_time == true:
		jumps = 0
		
	if Input.is_action_just_pressed("player_jump"):
		#super jump logic
		if is_on_floor() and superJump == true:
			motion.y = -jumpForce * superJumpMultiplier
			jumps = maxJumps + 1
			canDoubleJump = false
		#floor jump logic
		elif is_on_floor() and superJump != true:
			motion.y = -jumpForce
			jumps += 1 
			canDoubleJump = true
		#coyote jump logic
		elif !is_on_floor() and coyote_time == true: 
			motion.y = -jumpForce
			jumps += 1
			canDoubleJump = true
		#double jump logic
		elif !is_on_floor() and coyote_time != true and canDoubleJump:
			if jumps <= maxJumps:
				motion.y = -jumpForce
				jumps += 1 
				canDoubleJump = false

func applyMotion():
	motion = move_and_slide(motion, UP)

func _on_DropThroughCheck_body_entered(body):
	if body.is_in_group("DROP_THROUGH_LAYER"):
		canDrop = true

func _on_DropThroughCheck_body_exited(body):
	#Toggle collisions off with drop through objects
	if body.is_in_group("DROP_THROUGH_LAYER"):
		canDrop = false
		set_collision_layer_bit(2, true)
		set_collision_mask_bit(2, true)
	#Enable jumping when leaving any bodies
	coyote_time = true
	#print_debug(timestamp, " time to coyote")
	yield(get_tree().create_timer(coyote_time_value), "timeout")
	coyote_time = false
	#print_debug(timestamp, " time to coyote is now over")
