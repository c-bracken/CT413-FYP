extends CharacterBody2D

@export var SPEED = 30

@onready var mousePos = Vector2.ZERO
@onready var CAM = $Camera2D

var viewportRectSize

signal p_event(action, args)

func _ready():
	pass

func _process(_delta):
	viewportRectSize = get_viewport_rect().size
	mousePos.x = clampf(get_viewport().get_mouse_position().x, 0, viewportRectSize.x)
	mousePos.y = clampf(get_viewport().get_mouse_position().y, 0, viewportRectSize.y)
	$Cursor.transform.origin = (mousePos - (viewportRectSize / 2)) / CAM.zoom.x
	CAM.transform.origin = $Cursor.transform.origin / 2
	$Polygon2D.look_at($Cursor.transform.origin + transform.origin)

func _physics_process(delta):
	velocity = Vector2.ZERO
	if Input.is_action_pressed("forward"): velocity += Vector2(0, -1)
	if Input.is_action_pressed("backward"): velocity += Vector2(0, 1)
	if Input.is_action_pressed("left"): velocity += Vector2(-1, 0)
	if Input.is_action_pressed("right"): velocity += Vector2(1, 0)
	velocity *= SPEED
	move_and_slide()
