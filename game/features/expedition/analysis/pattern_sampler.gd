class_name PatternSampler
extends RefCounted
## Convierte un patrón en una señal muestreada (0-1) de `samples` puntos sobre el eje del analizador.
## Lo usan las vistas para dibujar difractogramas, cromatogramas, espectros gamma y curvas.


const BASELINE := 0.035
const COMPTON_HEIGHT := 0.42
const COMPTON_DECAY := 3.1
## Ancho por defecto de un pico sin ancho propio, como fracción del eje.
const DEFAULT_WIDTH := 0.004
const SIGMA_REACH := 5.0


static func sample(pattern: PatternSpec, analyzer: AnalyzerSpec, samples: int) -> PackedFloat32Array:
    if pattern.shape == PatternSpec.Shape.CURVE:
        return _curve(pattern, analyzer, samples)
    return _peaks(pattern, analyzer, samples)


static func _peaks(pattern: PatternSpec, analyzer: AnalyzerSpec, samples: int) -> PackedFloat32Array:
    var values: PackedFloat32Array = PackedFloat32Array()
    values.resize(samples)
    for i: int in samples:
        var base: float = BASELINE
        if analyzer.has_compton:
            base += COMPTON_HEIGHT * exp(-COMPTON_DECAY * float(i) / float(samples))
        values[i] = base
    var span: float = analyzer.span()
    for peak: Vector3 in pattern.bands:
        var width: float = peak.z if peak.z > 0.0 else span * DEFAULT_WIDTH
        var sigma: float = maxf(1.0, width / span * float(samples))
        var center: float = (peak.x - analyzer.axis_min) / span * float(samples)
        var low: int = int(maxf(0.0, center - SIGMA_REACH * sigma))
        var high: int = int(minf(float(samples), center + SIGMA_REACH * sigma))
        for i: int in range(low, high):
            values[i] += peak.y * exp(-0.5 * pow((float(i) - center) / sigma, 2.0))
    for i: int in samples:
        values[i] = minf(1.0, values[i])
    return values


static func _curve(pattern: PatternSpec, analyzer: AnalyzerSpec, samples: int) -> PackedFloat32Array:
    var values: PackedFloat32Array = PackedFloat32Array()
    values.resize(samples)
    var points: Array[Vector2] = pattern.points
    for i: int in samples:
        var x: float = analyzer.axis_min + analyzer.span() * float(i) / float(samples)
        var value: float = points[-1].y
        for k: int in points.size() - 1:
            var a: Vector2 = points[k]
            var b: Vector2 = points[k + 1]
            if a.x <= x and x <= b.x:
                var t: float = (x - a.x) / maxf(0.000001, b.x - a.x)
                value = lerpf(a.y, b.y, smoothstep(0.0, 1.0, t))
                break
        values[i] = clampf(value, 0.0, 1.0)
    return values


## Transmitancia de una banda de absorción en `nm` (1 = sin absorber).
static func transmittance(pattern: PatternSpec, nm: float) -> float:
    var result: float = 1.0
    for band: Vector3 in pattern.bands:
        result *= 1.0 - band.z * exp(-pow((nm - band.x) / (band.y * 0.7), 2.0))
    return result
