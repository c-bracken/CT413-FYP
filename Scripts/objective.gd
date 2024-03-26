extends Area2D

@onready var active = false

signal objective_reached

func _ready():
	deactivate()

# Activate objective
func activate():
	print("Activating %s" % name)
	$CollisionShape2D.set_deferred("disabled", false)
	$Polygon2D.visible = true

# Deactivate objective
func deactivate():
	$CollisionShape2D.set_deferred("disabled", true)
	$Polygon2D.visible = false

func _on_body_entered(body):
	objective_reached.emit()
	deactivate()
