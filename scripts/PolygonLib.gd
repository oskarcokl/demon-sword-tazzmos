class_name PolygonLib


static func simplifyLineRDP(line : PackedVector2Array, epsilon : float = 10.0) -> PackedVector2Array:
    var total : int = line.size()
    var start : Vector2 = line[0]
    var end : Vector2 = line[total - 1]

    var rdp_points : Array = [start]
    RDP.calculate(0, total - 1, Array(line), rdp_points, epsilon)
    rdp_points.append(end)

    return PackedVector2Array(rdp_points)


#moves all points of the polygon by offset
static func translatePolygon(poly : PackedVector2Array, offset : Vector2) -> PackedVector2Array:
    var new_poly : PackedVector2Array = []
    for p in poly:
        new_poly.append(p + offset)
    return new_poly


static func getTriangleArea(points : PackedVector2Array) -> float:
    var a : float = (points[1] - points[2]).length()
    var b : float = (points[2] - points[0]).length()
    var c : float = (points[0] - points[1]).length()
    var s : float = (a + b + c) * 0.5

    var value : float = s * (s - a) * (s - b) * (s - c)
    if value < 0.0:
        return 1.0
    var area : float = sqrt(value)
    return area


static func getPolygonArea(poly: PackedVector2Array) -> float:
    var total_area : float = 0.0
    var triangle_points = Geometry2D.triangulate_polygon(poly)
    for i in range(triangle_points.size() / 3):
        var index : int = i * 3
        var points : Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
        total_area += getTriangleArea(points)
    return total_area


static func triangulatePolygon(poly : PackedVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
    var triangle_points : PackedInt32Array = Geometry2D.triangulate_polygon(poly)
    return makeTriangles(poly, triangle_points, with_area, with_centroid)


#returns a dictionary for triangles
static func makeTriangle(points : PackedVector2Array, area : float, centroid : Vector2) -> Dictionary:
    return {"points" : points, "area" : area, "centroid" : centroid}


#makes a shape info with the given parameters and has different parameters than getShapeInfo
static func getShapeInfoSimple(source_global_trans : Transform2D, source_polygon : PackedVector2Array, triangulation : Dictionary) -> Dictionary:
    var centroid : Vector2 = getPolygonCentroid(triangulation.triangles, triangulation.area)
    var centered_shape : PackedVector2Array = translatePolygon(source_polygon, -centroid)
    return makeShapeInfo(source_polygon, centered_shape, centroid, getShapeSpawnPos(source_global_trans, centroid), triangulation.area, source_global_trans)


#triangulates a polygon and sums the weighted centroids of all triangles
static func getPolygonCentroid(triangles : Array, total_area : float) -> Vector2:
    var weighted_centroid := Vector2.ZERO
    for triangle in triangles:
        weighted_centroid += (triangle.centroid * triangle.area)
    return weighted_centroid / total_area


static func makeTriangles(poly : PackedVector2Array, triangle_points : PackedInt32Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
    var triangles : Array = []
    var total_area : float = 0.0
    for i in range(int(triangle_points.size() / 3.0)):
        var index : int = i * 3
        var points : PackedVector2Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]

        var area : float = 0.0
        if with_area:
            area = getTriangleArea(points)

        var centroid := Vector2.ZERO
        if with_centroid:
            centroid = getTriangleCentroid(points)

        total_area += area

        triangles.append(makeTriangle(points, area, centroid))
    return {"triangles" : triangles, "area" : total_area}


static func triangulatePolygonDelaunay(poly : PackedVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
    var triangle_points = Geometry2D.triangulate_delaunay(poly)
    return makeTriangles(poly, triangle_points, with_area, with_centroid)


#calculates the global world position for a given centroid
static func getShapeSpawnPos(source_global_trans : Transform2D, centroid : Vector2) -> Vector2:
    var spawn_pos : Vector2 = toGlobal(source_global_trans, centroid)
    return spawn_pos


static func makeShapeInfo(shape : PackedVector2Array, centered_shape : PackedVector2Array, centroid : Vector2, spawn_pos : Vector2, area : float, source_global_trans : Transform2D) -> Dictionary:
    return {"shape" : shape, "centered_shape" : centered_shape, "centroid" : centroid, "spawn_pos" : spawn_pos, "spawn_rot" : source_global_trans.get_rotation(), "area" : area, "source_global_trans" : source_global_trans}


static func getTriangleCentroid(points : PackedVector2Array) -> Vector2:
    var ab : Vector2 = points[1] - points[0]
    var ac : Vector2 = points[2] - points[0]
    var centroid : Vector2 = points[0] + (ab + ac) / 3.0
    return centroid


static func cutShape(source_polygon : PackedVector2Array, cut_polygon : PackedVector2Array, source_trans_global : Transform2D, cut_trans_global : Transform2D) -> Dictionary:
    var cut_pos : Vector2 = toLocal(source_trans_global, cut_trans_global.get_origin())

    cut_polygon = rotatePolygon(cut_polygon, cut_trans_global.get_rotation() - source_trans_global.get_rotation())
    cut_polygon = translatePolygon(cut_polygon, cut_pos)

    var intersected_polygons : Array = intersectPolygons(source_polygon, cut_polygon, true)
    if intersected_polygons.size() <= 0:
        return {"final" : [], "intersected" : []}

    var final_polygons : Array = clipPolygons(source_polygon, cut_polygon, true)

    return {"final" : final_polygons, "intersected" : intersected_polygons}


static func clipPolygons(poly_a : PackedVector2Array, poly_b : PackedVector2Array, exclude_holes : bool = true) -> Array:
    var new_polygons : Array = Geometry2D.clip_polygons(poly_a, poly_b)
    if exclude_holes:
        return getCounterClockwisePolygons(new_polygons)
    else:
        return new_polygons


#does the same as Node.toLocal()
static func toLocal(global_transform : Transform2D, global_pos : Vector2) -> Vector2:
    return global_transform.affine_inverse() * global_pos


static func toGlobal(global_transform : Transform2D, local_pos : Vector2) -> Vector2:
    return global_transform * local_pos


#rotates all points of the polygon by rot (in radians)
static func rotatePolygon(poly : PackedVector2Array, rot : float) -> PackedVector2Array:
    var rotated_polygon : PackedVector2Array = []

    for p in poly:
        rotated_polygon.append(p.rotated(rot))

    return rotated_polygon


static func intersectPolygons(poly_a : PackedVector2Array, poly_b : PackedVector2Array, exclude_holes : bool = true) -> Array:
    var new_polygons : Array = Geometry2D.intersect_polygons(poly_a, poly_b)
    if exclude_holes:
        return getCounterClockwisePolygons(new_polygons)
    else:
        return new_polygons


static func offsetPolyline(line : PackedVector2Array, delta : float, exclude_holes : bool = true) -> Array:
    var new_polygons : Array = Geometry2D.offset_polyline(line, delta)
    if exclude_holes:
        return getCounterClockwisePolygons(new_polygons)
    else:
        return new_polygons


#checks all polygons in the array and only returns not clockwise (counter clockwise) polygons (filled polygons)
static func getCounterClockwisePolygons(polygons : Array) -> Array:
    var ccw_polygons : Array = []
    for poly in polygons:
        if not Geometry2D.is_polygon_clockwise(poly):
            ccw_polygons.append(poly)
    return ccw_polygons
