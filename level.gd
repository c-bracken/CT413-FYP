extends Node

@onready var REGIONS = $Nav/Regions
@onready var STATIC = $Phys/Static

# Called when the node enters the scene tree for the first time.
func _ready():
	#for i: StaticBody2D in STATIC.get_children():
		#i.add_to_group("navigation")
	#print("Added all static geometry to navigation group")
	$Phys/TileMap.add_to_group("navigation")
	for i: NavigationRegion2D in REGIONS.get_children():
		i.navigation_polygon.clear_polygons()
		i.navigation_polygon.source_geometry_group_name = "navigation"
		i.bake_navigation_polygon()
		await i.bake_finished
	print("Rebaked all navigation polygons")
	
	var cam: Camera2D = $Camera2D
	cam.set
