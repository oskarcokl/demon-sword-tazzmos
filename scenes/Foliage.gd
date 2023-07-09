extends Sprite2D

var move_speed = 10.0

func _ready() -> void:
    # visible = true
    move_speed = randf_range(8.0, 11.0)

func _process(_delta: float) -> void:
    global_position += Vector2.LEFT * move_speed


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()

