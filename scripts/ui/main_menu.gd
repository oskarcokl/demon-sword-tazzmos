extends Control


func _on_play_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/prototype.tscn")



func _on_controls_pressed() -> void:
    pass # Replace with function body.


func _on_lore_pressed() -> void:
    pass # Replace with function body.


func _on_quit_pressed() -> void:
    get_tree().quit()
