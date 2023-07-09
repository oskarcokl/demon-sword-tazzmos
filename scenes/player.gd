extends Area2D

@onready var swing_sound: AudioStreamPlayer = $Swing
@onready var hurt_sound: AudioStreamPlayer = $Hurt

func swing() -> void:
    swing_sound.play()


func _on_body_entered(body: Node2D) -> void:
    hurt_sound.play()
