extends CharacterBody2D

@export var SPEED: float
@export var STATE_TIMER_DELAY: float = 1

@onready var NAV = $NavigationAgent2D

var next
var stateTimer

signal timer

func _ready():
	stateTimer = Timer.new()
	stateTimer.wait_time = STATE_TIMER_DELAY
	stateTimer.timeout.connect(_on_timer_timeout)
	stateTimer.autostart = true
	add_child(stateTimer)
	
	NAV.velocity_computed.connect(_on_nav_velocity_computed)

# Navigate to new position
func navigate_to(destination):
	NAV.set_target_position(destination)

# Physics tick
func _physics_process(delta):
	if NAV.is_navigation_finished(): return
	if NAV.get_current_navigation_path().size() == 0: return
	
	next = NAV.get_next_path_position()
	
	# Change navigation agent velocity - this triggers _on_nav_velocity_computed below
	NAV.set_velocity(transform.origin.direction_to(next) * SPEED)

# Navigation agent velocity computed
func _on_nav_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func set_nav_layers(layers):
	NAV.navigation_layers = layers

func _on_timer_timeout():
	pass
