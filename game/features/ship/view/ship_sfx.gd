class_name ShipSfx
extends Node
## Sonidos del hangar, sintetizados al arrancar (`Synth`): coger, encajar, quitar, aviso, cuenta atrás,
## motor de despegue en bucle y llegada a órbita.


enum Sound { PICK, SNAP, REMOVE, DENIED, READY, BEEP, IGNITION, ORBIT }

const VOICES := 6
const VOLUME_DB := -8.0
const ENGINE_DB := -6.0

var _streams: Dictionary = {}      # Sound -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _engine: AudioStreamPlayer
var _next_voice: int = 0


func _ready() -> void:
    for i: int in VOICES:
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        add_child(player)
        _players.append(player)
    _streams[Sound.PICK] = Synth.tone([660.0], 0.06, 0.3, Synth.Wave.TRIANGLE)
    _streams[Sound.SNAP] = Synth.boom(0.18, 180.0, 0.6)
    _streams[Sound.REMOVE] = Synth.sweep(500.0, 260.0, 0.15, 0.3)
    _streams[Sound.DENIED] = Synth.tone([180.0, 150.0], 0.2, 0.3, Synth.Wave.SQUARE)
    _streams[Sound.READY] = Synth.tone([523.0, 659.0, 784.0, 1047.0], 0.5, 0.4, Synth.Wave.TRIANGLE)
    _streams[Sound.BEEP] = Synth.tone([880.0], 0.15, 0.35, Synth.Wave.SQUARE)
    _streams[Sound.IGNITION] = Synth.boom(1.2, 45.0, 1.0)
    _streams[Sound.ORBIT] = Synth.tone([784.0, 988.0, 1175.0, 1568.0], 0.8, 0.4, Synth.Wave.SINE)
    _engine = AudioStreamPlayer.new()
    _engine.stream = Synth.rumble(2.0, 0.9, true)
    _engine.volume_db = ENGINE_DB
    add_child(_engine)


func play(sound: Sound, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    var player: AudioStreamPlayer = _players[_next_voice]
    _next_voice = (_next_voice + 1) % VOICES
    player.stream = _streams[sound]
    player.volume_db = VOLUME_DB + volume_db
    player.pitch_scale = pitch
    player.play()


## Rugido del motor mientras sube; `volume` 0..1 para apagarlo poco a poco.
func set_engine(volume: float) -> void:
    if volume <= 0.01:
        _engine.stop()
        return
    _engine.volume_db = ENGINE_DB + linear_to_db(volume)
    if not _engine.playing:
        _engine.play()
