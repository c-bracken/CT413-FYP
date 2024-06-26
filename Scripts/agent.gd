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
@export var PLAYER: CharacterBody2D

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
@onready var canShoot = true

var behaviour
var next
var lookTarget
var rayQuery: PhysicsRayQueryParameters2D
var rayRes: Dictionary
var lookTimer: Timer
var shotTimer: Timer
var pathTimer: Timer

enum {PATROL, LOOK, FIGHT, HUNT, DEAD}

signal shoot(pos, dir, isPlayer)

func _ready():
	NAV.velocity_computed.connect(_on_nav_velocity_computed)
	lookTimer = Timer.new()
	lookTimer.wait_time = WAIT_TIME
	lookTimer.one_shot = true
	add_child(lookTimer)
	pathTimer = Timer.new()
	pathTimer.wait_time = PATH_TIME
	pathTimer.timeout.connect(_on_pathtimer_timeout)
	add_child(pathTimer)
	shotTimer = Timer.new()
	shotTimer.wait_time = SHOT_TIME
	add_child(shotTimer)
	set_nav_layers(0b011)
	lookTarget = TARGET
	update_state(DEAD)

# Navigate to new position
func navigate_to(destination):
	if destination is Node2D:
		destination = destination.transform.origin
	NAV.set_target_position(destination)

# Physics tick
func _physics_process(delta):
	update_velocity()
	if behaviour != DEAD:
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
			if alert > ALERT_HUNT and (direct or peripheral) and rayRes.collider == PLAYER:
				TARGET.transform.origin = PLAYER.transform.origin
				update_state(HUNT)
			if lookTimer.time_left == 0:
				update_state(PATROL)
		# Fight player
		FIGHT:
			agent_shoot()
			if alert < ALERT_MAX:
				pathTimer.stop()
				shotTimer.stop()
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
		rayQuery = PhysicsRayQueryParameters2D.create(transform.origin, PLAYER.transform.origin, 0b01010)
		rayQuery.exclude = [self]
		rayRes = get_world_2d().direct_space_state.intersect_ray(rayQuery)
		# Raycast hits
		if rayRes:
			# Raycast hits player
			if rayRes.collider == PLAYER:
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
	if behaviour == DEAD:
		NAV.set_velocity(Vector2.ZERO)

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
			lookTarget = PLAYER
			pathTimer.start()
			shotTimer.start()
		HUNT:
			print("%s changing state to HUNT" % name)
			behaviour = HUNT
			alert = clamp(alert, ALERT_HUNT, 0.9 * ALERT_MAX)
			lookTarget = TARGET
			turnSpeed = TURN_INTERP_ALERT
			set_nav_layers(0b001)
			navigate_to(PLAYER)
		_:
			print("%s changing state to DEAD" % name)
			behaviour = DEAD
			$Rotation/Polygon2D.color = 0x888888FF
			lookTimer.stop()
			pathTimer.stop()
			shotTimer.stop()

# Agent hit by projectile
func hit():
	alert = 0.9 * ALERT_MAX
	if behaviour in [PATROL, LOOK]:
		TARGET.transform.origin = PLAYER.transform.origin
	health -= 1
	if health <= 0:
		kill()

# Revive the agent to MAX_HEALTH
func revive():
	health = MAX_HEALTH
	alert = 0
	pathNext = 0
	$Rotation/Polygon2D.color = 0xCA0000FF
	update_state(PATROL)

# Reset the position of and revive the agent
func reset():
	transform.origin = path[0].transform.origin
	revive()

# Allow the agent to fire projectiles at appropriate intervals
func agent_shoot():
	if canShoot:
		canShoot = false
		shoot.emit(transform.origin, transform.origin.direction_to(PLAYER.transform.origin), false)
		await shotTimer.timeout
		canShoot = true

# Kill the agent
func kill():
	update_state(DEAD)

# Navigation agent velocity computed, move agent
func _on_nav_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

# Player enters peripheral vision
func _on_peripheral_body_entered(_body):
	peripheral = true

# Player leaves peripheral vision
func _on_peripheral_body_exited(_body):
	peripheral = false

# Player enters direct vision
func _on_direct_body_entered(_body):
	direct = true

# Player leaves direct vision
func _on_direct_body_exited(_body):
	direct = false

# pathTimer times out, request another path to the player
func _on_pathtimer_timeout():
	navigate_to(PLAYER)
