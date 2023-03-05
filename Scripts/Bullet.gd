extends Area2D

export var speed := 300

func _physics_process(delta):
	position += transform.x * speed * delta

func _on_Bullet_body_entered(body):
	if body.is_in_group("ENEMY_GROUP"):
		#TODO: write logic
		body.queue_free()
	queue_free()


func _on_Bullet_area_entered(area):
	if area.is_in_group("OBSTACLES_GROUP"):
		#TODO: write logic
		queue_free()
