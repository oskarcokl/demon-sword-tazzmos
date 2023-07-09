extends Node2D

@onready var polygon: Polygon2D = $SourcePolygons/CutBody/Polygon2D
@onready var collision_polyong: CollisionPolygon2D = $SourcePolygons/CutBody/CollisionPolygon2D
@onready var _cut_line: Line2D = $CutLine
@onready var _source_polygon_parent: Node2D = $SourcePolygons
@onready var rigidbody_template: PackedScene = preload("res://scenes/imple.tscn")
@onready var game_over_screen: MarginContainer = $GameOverScreen


@export var cut_visualizer: PackedScene

const CUT_LINE_STATIONARY_DELAY : float = 0.2 #after that amount of seconds remaining stationary will end the cut line process and cut the sources
const CUT_LINE_MIN_LENGTH : float = 50.0 #the min length the cut line must have to be used for cutting (otherwise it will be discarded and no cutting occurs)
const CUT_LINE_DIRECTION_THRESHOLD : float = -0.7 #smaller than treshold will end the cut line process and cut the sources (start_dir.dot(cur_dir) < threshold = endLine)
const CUT_LINE_POINT_MIN_DISTANCE : float = 40.0 #distance before new point is added (the smaller the more detailed is the visual line (not the cut line)
const CUT_LINE_EPSILON : float = 10.0 # used in func simplifyLineRDP // how detailed the actual cut line is (opposed to CUT_LINE_POINT_MIN_DISTANCE which determines how detailed the visual cut line is)


var _cut_line_enabled: bool = false
var _cut_line_t: float = 0.0
var _cut_line_points: PackedVector2Array = []
var _cut_line_last_end_point: Vector3 = Vector3.ZERO #z is used as bool -> 0 = not a valid point/ 1 = valid point
var _input_disabled : bool = false
var _cut_line_start_direction: Vector2 = Vector2.ZERO
var _cut_line_total_length: float = 0.0
var _rng : RandomNumberGenerator



# Called when the node enters the scene tree for the first time.
func _ready():
    _rng = RandomNumberGenerator.new()


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
        #var last_pos: Vector2 = _cut_line_points[_cut_line_points.size() - 1]
        var last_pos: Vector2 = lerp(_cut_line_points[_cut_line_points.size() - 1], cur_pos, t) # using this work better but I have no idea why.
        # print(last_pos, _cut_line_points[_cut_line_points.size() - 1])
        var vec: Vector2 = cur_pos - last_pos
        var dir: Vector2 = vec.normalized()

        if _cut_line_start_direction == Vector2.ZERO:
            _cut_line_start_direction = dir

        elif dir == Vector2.ZERO:
            end_cut_line()
            return

        elif _cut_line_start_direction.dot(dir) < CUT_LINE_DIRECTION_THRESHOLD: #helps the line work better idk why.
            end_cut_line()
            return

        var last_point : Vector2 = _cut_line_points[_cut_line_points.size() - 1]
        var dis: float = (cur_pos - last_point).length()
        if dis > CUT_LINE_POINT_MIN_DISTANCE:
            _cut_line_points.append(cur_pos)
            _cut_line.points = _cut_line_points # draws cut line
            _cut_line_t = 0.0
            _cut_line_total_length += dis

        else:
            _cut_line.points = _cut_line_points
            _cut_line.add_point(cur_pos, -1)


func end_cut_line() -> void:
    if _cut_line_points.size() > 1 and _cut_line_total_length > CUT_LINE_MIN_LENGTH and not _input_disabled: # this if does the actual cutting
        var final_line: PackedVector2Array = PolygonLib.simplifyLineRDP(_cut_line_points, CUT_LINE_EPSILON)
        var final_shape: PackedVector2Array = []

        final_shape = PolygonLib.offsetPolyline(final_line, 2.0, true)[0]
        final_shape = PolygonLib.translatePolygon(final_shape, -_cut_line_points[0])
        cut_source_polygons(_cut_line_points[0], final_shape, 0.0, 0.0, 2.0)


    if _cut_line_points.size() > 1:
        var end_point : Vector2 = _cut_line_points[_cut_line_points.size() - 1]
        _cut_line_last_end_point = Vector3(end_point.x, end_point.y, 1.0)
    else:
        _cut_line_last_end_point = Vector3.ZERO

    _cut_line_total_length = 0.0
    _cut_line_points = []
    _cut_line.clear_points()
    _cut_line_start_direction = Vector2.ZERO
    _cut_line_t = 0.0

    _input_disabled = true
    set_deferred("_input_disabled", false)


