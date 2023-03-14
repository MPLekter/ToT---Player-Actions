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
export var maxSpeed := 200
export var accelerationForce := 20
export var slowingFactor_sliding := 0.030
export var slowingFactor_running := 1.000

var motion := Vector2()
var direction := Vector2()
var lastDirectionHorizontal := Vector2()
var traverseMotionValue := 0

#shooting related
export var shootCoolDown := 0.6
var canShoot := true
var isAimingUp := false
var isAimingDown := false
onready var bullet = preload("res://Resources/Bullet.tscn")

#dropping through related
var canDrop := false

#animation related
onready var ani = $AnimatedSprite

#state logic related
const possibleStates = ["IDLE", "RUNNING", "JUMP_UP", "JUMP_DOWN", "SLIDING", "AIM_UP", "AIM_DOWN"]
var IDLE = possibleStates[0]
var RUNNING = possibleStates[1]
var JUMP_UP = possibleStates[2]
var JUMP_DOWN = possibleStates[3]
var SLIDING = possibleStates[4]
var AIM_UP = possibleStates[5]
var AIM_DOWN = possibleStates[6]

var playerState = IDLE

#camera related
onready var camera = $ShakeCamera2D

#debug related 
var timestamp = Time.get_datetime_string_from_system()
onready var stateLabel = $EDITOR_ONLY_stateLabel

func _ready():
	direction = RIGHT
	lastDirectionHorizontal = RIGHT
	
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
	
	handlePlayerCollisionShape()
	
	movementLogic()
	slideLogic()
	jumpLogic()
	superjumpLogic()
	applyMotion()
	applyGunRotation()
	shootLogic()
	dropThroughLogic()
	
	handlePlayerState()
	flipPlayerAnimation(playerState)
		
func handlePlayerCollisionShape():
	if isTraversing:
		playerCollisionSlide()
	elif !isTraversing:
		if Input.is_action_pressed("player_crouch"):
			playerCollisionSlide()
		else:
			playerCollisionStandUp()
			
func handlePlayerState():
	#aiming vertical
	if isAimingUp == true:
		playerState = AIM_UP
	elif isAimingDown == true:
		playerState = AIM_DOWN
	else:
		#idling state 
		if is_on_floor() and motion.x == 0 and isSliding != true and isTraversing != true:
			playerState = IDLE
		#running state
		elif is_on_floor() and motion.x >= (3 * accelerationForce) and isSliding != true and isTraversing != true:
			playerState = RUNNING
		elif is_on_floor() and motion.x <= (-3 * accelerationForce) and isSliding != true and isTraversing != true:
			playerState = RUNNING
		#sliding state
		elif is_on_floor() and isSliding == true or isTraversing == true:
			playerState = SLIDING
		#jumping state TODO: check if going up or down, apply animation
		elif not is_on_floor() and motion.y >= accelerationForce:
			playerState = JUMP_UP
		elif not is_on_floor() and motion.y <= -accelerationForce:
			playerState = JUMP_UP
		
func flipPlayerAnimation(playerState):
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
	
	#show animation in label
	stateLabel.text = "animation: " + playerState
	
func dropThroughLogic():
	if canDrop == true:
		while Input.is_action_pressed("player_down") and Input.is_action_just_pressed("player_crouch"):
				set_collision_layer_bit(2, false)
				set_collision_mask_bit(2, false)
				break

func shootLogic():
	if Input.is_action_pressed("player_shoot"):
		#check if can shoot
		if canShoot:
			#Recoil: determine spawnpoint at one of three possible positions
			var recoil = recoilLogic()
			var spawnPoint = $GunShape/ShootStartPoint.get_global_position() + recoil
			var newBullet = bullet.instance()
			newBullet.init(direction, spawnPoint)
			get_tree().get_root().add_child(newBullet)
			#print_debug(timestamp, " spawned a bullet going ", direction, " @ ", spawnPoint)

			#try shake camera
			shakeCamera()
			
			#wait until ready to shoot again
			canShoot = false
			yield(get_tree().create_timer(shootCoolDown), "timeout")
			canShoot = true
			
func shakeCamera():
	camera.shake(0.2, 15.0, 8.0) #these values are somewhat random
	
func recoilLogic():
	#make new array and add vectors normal, slightly up, slightly down
	var spawnPositions = []
	spawnPositions.append(Vector2.ZERO)
	spawnPositions.append(Vector2(0, -1))
	spawnPositions.append(Vector2(0, -2))
	spawnPositions.append(Vector2(0, -3))
	spawnPositions.append(Vector2(0, 1))
	spawnPositions.append(Vector2(0, 2))
	spawnPositions.append(Vector2(0, 3))
	
	#make sure seed is randomized
	randomize()
	#now pick any random vector from the array and return it to shootLogic function
	var randomizedPosition = spawnPositions[randi() % spawnPositions.size()]
	return randomizedPosition
	
func applyGunRotation(): #TODO: possibly this will not be needed anymore?
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

	if Input.is_action_pressed("player_left"):
		direction = LEFT
		lastDirectionHorizontal = LEFT
	elif Input.is_action_pressed("player_right"):
		direction = RIGHT
		lastDirectionHorizontal = RIGHT
		
	#as long as holding up or down, the direction is up or down.
	#but it won't happen if you are running at the same time.
	while Input.is_action_pressed("player_down") and not playerState == RUNNING:
		isAimingDown = true
		direction = DOWN
		break
	while Input.is_action_pressed("player_up") and not playerState == RUNNING:
		isAimingUp = true
		direction = UP
		break
		
	#once you release it, direction is lastly used horizontal
	if Input.is_action_just_released("player_down") or Input.is_action_just_released("player_up"):
			isAimingUp = false
			isAimingDown = false
			direction = lastDirectionHorizontal

		
	#TODO: check if needed anymore
	if direction != lastdirection:
		#print_debug(timestamp, direction)
		pass
	
func changeisTraversingState(body): #TODO: something is off here. It keeps turning on and off too much 
	if body == self:
		print_debug(timestamp, " STATE: isTraversing is now ", !isTraversing)
		isTraversing = !isTraversing
		if isTraversing == true:
			traverseMotionValue = motion.x

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
		#you can't move when you are on ground and aiming up or down
		if is_on_floor() and isAimingUp or isAimingDown:
			motion.x == 0
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
