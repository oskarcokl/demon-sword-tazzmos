extends Node2D

@onready var source_polygons = get_tree().get_root().get_node("Prototype/SourcePolygons")

@export var impl_scene: PackedScene


func _on_timer_timeout() -> void:
    var impl_instance = impl_scene.instantiate()
    impl_instance.global_position = global_position
    source_polygons.add_child(impl_instance)
