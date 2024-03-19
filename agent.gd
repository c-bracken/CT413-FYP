extends CharacterBody2D

@export var SPEED: float

@onready var NAV = $NavigationAgent2D
@onready var onLink = false

var next

func _ready():
	NAV.velocity_computed.connect(Callable(velocity_computed))

func navigate_to(destination):
	print("Agent %s navigating to %s through map %s" % [NAV.get_rid(), destination, NAV.get_navigation_map()])
	if onLink:
		await NAV.waypoint_reached
		onLink = false
	NAV.set_target_position(destination)

func _physics_process(delta):
	if NAV.is_navigation_finished(): return
	if NAV.get_current_navigation_path().size() == 0: return
	next = NAV.get_next_path_position()
	NAV.set_velocity(transform.origin.direction_to(next) * SPEED)
	move_and_slide()

func velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func link_entered(_details):
	onLink = true
