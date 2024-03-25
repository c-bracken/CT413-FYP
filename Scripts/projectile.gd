extends RigidBody2D

signal hit(body)

# When collision detected, make invisible, stop processing, then delete
func _on_body_entered(body):
	if body.name.begins_with("Agent") or body.name.begins_with("Player"):
		hit.emit(body)
	$Polygon2D.visible = false
	for i in hit.get_connections():
		hit.disconnect(i.callable)
	queue_free()