func cut_source_polygons(cut_pos: Vector2, cut_shape: PackedVector2Array, cut_rot: float, cut_force: float = 0.0, fade_speed: float = 2.0) -> void:
    var instance = cut_visualizer.instantiate()
    instance.create_cut_visualizer(cut_pos, fade_speed)
    instance.set_polygon_custom(cut_shape)
    get_tree().get_root().add_child(instance)

    for source in _source_polygon_parent.get_children():
        var source_polygon : PackedVector2Array = source.get_polygon()
        var total_area : float = PolygonLib.getPolygonArea(source_polygon)

        var source_trans : Transform2D = source.get_global_transform()
        var cut_trans := Transform2D(cut_rot, cut_pos)

        var s_lin_vel := Vector2.ZERO
        var s_ang_vel : float = 0.0
        var s_mass : float = 0.0

        if source is RigidBody2D:
            s_lin_vel = source.linear_velocity
            s_ang_vel = source.angular_velocity
            s_mass = source.mass


        # var transformed_polygon = source_polygon * source_trans
        # var transformed_cut_shape = cut_shape * cut_trans
        var cut_fracture_info: Dictionary = cut_fracture(source_polygon, cut_shape, source_trans, cut_trans, 500, 3000, 250, 1)


        if cut_fracture_info.shapes.size() <= 0 and  cut_fracture_info.fractures.size() <= 0:
            continue

        var source_uv : PackedVector2Array = source.get_uv()

        for shape in cut_fracture_info.shapes:
            var area_p : float = shape.area / total_area
            var mass : float = s_mass * area_p
            var dir : Vector2 = (shape.spawn_pos - cut_pos).normalized()

            call_deferred("spawnRigibody2d", shape, source.modulate, s_lin_vel + dir * cut_force, s_ang_vel, mass, source.getTextureInfo(), source_uv)

        source.queue_free()


func cut_fracture(source_polygon: PackedVector2Array, cut_polygon: PackedVector2Array, source_trans_global: Transform2D, cut_trans_global: Transform2D, cut_min_area: float, fracture_min_area: float, shard_min_area: float, fractures: int = 3) -> Dictionary:
    var cut_info : Dictionary = PolygonLib.cutShape(source_polygon, cut_polygon, source_trans_global, cut_trans_global)

    var fracture_infos : Array = []
    # if cut_info.intersected and cut_info.intersected.size() > 0:
    #     for shape in cut_info.intersected:
    #         var area : float = PolygonLib.getPolygonArea(shape)
    #         print("Area:", area)
    #         if area < fracture_min_area:
    #             continue

    #         var fracture_info : Array = fractureDelaunay(shape, source_trans_global, fractures, shard_min_area)
    #         fracture_infos.append(fracture_info)

    var shape_infos : Array = []
    if cut_info.final and cut_info.final.size() > 0:
        for shape in cut_info.final:
            var triangulation : Dictionary = PolygonLib.triangulatePolygon(shape)
            var shape_area : float = triangulation.area#PolygonLib.getPolygonArea(shape)
            if shape_area < cut_min_area:
                var fracture_info : Array = fractureDelaunay(shape, source_trans_global, fractures, shard_min_area)
                fracture_infos.append(fracture_info)
                continue

            var shape_info : Dictionary = PolygonLib.getShapeInfoSimple(source_trans_global, shape, triangulation)
            shape_infos.append(shape_info)

    return {"shapes" : shape_infos, "fractures" : fracture_infos}


