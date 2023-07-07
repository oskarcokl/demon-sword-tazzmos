extends Node2D

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_polyong: CollisionPolygon2D = $CollisionPolygon2D

# Called when the node enters the scene tree for the first time.
func _ready():
	draw_polygon_rect()

func draw_polygon_rect():
	# Looks like the the vertices are relative to the polygon anchor
	var vertices = PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, 32),
		Vector2(32, 32),
		Vector2(32, 0),
	])
	polygon.polygon = vertices
	polygon.scale = Vector2(7, 7)
	collision_polyong.polygon = vertices
	collision_polyong.scale = Vector2(7, 7)

func _input(event: InputEvent) -> void:
	pass


func _on_mouse_entered():
	print("Mouse entered")
