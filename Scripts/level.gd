extends Node2D

@export var AGENT_RADIUS: int = 4
@export var EXPOSED_PADDING: int = 15
@export var PLAYER: CharacterBody2D
@export var GRACE_TIME: float
@export var LEVEL_TIME: float
@export var PROJECTILE_SPEED: float

@onready var DEFAULT_MAP: RID = get_world_2d().get_navigation_map()
@onready var highscore = 0
@onready var PROJECTILE: PackedScene = preload("res://Scenes/Projectile.tscn")

var level
var score
var levelItems
var projectile: RigidBody2D
var graceTimer: Timer
var levelTimer: Timer
var agents: Array[Node]
var objectives: Array[Node]

func _ready():
	navigation_setup()
	
	# Variable setup
	graceTimer = Timer.new()
	graceTimer.wait_time = GRACE_TIME
	graceTimer.one_shot = true
	add_child(graceTimer)
	
	levelTimer = Timer.new()
	levelTimer.wait_time = LEVEL_TIME
	levelTimer.one_shot = true
	levelTimer.timeout.connect(level_timer_expired)
	add_child(levelTimer)
	
	agents = $Agents.get_children()
	objectives = $Objectives.get_children()
	$Camera2D.make_current()
	
	for i in objectives:
		i.objective_reached.connect(update_score)

# Set up navigation areas
func navigation_setup():
	print("Default map: %s" % DEFAULT_MAP.get_id())
	NavigationServer2D.map_set_edge_connection_margin(DEFAULT_MAP, float(AGENT_RADIUS * 2))
	$Covered.navigation_polygon.agent_radius = AGENT_RADIUS
	$Exposed.navigation_polygon.agent_radius = AGENT_RADIUS + EXPOSED_PADDING
	
	# Inital navigation mesh bake
	$TileMap.add_to_group("navigation")
	$Covered.navigation_polygon.source_geometry_group_name = "navigation"
	$Exposed.navigation_polygon.source_geometry_group_name = "navigation"
	$Covered.bake_navigation_polygon()
	await $Covered.bake_finished
	$Exposed.bake_navigation_polygon()
	await $Exposed.bake_finished
	print("Rebaked all navigation polygons")
	
	# Remove open areas from covered mesh
	print("Subtracting open areas from base mesh")
	var exposedAreas: NavigationPolygon = $Exposed.navigation_polygon
	var exposedVerts: PackedVector2Array = exposedAreas.get_vertices()
	var extraPolys: Array = []
	# For every polygon in the exposed mesh, make a copy as a Polygon2D
	for i in exposedAreas.get_polygon_count():
		var newPoly: Polygon2D = Polygon2D.new()
		var newVerts = []
		var exposedPoly = exposedAreas.get_polygon(i)
		for j in exposedPoly:
			newVerts.append(exposedVerts[j])
		newPoly.polygon = PackedVector2Array(newVerts)
		newPoly.add_to_group("navigation")
		extraPolys.append(newPoly)
		self.add_child(newPoly)
		print("Added polygon %d to the scene" % i)
	
	# Rebake covered navmesh
	print("Rebaking navmesh")
	$Covered.bake_navigation_polygon()
	await $Covered.bake_finished
	print("Rebaked with subtraction")
	
	# Remove previously used Polygon2D nodes
	print("Removing excess Polygon2D nodes")
	for i in extraPolys:
		i.queue_free()

# Let player be controlled, reset score, etc.
func start_game():
	print("Starting game")
	for i in agents:
		i.reset()
	level = 0
	levelItems = min(3 + floor(level * 0.4), 12)
	score = 0
	$Player.transform.origin = Vector2.ZERO
	$Player.CAM.make_current()
	$Camera2D/Control.visible = false
	start_level()

# Advance to next level
func next_level():
	print("Advancing to next level")
	level += 1
	grace_period()

func start_level():
	print("Starting level")
	for i in agents:
		i.revive()
	# place objects randomly
	levelTimer.start()

func grace_period():
	print("Grace period begins")
	graceTimer.start()
	await graceTimer.timeout
	start_level()

func end_game():
	print("Ending game")
	if score > highscore:
		highscore = score
	# kill agents
	$Camera2D.make_current()
	$Camera2D/Control.visible = true

# Create enemy or player projectile
func create_projectile(pos: Vector2, dir: Vector2, player: bool = false):
	var newProj: RigidBody2D = PROJECTILE.instantiate()
	add_child(newProj)
	newProj.transform.origin = pos
	newProj.apply_central_impulse(dir * PROJECTILE_SPEED)

# Increase the player's score
func update_score():
	print("Increasing score")
	score += floor(levelItems * (levelTimer.time_left + level))

# Set enemies to aggressive when timer expires
func level_timer_expired():
	print("Level timer expired")

func quit_game():
	get_tree().quit()
