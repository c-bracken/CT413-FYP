extends Node2D

@onready var DEFAULT_MAP: RID = get_world_2d().get_navigation_map()

@export var AGENT_RADIUS: int = 4
@export var EXPOSED_PADDING: int = 15

func _ready():
	# Navigation setup
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
	
	# Rebake covered navmesh
	$Covered.bake_navigation_polygon()
	await $Covered.bake_finished
	print("Rebaked with subtraction")
	
	# Remove previously used Polygon2D nodes
	print("Removing excess Polygon2D nodes")
	for i in extraPolys:
		i.queue_free()

func _process(_delta):
	if Input.is_action_just_pressed("left_mouse"):
		var clickPos = get_viewport().get_mouse_position()
		var clickPosWorld = clickPos - (get_viewport_rect().size / 2)
		for i in $Agents.get_children():
			i.navigate_to(clickPosWorld)
