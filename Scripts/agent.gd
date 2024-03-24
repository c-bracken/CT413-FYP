extends CharacterBody2D

@export var SPEED: float
@export var ALERT_RATE: float
@export var ALERT_DECAY: float
@export var ALERT_MAX: float
@export var ALERT_HUNT: float
@export var MAX_HEALTH: int
@export var path: Array[Node2D]
@export var WAIT_TIME: float
@export var SHOT_TIME: float
@export var PATH_TIME: float
@export var TURN_INTERP: float
@export var TURN_INTERP_ALERT: float

@onready var NAV: NavigationAgent2D = $NavigationAgent2D
@onready var ROTATION: Node2D = $Rotation
@onready var TARGET: Node2D = $Target
@onready var peripheral = false
@onready var direct = false
@onready var alert = 0
@onready var alertMult = 0
@onready var health = MAX_HEALTH
@onready var pathNext = 0
@onready var turnSpeed = TURN_INTERP

var behaviour
var next
var lookTarget
var rayQuery: PhysicsRayQueryParameters2D
var rayRes: Dictionary
var player: CharacterBody2D
var lookTimer: Timer
var shotTimer: Timer
var pathTimer: Timer

enum {PATROL, LOOK, FIGHT, HUNT, DEAD}

func _ready():
	NAV.velocity_computed.connect(_on_nav_velocity_computed)
	player = get_tree().root.get_child(0).PLAYER
	lookTimer = Timer.new()
	lookTimer.wait_time = WAIT_TIME
	lookTimer.one_shot = true
	add_child(lookTimer)
	pathTimer = Timer.new()
	pathTimer.wait_time = PATH_TIME
	pathTimer.timeout.connect(_on_pathtimer_timeout)
	add_child(pathTimer)
	set_nav_layers(0b011)
	update_state(PATROL)

# Navigate to new position
func navigate_to(destination):
	if destination is Node2D:
		destination = destination.transform.origin
	NAV.set_target_position(destination)

# Physics tick
func _physics_process(delta):
	#look_at(transform.origin + Vector2.UP)
	update_velocity()
	update_rotation()
	change_alert_rate()
	alert = clampf(alert + (ALERT_RATE * alertMult * delta), 0, ALERT_MAX)
	
	# Trigger state changes
	match behaviour:
		# Patrol between points
		PATROL:
			if alert > ALERT_HUNT:
				update_state(HUNT)
			if NAV.is_navigation_finished():
				pathNext = (pathNext + 1) % path.size()
				update_state(LOOK)
		# Look around from current position
		LOOK:
			if alert > ALERT_HUNT and rayRes.collider == player and (direct or peripheral):
				update_state(HUNT)
			if lookTimer.time_left == 0:
				update_state(PATROL)
		# Fight player
		FIGHT:
			if alert < ALERT_MAX:
				pathTimer.stop()
				update_state(HUNT)
		# Chase player
		HUNT:
			if alert == ALERT_MAX:
				update_state(FIGHT)
			if NAV.is_navigation_finished():
				update_state(LOOK)
		_:
			return

func change_alert_rate():
	# Modify alert rate
	alertMult = ALERT_DECAY
	# Player in vision zones
	if peripheral or direct:
		rayQuery = PhysicsRayQueryParameters2D.create(transform.origin, player.transform.origin)
		rayQuery.exclude = [self]
		rayRes = get_world_2d().direct_space_state.intersect_ray(rayQuery)
		# Raycast hits
		if rayRes:
			# Raycast hits player
			if rayRes.collider == player:
				alertMult = (0.4 if peripheral else 0.0) + (0.6 if direct else 0.0)
	if behaviour == HUNT:
		alertMult = max(alertMult, 0)

func update_velocity():
	if NAV.is_navigation_finished() or (NAV.get_current_navigation_path().size() == 0):
		return
	
	# Still on a path, set velocity
	next = NAV.get_next_path_position()
	if behaviour == PATROL:
		TARGET.transform.origin = next
	elif behaviour == HUNT:
		TARGET.transform.origin = NAV.get_final_position()
	NAV.set_velocity(transform.origin.direction_to(next) * SPEED)

# Update the rotation of agent sprite & vision zones
func update_rotation():
	var targetTransform = ROTATION.transform.looking_at(lookTarget.transform.origin - transform.origin)
	ROTATION.transform = ROTATION.transform.interpolate_with(targetTransform, turnSpeed)

# 0b001 for covered only
# 0b011 for covered and exposed
func set_nav_layers(layers):
	NAV.navigation_layers = layers

# Handle state updates
func update_state(newState):
	match newState:
		PATROL:
			print("%s changing state to PATROL" % name)
			behaviour = PATROL
			set_nav_layers(0b011)
			navigate_to(path[pathNext])
			lookTarget = TARGET
		LOOK:
			print("%s changing state to LOOK" % name)
			behaviour = LOOK
			turnSpeed = TURN_INTERP
			lookTimer.start()
		FIGHT:
			print("%s changing state to FIGHT" % name)
			behaviour = FIGHT
			lookTarget = player
			pathTimer.start()
			set_nav_layers(0b001)
		HUNT:
			print("%s changing state to HUNT" % name)
			behaviour = HUNT
			alert = clamp(alert, ALERT_HUNT, 0.9 * ALERT_MAX)
			lookTarget = TARGET
			turnSpeed = TURN_INTERP_ALERT
			set_nav_layers(0b001)
			navigate_to(player)
		_:
			print("%s changing state to DEAD" % name)
			behaviour = DEAD

func hit():
	alert = ALERT_MAX
	health -= 1
	if health <= 0:
		update_state(DEAD)
		await get_tree().root.get_child(0).next_level
		revive()

func revive():
	health = MAX_HEALTH
	alert = 0
	update_state(PATROL)

func reset():
	transform.origin = path[0].transform.origin
	revive()

# Navigation agent velocity computed
func _on_nav_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func _on_peripheral_body_entered(_body):
	peripheral = true

func _on_peripheral_body_exited(_body):
	peripheral = false

func _on_direct_body_entered(_body):
	direct = true

func _on_direct_body_exited(_body):
	direct = false

func _on_pathtimer_timeout():
	navigate_to(player)
