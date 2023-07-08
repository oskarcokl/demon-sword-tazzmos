extends RigidBody2D

@onready var _polygon: Polygon2D = $Polygon2D

func get_polygon() -> PackedVector2Array:
    return _polygon.polygon
