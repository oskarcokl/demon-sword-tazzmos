extends RigidBody2D


@export var move_speed = 5.0

@onready var _polygon: Polygon2D = $Polygon2D
@onready var _collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _death_sound: AudioStreamPlayer = $Death
@onready var _can_die = true


func _ready() -> void:
    _collision_polygon.polygon = _polygon.polygon


func set_can_die(die: bool) -> void:
    _can_die = die

func kill():
    if _can_die:
        _animated_sprite.visible = false
        _collision_polygon.disabled = true
        _death_sound.play()

func get_polygon() -> PackedVector2Array:
    return _polygon.polygon


func get_uv() -> PackedVector2Array:
    return _polygon.uv


func set_polygon_custom(poly : PackedVector2Array) -> void:
    _polygon.set_polygon(poly)
    _collision_polygon.set_polygon(poly)
    poly.append(poly[0])

func set_uv(uv: PackedVector2Array) -> void:
    _polygon.uv = uv

func getTextureInfo() -> Dictionary:
    return {"texture" : _polygon.texture, "rot" : _polygon.texture_rotation, "offset" : _polygon.texture_offset, "scale" : _polygon.texture_scale}

func set_texture(texture_info : Dictionary) -> void:
    _polygon.texture = texture_info.texture
    _polygon.texture_scale = texture_info.scale
    _polygon.texture_offset = texture_info.offset
    _polygon.texture_rotation = texture_info.rot


func hide_animated_sprite() -> void:
    _animated_sprite.visible = false


func show_polygon() -> void:
    _polygon.visible = true


func dead() -> void:
    hide_animated_sprite()
    show_polygon()
    move_speed = 3.0
    _collision_polygon.disabled = true
    gravity_scale = 6.0


func _physics_process(_delta: float) -> void:
    var movement_vector = Vector2.LEFT * move_speed
    move_and_collide(movement_vector)



func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()


func _on_death_finished() -> void:
    queue_free()
