extends CharacterBody2D

@export var FAST_SPEED: float
@export var SPEED: float
@export var SLOW_SPEED: float
@export var STATE_TIMER_DELAY: float = 1
@export var ALERT_RATE: float
@export var ALERT_DECAY: float
@export var ALERT_MAX: float
@export var ALERT_SEARCH: float

@onready var NAV: NavigationAgent2D = $NavigationAgent2D
@onready var ROTATION: Node2D = $Rotation
@onready var VISION: Area2D = $Rotation/Vision
@onready var patrolPoints = []
@onready var patrolIndex: int = 0
@onready var peripheral = false
@onready var direct = false
@onready var alertness = 0
@onready var alertMult = 0

var next
var target

enum Life {ALIVE, DEAD}
enum Alive {PATROL, COMBAT}
enum Patrol {MOVING, STATIONARY}
enum Combat {FIGHT, HUNT, RELOAD}

signal timer

func _ready():
	NAV.velocity_computed.connect(_on_nav_velocity_computed)

# Navigate to new position
func navigate_to(destination):
	NAV.set_target_position(destination)

# Physics tick
func _physics_process(delta):
	look_at(transform.origin + Vector2.UP)
	update_velocity()
	update_target()
	update_rotation()
	update_alertness(delta)

func update_velocity():
	if NAV.is_navigation_finished(): return
	if NAV.get_current_navigation_path().size() == 0: return
	
	next = NAV.get_next_path_position()
	
	# Change navigation agent velocity - this triggers _on_nav_velocity_computed below
	NAV.set_velocity(transform.origin.direction_to(next) * SPEED)

func update_target():
	target = transform.origin + transform.origin.direction_to(NAV.get_next_path_position())

func update_rotation():
	if target != null:
		ROTATION.look_at(target)

# Update the agent's alertness value
func update_alertness(delta):
	alertness = clampf(alertness + (ALERT_RATE * alertMult * delta), 0, ALERT_MAX)

# Navigation agent velocity computed
func _on_nav_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func set_nav_layers(layers):
	NAV.navigation_layers = layers

func _on_peripheral_body_entered(body):
	peripheral = true

func _on_peripheral_body_exited(body):
	peripheral = false

func _on_direct_body_entered(body):
	direct = true

func _on_direct_body_exited(body):
	direct = false
