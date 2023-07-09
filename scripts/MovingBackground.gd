extends Node2D


@export var tree: PackedScene
@export var bush: PackedScene
@export var mushroom: PackedScene
@export var grass: PackedScene
@export var small_tree: PackedScene


var rng = RandomNumberGenerator.new()

func _on_timer_timeout() -> void:
    var random_number = rng.randf()
    var foliage_instance: Sprite2D
    if random_number >= 0.0 and random_number <= 0.3:
        foliage_instance = tree.instantiate()
    elif random_number > 0.3 and random_number <= 0.6:
        foliage_instance = small_tree.instantiate()
    elif random_number > 0.6 and random_number <= 0.75:
        foliage_instance = mushroom.instantiate()
    elif random_number > 0.75 and random_number <= 0.9:
        foliage_instance = grass.instantiate()
    elif random_number > 0.9 and random_number <= 1.0:
        foliage_instance = bush.instantiate()


    foliage_instance.visible = true
    add_child(foliage_instance)
