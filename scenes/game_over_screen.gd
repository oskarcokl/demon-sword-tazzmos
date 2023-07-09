extends MarginContainer


@onready var music: AudioStreamPlayer = $AudioStreamPlayer


func _on_restart_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/prototype.tscn")
    get_tree().paused = false
    visible = false



func _on_quit_pressed() -> void:
    print("Quit")
    get_tree().quit()


func game_over() -> void:
    music.play()
    visible = true
