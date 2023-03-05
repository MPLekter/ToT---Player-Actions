extends Area2D

const UP := Vector2.UP
const DOWN := Vector2.DOWN
const LEFT := Vector2.LEFT
const RIGHT := Vector2.RIGHT

export var speed := 300
var direction := Vector2()

func init(_direction, _startpoint):
	direction = _direction
	set_position(_startpoint)
	match direction:
		RIGHT:
			set_rotation_degrees(0)
		LEFT:
			set_rotation_degrees(180)
		UP:
			set_rotation_degrees(270)
		DOWN:
			set_rotation_degrees(90)

	
func _physics_process(delta):
	#position += transform.x * speed * delta
	position += direction * speed * delta
	
func _on_Bullet_body_entered(body):
	if body.is_in_group("ENEMY_GROUP"):
		#TODO: write logic
		body.queue_free()
	queue_free()


func _on_Bullet_area_entered(area):
	if area.is_in_group("OBSTACLES_GROUP"):
		#TODO: write logic
		queue_free()
