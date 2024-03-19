extends CharacterBody2D

var viewportRectSize

@export var SPEED = 20

@onready var mousePos = Vector2.ZERO

func _ready():
	pass

func _process(_delta):
	viewportRectSize = get_viewport_rect().size
	mousePos.x = clampf(get_viewport().get_mouse_position().x, 0, viewportRectSize.x)
	mousePos.y = clampf(get_viewport().get_mouse_position().y, 0, viewportRectSize.y)
	$Cursor.transform.origin = (mousePos - (viewportRectSize / 2)) / $Camera2D.zoom.x
	$Camera2D.transform.origin = transform.origin + ($Cursor.transform.origin - transform.origin) / 2

func _physics_process(delta):
	velocity = Vector2.ZERO
	if Input.is_action_pressed("forward"): velocity += Vector2(0, -1)
	if Input.is_action_pressed("backward"): velocity += Vector2(0, 1)
	if Input.is_action_pressed("left"): velocity += Vector2(-1, 0)
	if Input.is_action_pressed("right"): velocity += Vector2(1, 0)
	velocity *= SPEED
	move_and_slide()
