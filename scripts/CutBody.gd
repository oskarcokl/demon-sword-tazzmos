extends RigidBody2D

@onready var _polygon: Polygon2D = $Polygon2D
@onready var _collision_polygon: CollisionPolygon2D = $CollisionPolygon2D

func get_polygon() -> PackedVector2Array:
    return _polygon.polygon

func set_polygon_custom(poly : PackedVector2Array) -> void:
    _polygon.set_polygon(poly)
    _collision_polygon.set_polygon(poly)
    poly.append(poly[0])

func getTextureInfo() -> Dictionary:
    return {"texture" : _polygon.texture, "rot" : _polygon.texture_rotation, "offset" : _polygon.texture_offset, "scale" : _polygon.texture_scale}

func set_texture(texture_info : Dictionary) -> void:
    _polygon.texture = texture_info.texture
    _polygon.texture_scale = texture_info.scale
    _polygon.texture_offset = texture_info.offset
    _polygon.texture_rotation = texture_info.rot
