class_name FoundrySfx
extends Node
## Sonidos de la fundición, sintetizados al arrancar (`Synth`): teclear, error, caída a la tolva, objetivo
## al centro, recoger (más brillante cuanto más valioso), enfriarse, últimos segundos y final.
## Un rumor grave del horno en bucle mientras dura el nivel.


enum Sound { KEY, WRONG, DROP, SELECT, COLLECT, GOLD, LOST, TICK, END }

const VOICES := 8
const VOLUME_DB := -8.0
const FURNACE_DB := -22.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _furnace: AudioStreamPlayer
var _next_voice: int = 0


func _ready() -> void:
    for i: int in VOICES:
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        add_child(player)
        _players.append(player)
    _streams[Sound.KEY] = Synth.tone([1400.0], 0.03, 0.2, Synth.Wave.SQUARE)
    _streams[Sound.WRONG] = Synth.tone([200.0, 160.0], 0.18, 0.3, Synth.Wave.SQUARE)
    _streams[Sound.DROP] = Synth.boom(0.16, 140.0, 0.45)
    _streams[Sound.SELECT] = Synth.sweep(300.0, 620.0, 0.14, 0.25)
    _streams[Sound.COLLECT] = Synth.tone([659.0, 988.0], 0.18, 0.4, Synth.Wave.TRIANGLE)
    _streams[Sound.GOLD] = Synth.tone([784.0, 1175.0, 1568.0, 2093.0], 0.34, 0.4, Synth.Wave.SINE)
    _streams[Sound.LOST] = Synth.sweep(700.0, 140.0, 0.4, 0.25)
    _streams[Sound.TICK] = Synth.tone([1046.0], 0.05, 0.25, Synth.Wave.TRIANGLE)
    _streams[Sound.END] = Synth.boom(1.2, 70.0, 0.9)
    _furnace = AudioStreamPlayer.new()
    _furnace.stream = Synth.rumble(2.0, 0.7, true)
    _furnace.volume_db = FURNACE_DB
    add_child(_furnace)


func play(sound: Sound, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    var player: AudioStreamPlayer = _players[_next_voice]
    _next_voice = (_next_voice + 1) % VOICES
    player.stream = _streams[sound]
    player.volume_db = VOLUME_DB + volume_db
    player.pitch_scale = pitch
    player.play()


func set_furnace(is_on: bool) -> void:
    if is_on and not _furnace.playing:
        _furnace.play()
    elif not is_on:
        _furnace.stop()
