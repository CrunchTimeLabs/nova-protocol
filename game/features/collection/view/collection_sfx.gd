class_name CollectionSfx
extends Node
## Sonidos de la recolección, sintetizados al arrancar (`Synth`). Un motor en bucle mientras el cochecito
## se mueve y efectos sueltos por varias voces.


enum Sound { METAL, CRYSTAL, LOST, CRASH, RUMBLE, LESSON, CLICK, FINISH }

const VOICES := 8
const VOLUME_DB := -8.0
const ENGINE_DB := -20.0

var _streams: Dictionary = {}      # Sound -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _engine: AudioStreamPlayer
var _next_voice: int = 0


func _ready() -> void:
    for i: int in VOICES:
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        add_child(player)
        _players.append(player)
    _streams[Sound.METAL] = Synth.tone([523.0, 784.0], 0.16, 0.45, Synth.Wave.TRIANGLE)
    _streams[Sound.CRYSTAL] = Synth.tone([784.0, 988.0, 1319.0, 1568.0], 0.32, 0.4, Synth.Wave.SINE)
    _streams[Sound.LOST] = Synth.sweep(520.0, 220.0, 0.3, 0.25)
    _streams[Sound.CRASH] = Synth.boom(0.7, 55.0, 0.9)
    _streams[Sound.RUMBLE] = Synth.rumble(1.1, 0.8, false)
    _streams[Sound.LESSON] = Synth.tone([659.0, 880.0], 0.28, 0.35, Synth.Wave.SINE)
    _streams[Sound.CLICK] = Synth.tone([1200.0], 0.04, 0.25, Synth.Wave.SQUARE)
    _streams[Sound.FINISH] = Synth.tone([523.0, 659.0, 784.0, 1047.0], 0.7, 0.45, Synth.Wave.TRIANGLE)
    _engine = AudioStreamPlayer.new()
    _engine.stream = Synth.rumble(2.0, 0.6, true)
    _engine.volume_db = ENGINE_DB
    add_child(_engine)


func play(sound: Sound, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    var player: AudioStreamPlayer = _players[_next_voice]
    _next_voice = (_next_voice + 1) % VOICES
    player.stream = _streams[sound]
    player.volume_db = VOLUME_DB + volume_db
    player.pitch_scale = pitch
    player.play()


## Motor encendido mientras se mueve; el tono sube un poco con la marcha.
func set_engine(is_moving: bool) -> void:
    if is_moving and not _engine.playing:
        _engine.play()
    elif not is_moving and _engine.playing:
        _engine.stop()