func fractureDelaunay(source_polygon : PackedVector2Array, source_global_trans : Transform2D, fracture_number : int, min_discard_area : float) -> Array:
#	source_polygon = PolygonLib.rotatePolygon(source_polygon, world_rot_rad)
    var points = getRandomPointsInPolygon(source_polygon, fracture_number)
    var triangulation : Dictionary = PolygonLib.triangulatePolygonDelaunay(points + source_polygon, true, true)

    var fracture_info : Array = []
    for triangle in triangulation.triangles:
        if triangle.area < min_discard_area:
            continue

        var results : Array = PolygonLib.intersectPolygons(triangle.points, source_polygon, true)
        for r in results:
            if r.size() > 0:
                if r.size() == 3:
                    var area : float = PolygonLib.getTriangleArea(r)
                    if area >= min_discard_area:
                        var centroid : Vector2 = PolygonLib.getTriangleCentroid(r)
#						var source_global_trans := Transform2D(world_rot_rad, world_pos)
                        var centered_shape = PolygonLib.translatePolygon(r, -centroid)
                        var spawn_pos : Vector2 = PolygonLib.getShapeSpawnPos(source_global_trans, centroid)
                        fracture_info.append(PolygonLib.makeShapeInfo(r, centered_shape, centroid, spawn_pos, triangle.area, source_global_trans))
                else:
                    var t : Dictionary = PolygonLib.triangulatePolygon(r, true, true)
                    if t.area >= min_discard_area:
                        var shape_info : Dictionary = PolygonLib.getShapeInfoSimple(source_global_trans, r, t)
                        fracture_info.append(shape_info)

    return fracture_info


func getRandomPointsInPolygon(poly : PackedVector2Array, number : int) -> PackedVector2Array:
    var triangulation : Dictionary = PolygonLib.triangulatePolygon(poly, true, false)

    var points : PackedVector2Array = []

    for i in range(number):
        var triangle : Array = getRandomTriangle(triangulation)
        if triangle.size() <= 0: continue
        var point : Vector2 = getRandomPointInTriangle(triangle)
        points.append(point)

    return points


#if a polygon is triangulated, that function can be used to get a random triangle from the triangultion
#each triangle is weighted based on its area
func getRandomTriangle(triangulation : Dictionary) -> PackedVector2Array:
    var chosen_weight : float = _rng.randf() * triangulation.area
    var current_weight : float = 0.0
    for triangle in triangulation.triangles:
        current_weight += triangle.area
        if current_weight > chosen_weight:
            return triangle.points

    var empty : PackedVector2Array = []
    return empty


func getRandomPointInTriangle(points : PackedVector2Array) -> Vector2:
    var rand_1 : float = _rng.randf()
    var rand_2 : float = _rng.randf()
    var sqrt_1 : float = sqrt(rand_1)

    return (1.0 - sqrt_1) * points[0] + sqrt_1 * (1.0 - rand_2) * points[1] + sqrt_1 * rand_2 * points[2]



func spawnRigibody2d(shape_info : Dictionary, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, texture_info : Dictionary, source_uv: PackedVector2Array) -> void:
    var instance = rigidbody_template.instantiate()
    _source_polygon_parent.add_child(instance)
    instance.global_position = shape_info.spawn_pos
    instance.global_rotation = shape_info.spawn_rot
    instance.set_polygon_custom(shape_info.centered_shape)
    # instance.set_uv(source_uv)
    instance.modulate = color
    instance.linear_velocity = lin_vel
    instance.angular_velocity = ang_vel
    instance.mass = mass
    instance.set_texture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))
    instance.dead()



func _input(event: InputEvent) -> void:
    if _input_disabled:
        return

    if event is InputEventMouseButton:
        if event.button_index == 1:
            if _cut_line_enabled and not event.pressed and _cut_line.visible:
                end_cut_line()
                _cut_line_enabled = false
                _cut_line.visible = false
                _cut_line_last_end_point = Vector3.ZERO
            elif event.pressed:
                _cut_line_enabled = true


func _process(delta: float) -> void:
    if _cut_line_enabled:
        var cur_pos : Vector2 = get_global_mouse_position()
        if _cut_line_t < 1.0:
            _cut_line_t += delta * (1.0 / CUT_LINE_STATIONARY_DELAY)
        calculate_cut_line(cur_pos, _cut_line_t)


func _on_health_bar_player_dead() -> void:
    game_over_screen.game_over()
    get_tree().paused = true


