extends Area2D

@onready var swing_sound: AudioStreamPlayer = $Swing

func swing() -> void:
    swing_sound.play()
