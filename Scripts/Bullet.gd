extends Area2D

const UP := Vector2.UP
const DOWN := Vector2.DOWN
const LEFT := Vector2.LEFT
const RIGHT := Vector2.RIGHT

export var speed := 300
var direction := Vector2()

func init(_direction, _startpoint):
	direction = _direction
	set_global_position(_startpoint)
	match direction:
		RIGHT:
			set_rotation_degrees(90)
		LEFT:
			set_rotation_degrees(270)
		UP:
			set_rotation_degrees(0)
		DOWN:
			set_rotation_degrees(180)

	
func _physics_process(delta):
	position += direction * speed * delta
	
func _on_Bullet_body_entered(body):
	if body.is_in_group("PLAYER_GROUP"):
		pass
	elif body.is_in_group("ENEMY_GROUP"):
		#TODO: write logic
		body.queue_free()
	elif body.is_in_group("NON-PASSABLE_LAYER"):
		#destroy bullet if hit non-passables
		queue_free()




func _on_VisibilityNotifier2D_screen_exited(): #destroy if left screen
	queue_free()
