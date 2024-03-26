extends Node2D

@export var AGENT_RADIUS: int = 4
@export var EXPOSED_PADDING: int = 15
@export var PLAYER: CharacterBody2D
@export var GRACE_TIME: float
@export var LEVEL_TIME: float
@export var PROJECTILE_SPEED: float

@onready var DEFAULT_MAP: RID = get_world_2d().get_navigation_map()
@onready var highscore = 0
@onready var lastScore = 0
@onready var PROJECTILE: PackedScene = preload("res://Scenes/Projectile.tscn")

var level
var score
var levelItems
var itemsLeft
var projectile: RigidBody2D
var graceTimer: Timer
var agents: Array[Node]
var objectives: Array[Node]

func _ready():
	navigation_setup()
	
	# Variable setup
	graceTimer = Timer.new()
	graceTimer.wait_time = GRACE_TIME
	graceTimer.one_shot = true
	add_child(graceTimer)
	
	agents = $Agents.get_children()
	objectives = $Objectives.get_children()
	$Camera2D.make_current()
	
	for i in objectives:
		i.objective_reached.connect(objective_monitor)
	
	for i in agents:
		i.shoot.connect(create_projectile)
	$Player.shoot.connect(create_projectile)
	
	$Player.dead.connect(end_game)
	$Player.p_hit.connect(update_game_ui)
	update_highscore()

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
	score = 0
	$Player.transform.origin = Vector2.ZERO
	$Player.revive()
	$Player.CAM.make_current()
	$Menu.visible = false
	update_game_ui()
	$GameUI.visible = true
	start_level()

# Advance to next level
func next_level():
	print("Advancing to next level")
	level += 1
	for i in agents:
		i.kill()
	grace_period()

func start_level():
	print("Starting level")
	for i in agents:
		i.revive()
	levelItems = min(3 + floor(level * 0.4), objectives.size())
	itemsLeft = levelItems
	update_game_ui()
	randomize_objectives()

func objective_monitor():
	itemsLeft -= 1
	update_score()
	if itemsLeft == 0:
		next_level()

func grace_period():
	print("Grace period begins")
	graceTimer.start()
	await graceTimer.timeout
	start_level()

func end_game():
	print("Ending game")
	lastScore = score
	if score > highscore:
		highscore = score
	update_highscore()
	for i in agents:
		i.kill()
	$Camera2D.make_current()
	$Menu.visible = true
	$GameUI.visible = false

# Create enemy or player projectile
func create_projectile(pos: Vector2, dir: Vector2, player: bool = false):
	var newProj: RigidBody2D = PROJECTILE.instantiate()
	add_child(newProj)
	newProj.transform.origin = pos
	newProj.apply_central_impulse(dir * PROJECTILE_SPEED)
	if player:
		newProj.collision_mask = 0b010010
	else:
		newProj.collision_mask = 0b001010
	newProj.hit.connect(target_hit)

# Increase the player's score
func update_score():
	print("Increasing score")
	score += floor(levelItems + level)
	update_game_ui()

func quit_game():
	get_tree().quit()

func target_hit(body):
	body.hit()

func update_highscore():
	$Menu/Control/VBoxContainer/Highscore.text = "[color=white][outline_size=4][outline_color=black][i]High Score: %d\nLast Score: %d" % [highscore, lastScore]

func randomize_objectives():
	print("Randomizing %d level items" % levelItems)
	var chosen = 0
	for i in range(objectives.size()):
		if chosen == levelItems: return
		var prob = float(levelItems - chosen) / float(objectives.size() - i)
		print("Probability objective %d is chosen: %.3f" % [i, prob])
		if randf() <= prob:
			print("Activating objective %d" % i)
			chosen += 1
			objectives[i].activate()

func update_game_ui():
	$GameUI/Control/HBoxContainer/RichTextLabel.text = "[color=white][outline_size=4][outline_color=black]Level: %d\nObjectives left: %d" % [level, itemsLeft] #level/objectives left
	$GameUI/Control/HBoxContainer/RichTextLabel2.text = "[center][color=white][outline_size=4][outline_color=black]Health: %d" % $Player.health #player health
	$GameUI/Control/HBoxContainer/RichTextLabel3.text = "[right][color=white][outline_size=4][outline_color=black]Score: %d" % score #player score
