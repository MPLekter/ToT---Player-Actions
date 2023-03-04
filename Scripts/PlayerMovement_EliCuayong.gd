extends KinematicBody2D

const UP := Vector2.UP

#jumping related
export var gravity := 15
export var maxFallSpeed := 140
export var jumpForce := 500
export var maxJumps := 2
var jumps := 0
export var superJump := false
export var superJumpMultiplier := 1.99

#slide related 
export var slideTimer := 2.2
var underPlatform := false

#movement related
export var maxSpeed := 100
export var accelerationForce := 20
var motion := Vector2()

#debug related 
var timestamp = Time.get_datetime_string_from_system()




func _ready():
	applyTraversePointsLogic()
	
func applyTraversePointsLogic():
	var allTraversePoints = get_tree().get_nodes_in_group("TraversePoint")
	print_debug("There are ", allTraversePoints.size(), " traverse points in ", get_tree().get_current_scene().get_name())
	for traversePoint in allTraversePoints:
		traversePoint.connect("body_entered", self, "changeUnderPlatformState")
		traversePoint.connect("body_exited", self, "changeUnderPlatformState")
		#print_debug(traversePoint, " connected my signals")
		#print_debug(traversePoint.is_connected("body_entered", self, "changeUnderPlatformState"))
		
func _physics_process(delta):
	
	applyGravity()
	movementLogic()
	slideLogic()
	jumpLogic()
	superjumpLogic()
	applyMotion()
		
func changeUnderPlatformState(body):
	if body == self:
		print_debug(timestamp, " STATE: under platform is now ", !underPlatform)
		underPlatform = !underPlatform
		if underPlatform == false:
			playerStandUp()

			
func playerStandUp():
	$SlidingCollisionShape.set_disabled(true)
	$StandingCollisionShape.set_disabled(false)
	rotateSprite("standing")

func playerSlide():
	$SlidingCollisionShape.set_disabled(false)
	$StandingCollisionShape.set_disabled(true)
	rotateSprite("sliding")
			
	
func superjumpLogic():
	if Input.is_action_just_released("player_superjump_toggle"):
		superJump = !superJump
		print_debug(timestamp, " superjump is now ", superJump)
	
func movementLogic():
	#move no faster than maxSpeed
	motion.x = clamp(motion.x, -maxSpeed, maxSpeed)
	
	if Input.is_action_pressed("player_right"):
		motion.x += accelerationForce
	elif Input.is_action_pressed("player_left"):
		motion.x -= accelerationForce
	else:
		#slow down gradually
		motion.x = lerp(motion.x, 0, 0.2)
		
func applyGravity():
	motion.y += gravity
	if motion.y > maxFallSpeed:
		motion.y = maxFallSpeed

func slideLogic():
	#use smaller collision shape
	#when holding action, start slowing down gradually until no motion at all
	#keep sliding position
	#if underPlatform, don't do that, just keep sliding
	var isMoving = not is_zero_approx(motion.x)
	if is_on_floor():
		if Input.is_action_just_pressed("player_crouch") and isMoving:
			print_debug(timestamp, " STATE: begun sliding")
			playerSlide()
			yield (get_tree().create_timer(slideTimer), "timeout")
			if not underPlatform:
				print_debug(timestamp, " STATE: finished sliding")
				playerStandUp()
			else:
				print_debug(timestamp, " STATE: trying to stand up but still under a platform!")
			
func jumpLogic():
	#2 phase animation
	#full mobility while in air
	if is_on_floor():
		jumps = 0  
	if Input.is_action_just_pressed("player_jump"): 
		if jumps <= maxJumps:
			if not superJump:
				jumps += 1 #double jump if not double jumped already
				motion.y = -jumpForce
			else:
				jumps = maxJumps + 1 #no double jump for superJump
				motion.y = -jumpForce * superJumpMultiplier

func applyMotion():
	motion = move_and_slide(motion, UP)

func rotateSprite(doingWhat):
	if doingWhat == "sliding":
		$Sprite.set_flip_v(true)
	elif doingWhat == "standing":
		$Sprite.set_flip_v(false)
			
