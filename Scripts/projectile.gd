extends RigidBody2D

# When collision detected, make invisible, stop processing, then delete
func _on_body_entered(body):
	$Polygon2D.visible = false
	process_mode = 4
	queue_free()
