extends Node2D


@export var hearts: int = 1
@export var margin: float = 10.0

@onready var empty_heart: Sprite2D = $EmptyHeart

var curr_hearts: int

signal player_dead


func _ready() -> void:
    curr_hearts = hearts
    var prev_heart = empty_heart
    for i in range(1, hearts):
        var empty_heart_instance: Sprite2D = empty_heart.duplicate()
        empty_heart_instance.position.x = prev_heart.position.x + margin + (prev_heart.texture.get_width() / 2)
        add_child(empty_heart_instance)
        prev_heart = empty_heart_instance


func take_dammage():
    get_child(curr_hearts - 1).get_child(0).visible = false
    curr_hearts -= 1

    if curr_hearts <= 0:
        print("Dead")
        emit_signal("player_dead")


func _on_player_body_entered(body: Node2D) -> void:
    take_dammage()
