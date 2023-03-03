extends KinematicBody2D

const UP := Vector2.UP

#jumping related
export var gravity := 15
export var maxFallSpeed := 140
export var jumpForce := 500
export var maxJumps := 2

#slide related 
export var slideTimer := 2.2
var underPlatform := false

#movement related
export var maxSpeed := 100
export var accelerationForce := 20


var motion := Vector2()
var jumps := 0



func _ready():
	print_debug("ready here")
	applyTraversePointsLogic()
	
func applyTraversePointsLogic():
	var allTraversePoints = get_tree().get_nodes_in_group("TraversePoint")
	print_debug("There are ", allTraversePoints.size(), " traverse points in ", get_tree().get_current_scene().get_name())
	for traversePoint in allTraversePoints:
		traversePoint.connect("body_entered", self, "changeUnderPlatformState")
		traversePoint.connect("body_exited", self, "changeUnderPlatformState")
		#print_debug(traversePoint, " connected my signals")
		#print_debug(traversePoint.is_connected("body_entered", self, "changeUnderPlatformState"))
		
		
func changeUnderPlatformState(body):
	if body == self:
		print_debug(Time.get_datetime_string_from_system(), " STATE: under platform is now ", !underPlatform)
		underPlatform = !underPlatform
		if underPlatform == false:
			$SlidingCollisionShape.set_disabled(true)
			$StandingCollisionShape.set_disabled(false)
			rotateSprite("standing")
	
func _physics_process(delta):
	
	applyGravity(delta)
	
	#move no faster than maxSpeed
	motion.x = clamp(motion.x, -maxSpeed, maxSpeed)
	
	if Input.is_action_pressed("player_right"):
		motion.x += accelerationForce
	elif Input.is_action_pressed("player_left"):
		motion.x -= accelerationForce
	else:
		#slow down gradually
		motion.x = lerp(motion.x, 0, 0.2)
	
	slideLogic()
	jumpLogic()
	applyMotion()

		
func applyGravity(delta):
	motion.y += gravity
	if motion.y > maxFallSpeed:
		motion.y = maxFallSpeed

func slideLogic():
	var isMoving = not is_zero_approx(motion.x)
	if is_on_floor():
		if Input.is_action_just_pressed("player_crouch") and isMoving:
			print_debug(Time.get_datetime_string_from_system(), " STATE: begun sliding")
			$SlidingCollisionShape.set_disabled(false)
			$StandingCollisionShape.set_disabled(true)
			rotateSprite("sliding")
			yield (get_tree().create_timer(slideTimer), "timeout")
			if not underPlatform:
				print_debug(Time.get_datetime_string_from_system(), " STATE: finished sliding")
				$SlidingCollisionShape.set_disabled(true)
				$StandingCollisionShape.set_disabled(false)
				rotateSprite("standing")
			else:
				print_debug(Time.get_datetime_string_from_system(), " STATE: trying to stand up but still under a platform!")
			
			
func jumpLogic():
	if is_on_floor():
		jumps = 0  
	if Input.is_action_just_pressed("player_jump"): #just pressed here
		jumps += 1
		if jumps <= maxJumps:
			motion.y = -jumpForce

func applyMotion():
	motion = move_and_slide(motion, UP)

func rotateSprite(doingWhat):
	if doingWhat == "sliding":
		$Sprite.set_flip_v(true)
	elif doingWhat == "standing":
		$Sprite.set_flip_v(false)
			
