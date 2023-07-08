extends Polygon2D

@export_color_no_alpha var start_color = Color(1.5, 1.5, 1.5, 1.0)
@export_color_no_alpha var end_color = Color(1.0, 1.0, 1.0, 0.1)
@export var fade_speed: float = 1.0

var t: float = 0.0


func _ready():
    set_process(false)
    visible = false


func create_cut_visualizer(pos: Vector2, fade_speed: float = 1.0) -> void:
    global_position = pos
    visible = true
    if fade_speed > 0.0:
        self.fade_speed = fade_speed
        set_process(true)


func _process(delta: float) -> void:
    if fade_speed > 0.0:
        t += delta * fade_speed

    color = lerp(start_color, end_color, t)

    if t >= 1.0:
        queue_free()

func set_polygon_custom(poly: PackedVector2Array) -> void:
    t = 0.0
    color = start_color
    set_polygon(poly)
