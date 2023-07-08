class_name RDP


static func calculate(startIndex : int, endIndex : int, line : Array, final_line : Array, epsilon : float) -> void:
    var nextIndex : int = findFurthest(line, startIndex, endIndex, epsilon)
    if nextIndex > 0:
        if startIndex != nextIndex:
            calculate(startIndex, nextIndex, line, final_line, epsilon)

        final_line.append(line[nextIndex])

        if (endIndex != nextIndex):
            calculate(nextIndex, endIndex, line, final_line, epsilon)


static func findFurthest(points : Array, a : int, b : int, epsilon : float) -> int:
    var recordDistance : float = -1.0
    var start : Vector2 = points[a]
    var end : Vector2 = points[b]
    var furthestIndex : int = -1
    for i in range(a+1,b):
        var currentPoint : Vector2 = points[i]
        var d : float = lineDist(currentPoint, start, end);
        if d > recordDistance:
            recordDistance = d;
            furthestIndex = i;

    if recordDistance > epsilon:
        return furthestIndex

    else:
        return -1


static func lineDist(point : Vector2, line_start : Vector2, line_end : Vector2) -> float:
    var norm = scalarProjection(point, line_start, line_end)
    return (point - norm).length()


static func scalarProjection(p : Vector2, a : Vector2, b : Vector2) -> Vector2:
    var ap : Vector2 = p - a
    var ab : Vector2 = b - a
    ab = ab.normalized()
    ab *= ap.dot(ab)
    return a + ab
