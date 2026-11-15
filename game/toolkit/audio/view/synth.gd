class_name Synth
extends RefCounted
## Sonidos sintetizados en PCM de 16 bits, sin archivos de audio. Genérico: cada juego elige notas y formas.
## El ruido usa un generador con semilla propia (es solo sonido, no afecta a ninguna regla).


const RATE := 22050

static var _noise: RandomNumberGenerator


enum Wave { SINE, SQUARE, TRIANGLE }


## Notas seguidas (arpegio), cada una con su envolvente corta.
static func tone(notes: Array[float], seconds: float, volume: float, wave: Wave) -> AudioStreamWAV:
    var total: int = int(seconds * RATE)
    var per_note: int = maxi(1, total / notes.size())
    var samples: PackedFloat32Array = PackedFloat32Array()
    samples.resize(total)
    var phase: float = 0.0
    for i: int in total:
        var note: int = mini(i / per_note, notes.size() - 1)
        var local: float = float(i - note * per_note) / float(per_note)
        phase += notes[note] / RATE
        var envelope: float = minf(1.0, local * 40.0) * pow(1.0 - local, 1.5)
        samples[i] = _wave(wave, phase) * envelope * volume
    return wav(samples, false)


## Tono que se desliza de una frecuencia a otra.
static func sweep(from_hz: float, to_hz: float, seconds: float, volume: float) -> AudioStreamWAV:
    var total: int = int(seconds * RATE)
    var samples: PackedFloat32Array = PackedFloat32Array()
    samples.resize(total)
    var phase: float = 0.0
    for i: int in total:
        var t: float = float(i) / float(total)
        phase += lerpf(from_hz, to_hz, t) / RATE
        var envelope: float = minf(1.0, t * 20.0) * pow(1.0 - t, 1.3)
        samples[i] = _wave(Wave.SINE, phase) * envelope * volume
    return wav(samples, false)


## Golpe: ruido filtrado y un tono grave que cae (rocas, impactos).
static func boom(seconds: float, low_hz: float, volume: float) -> AudioStreamWAV:
    var total: int = int(seconds * RATE)
    var samples: PackedFloat32Array = PackedFloat32Array()
    samples.resize(total)
    var phase: float = 0.0
    var filtered: float = 0.0
    for i: int in total:
        var t: float = float(i) / float(total)
        filtered = lerpf(filtered, noise().randf_range(-1.0, 1.0), 0.18)
        phase += low_hz * (1.0 - 0.6 * t) / RATE
        samples[i] = (filtered * 1.6 + _wave(Wave.SINE, phase) * 0.7) * pow(1.0 - t, 2.2) * volume
    return wav(samples, false)


## Retumbo de ruido grave que sube y baja (temblor, derrumbe lejano).
static func rumble(seconds: float, volume: float, looped: bool) -> AudioStreamWAV:
    var total: int = int(seconds * RATE)
    var samples: PackedFloat32Array = PackedFloat32Array()
    samples.resize(total)
    var brown: float = 0.0
    for i: int in total:
        var t: float = float(i) / float(total)
        brown = clampf(brown + noise().randf_range(-0.08, 0.08), -1.0, 1.0) * 0.995
        var envelope: float = 1.0 if looped else sin(t * PI)
        samples[i] = brown * envelope * volume
    return wav(samples, looped)


static func wav(samples: PackedFloat32Array, looped: bool) -> AudioStreamWAV:
    var data: PackedByteArray = PackedByteArray()
    data.resize(samples.size() * 2)
    for i: int in samples.size():
        data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = data
    if looped:
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_begin = 0
        stream.loop_end = samples.size()
    return stream


static func noise() -> RandomNumberGenerator:
    if _noise == null:
        _noise = RandomNumberGenerator.new()
        _noise.seed = 1234
    return _noise


static func _wave(wave: Wave, phase: float) -> float:
    match wave:
        Wave.SQUARE:
            return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
        Wave.TRIANGLE:
            return 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0
    return sin(phase * TAU)
