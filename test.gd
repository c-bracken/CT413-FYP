extends Node2D

var points = PackedVector2Array([Vector2(-200, -200), Vector2(200, -200), Vector2(200, 200), Vector2(-200, 200)])
var newNavmesh = NavigationPolygon.new()
var path: NavigationPathQueryResult2D
var map

@onready var agent = $Nav/Agents/Agent

func _ready():
	call_deferred("nav_setup")

func nav_setup():
	map = NavigationServer2D.map_create()
	NavigationServer2D.map_set_cell_size(map, 1.0)
	NavigationServer2D.map_set_edge_connection_margin(map, 20)
	NavigationServer2D.map_set_link_connection_radius(map, 4)
	NavigationServer2D.map_set_active(map, true)
	print("Map RID: %s" % map.get_id())
	NavigationServer2D.region_set_map($Nav/Regions/NavigationRegion2D, map)
	NavigationServer2D.region_set_map($Nav/Regions/NavigationRegion2D2, map)
	NavigationServer2D.link_set_map($Nav/Links/NavigationLink2D, map)
	NavigationServer2D.agent_set_map($Nav/Agents/Agent/NavigationAgent2D, map)
	NavigationServer2D.obstacle_set_map($Nav/Obstacles/NavigationObstacle2D, map)
	await get_tree().physics_frame
	print("Map regions: %s" % [NavigationServer2D.map_get_regions(map)])
	print("Map links: %s" % [NavigationServer2D.map_get_links(map)])
	print("Map agents: %s" % [NavigationServer2D.map_get_agents(map)])
	print("Map obstacles: %s" % [NavigationServer2D.map_get_obstacles(map)])

#func _draw():
	#if path != null:
		#points = path.get_path()
		#for i in range(points.size()):
			#draw_circle(points[i], 5.0, Color.hex(0x00FF00FF))
		#for i in range(points.size() - 1):
			#draw_line(points[i], points[i + 1], Color.RED)
