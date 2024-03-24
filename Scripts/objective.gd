extends Area2D

@onready var active = false

signal objective_reached

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Activate objective
func activate():
	pass

# Deactivate objective
func deactivate():
	pass

func _on_body_entered(body):
	objective_reached.emit()
	deactivate()
