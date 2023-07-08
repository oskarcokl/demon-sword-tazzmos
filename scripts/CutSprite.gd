extends Node2D

# exposed vars
@export var cut_visualizer: PackedScene

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_polyong: CollisionPolygon2D = $CollisionPolygon2D
@onready var _cut_line: Line2D = get_tree().get_root().get_node("Prototype/CutLine")


const CUT_LINE_STATIONARY_DELAY : float = 0.1 #after that amount of seconds remaining stationary will end the cut line process and cut the sources
const CUT_LINE_MIN_LENGTH : float = 50.0 #the min length the cut line must have to be used for cutting (otherwise it will be discarded and no cutting occurs)
const CUT_LINE_DIRECTION_THRESHOLD : float = -0.7 #smaller than treshold will end the cut line process and cut the sources (start_dir.dot(cur_dir) < threshold = endLine)
const CUT_LINE_POINT_MIN_DISTANCE : float = 40.0 #distance before new point is added (the smaller the more detailed is the visual line (not the cut line)


var _cut_line_enabled: bool = false
var _cut_line_t: float = 0.0
var _cut_line_points: PackedVector2Array = []
var _cut_line_last_end_point: Vector3 = Vector3.ZERO #z is used as bool -> 0 = not a valid point/ 1 = valid point

var _cut_line_start_direction: Vector2 = Vector2.ZERO
var _cut_line_total_length: float = 0.0



# Called when the node enters the scene tree for the first time.
func _ready():
    draw_polygon_rect()
    print(_cut_line)

func draw_polygon_rect() -> void:
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


func calculate_cut_line(cur_pos: Vector2, t: float) -> void:
    if _cut_line_points.size() <= 0: # starting the cut
        if _cut_line_last_end_point.z > 0.0:# last cut lines end point is new cut lines start point
            _cut_line_points.append(Vector2(_cut_line_last_end_point.x, _cut_line_last_end_point.y))
            _cut_line_last_end_point = Vector3.ZERO

        else: #there was no cut line before
            _cut_line_points.append(cur_pos)

    elif _cut_line_points.size() == 1 and not _cut_line.visible:
        var dis: float = (cur_pos - _cut_line_points[_cut_line_points.size() - 1]).length() # calc distance between current and last point
        if dis > CUT_LINE_MIN_LENGTH: # display line when distance passes threshold
            _cut_line.visible = true

    else:
        var last_pos: Vector2 = _cut_line_points[_cut_line_points.size() - 1]
        #var last_pos: Vector2 = lerp(_cut_line_points[_cut_line_points.size() - 1], cur_pos, t) # using this work better but I have no idea why.
        # print(last_pos, _cut_line_points[_cut_line_points.size() - 1])
        var vec: Vector2 = cur_pos - last_pos
        var dir: Vector2 = vec.normalized()

        if _cut_line_start_direction == Vector2.ZERO:
            _cut_line_start_direction = dir

        elif dir == Vector2.ZERO:
            end_cut_line()
            return

#        else: not sure why this is a good idea
#            if _cut_line_start_direction.dot(dir) < CUT_LINE_DIRECTION_THRESHOLD:
#                end_cut_line()
#                return

        var last_point : Vector2 = _cut_line_points[_cut_line_points.size() - 1]
        var dis: float = (cur_pos - last_point).length()
        if dis > CUT_LINE_POINT_MIN_DISTANCE:
            _cut_line_points.append(cur_pos)
            _cut_line.points = _cut_line_points # draws cut line
            _cut_line_t = 0.0
            _cut_line_total_length += dis

#        else: not sure why this was needed
#            print("Else")
#            _cut_line.points = _cut_line_points
#            _cut_line.add_point(cur_pos, -1)

func end_cut_line() -> void:
    pass


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == 1:
        if _cut_line_enabled and not event.pressed:
            _cut_line_enabled = false
        elif event.pressed:
            _cut_line_enabled = true


func _process(delta: float) -> void:
    if _cut_line_enabled:
        var cur_pos : Vector2 = get_global_mouse_position()
        if _cut_line_t < 1.0:
            _cut_line_t += delta * (1.0 / CUT_LINE_STATIONARY_DELAY)
        calculate_cut_line(cur_pos, _cut_line_t)
