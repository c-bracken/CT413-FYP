extends CharacterBody2D

@export var SPEED: float

@onready var NAV = $NavigationAgent2D

var next

func _ready():
	NAV.velocity_computed.connect(Callable(velocity_computed))

func navigate_to(destination):
	print("This agent is on map %s" % NavigationServer2D.agent_get_map(NAV.get_rid()).get_id())
	print("Agent %s navigating to %s through map %s" % [NAV.get_rid(), destination, NAV.get_navigation_map()])
	if NAV.get_navigation_map() != NavigationServer2D.agent_get_map(NAV.get_rid()):
		NAV.set_navigation_map(NavigationServer2D.agent_get_map(NAV.get_rid()))
		print("Corrected to map %s" % NAV.get_navigation_map().get_id())
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
