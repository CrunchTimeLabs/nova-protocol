class_name Sfx
extends Node
## Sin sonido: conserva la interfaz para que las pantallas no cambien.


enum Sound {
    CLICK,
    PICKUP,
    VEIN,
    PERFECT,
    HIT,
    EXPLOSION,
    LASER_CHARGE,
    LASER_FIRE,
    WAVE,
    ALARM,
    SUCCESS,
    FAILURE,
    BEEP,
    GO,
    LOAD,
    UNLOAD,
    DENIED,
    SCAN,
}
enum Loop { ENGINE, PHASE }


func play(_sound: Sound, _pitch: float = 1.0, _volume_db: float = 0.0) -> void:
    pass


func set_loop(_loop: Loop, _on: bool, _volume_db: float = 0.0) -> void:
    pass


func stop_loops() -> void:
    pass
