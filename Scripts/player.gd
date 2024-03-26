extends CharacterBody2D

@export var SPEED: float = 30.0
@export var SHOT_TIME: float
@export var MAX_HEALTH: int

@onready var mousePos = Vector2.ZERO
@onready var CAM = $Camera2D
@onready var isPlayer = true
@onready var canShoot = true
@onready var health = 0

var viewportRectSize
var shotTimer: Timer

signal shoot(pos, dir, isPlayer)
signal dead
signal p_hit

func _ready():
	shotTimer = Timer.new()
	shotTimer.wait_time = SHOT_TIME
	shotTimer.one_shot = true
	add_child(shotTimer)
	revive()

func _process(_delta):
	viewportRectSize = get_viewport_rect().size
	mousePos.x = clampf(get_viewport().get_mouse_position().x, 0, viewportRectSize.x)
	mousePos.y = clampf(get_viewport().get_mouse_position().y, 0, viewportRectSize.y)
	$Cursor.transform.origin = (mousePos - (viewportRectSize / 2)) / CAM.zoom.x
	CAM.transform.origin = $Cursor.transform.origin / 2
	$Polygon2D.look_at($Cursor.transform.origin + transform.origin)

func _physics_process(delta):
	if health > 0:
		velocity = Vector2.ZERO
		if Input.is_action_pressed("forward"): velocity += Vector2(0, -1)
		if Input.is_action_pressed("backward"): velocity += Vector2(0, 1)
		if Input.is_action_pressed("left"): velocity += Vector2(-1, 0)
		if Input.is_action_pressed("right"): velocity += Vector2(1, 0)
		if Input.is_action_pressed("left_mouse"): player_shoot()
		velocity *= SPEED
		move_and_slide()

func player_shoot():
	if canShoot:
		canShoot = false
		shoot.emit(transform.origin, transform.origin.direction_to($Cursor.transform.origin + transform.origin), true)
		shotTimer.start()
		await shotTimer.timeout
		canShoot = true

func revive():
	health = MAX_HEALTH

func hit():
	health -= 1
	p_hit.emit()
	if health <= 0:
		dead.emit()
