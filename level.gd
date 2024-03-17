extends Node

@onready var REGIONS = $Nav/Regions

func _ready():
	$Phys/TileMap.add_to_group("navigation")
	for i: NavigationRegion2D in REGIONS.get_children():
		i.navigation_polygon.source_geometry_group_name = "navigation"
		i.bake_navigation_polygon()
		await i.bake_finished
	print("Rebaked all navigation polygons")
	
	print("Subtracting open areas from base mesh")
	var exposedAreas: NavigationPolygon = $Nav/Regions/Exposed.navigation_polygon
	var exposedVerts: PackedVector2Array = exposedAreas.get_vertices()
	var extraPolys: Array = []
	print("Vertices: %s" % exposedVerts)
	for i in exposedAreas.get_polygon_count():
		var newPoly: Polygon2D = Polygon2D.new()
		var newVerts = []
		var exposedPoly = exposedAreas.get_polygon(i)
		print("Polygon %d: %s" % [i, exposedPoly])
		for j in exposedPoly:
			newVerts.append(exposedVerts[j])
		newPoly.polygon = PackedVector2Array(newVerts)
		newPoly.add_to_group("navigation")
		extraPolys.append(newPoly)
		self.add_child(newPoly)
	
	$Nav/Regions/Covered.bake_navigation_polygon()
	await $Nav/Regions/Covered.bake_finished
	print("Rebaked with subtraction")
	
	print("Removing excess Polygon2D nodes")
	for i in extraPolys:
		i.queue_free()
