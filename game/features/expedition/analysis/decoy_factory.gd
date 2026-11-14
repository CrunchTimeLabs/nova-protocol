class_name DecoyFactory
extends RefCounted
## Ventanas falsas hechas a partir del patrón verdadero: mismo número de picos, misma densidad,
## intensidades parecidas, pero corridos lo justo para que el color cambie. Así los seis candidatos
## se ven igual de densos y la única diferencia está en dónde cae cada pico.


## Margen a cada lado del eje que un pico corrido no puede cruzar.
const EDGE := 0.02


static func decoy(pattern: PatternSpec, analyzer: AnalyzerSpec, seed_value: int) -> PatternSpec:
    var rng: GameRandom = GameRandom.new(seed_value)
    var fake: PatternSpec = pattern.copy_as_decoy()
    match pattern.shape:
        PatternSpec.Shape.EMISSION:
            fake.points.clear()
            for line: Vector2 in pattern.points:
                var nm: float = _shift(line.x, 0.010, 0.030, analyzer, rng)
                fake.points.append(Vector2(nm, clampf(line.y * rng.range_float(0.85, 1.15), 0.18, 1.0)))
        PatternSpec.Shape.ABSORPTION:
            fake.bands.clear()
            for band: Vector3 in pattern.bands:
                var center: float = _shift(band.x, 0.035, 0.085, analyzer, rng)
                fake.bands.append(Vector3(center, band.y * rng.range_float(0.9, 1.1), band.z))
        PatternSpec.Shape.PEAKS:
            fake.bands.clear()
            for peak: Vector3 in pattern.bands:
                var center: float = _shift(peak.x, 0.012, 0.040, analyzer, rng)
                var height: float = clampf(peak.y * rng.range_float(0.85, 1.15), 0.15, 1.0)
                fake.bands.append(Vector3(center, height, peak.z * rng.range_float(0.9, 1.15)))
        PatternSpec.Shape.CURVE:
            var direction: float = 1.0 if rng.chance(0.5) else -1.0
            var lag: float = direction * rng.range_float(1.2, 3.0)
            var scale: float = rng.range_float(0.82, 1.18)
            var lift: float = rng.range_float(-0.07, 0.07)
            fake.points.clear()
            for point: Vector2 in pattern.points:
                fake.points.append(Vector2(
                        clampf(point.x + lag, analyzer.axis_min, analyzer.axis_max),
                        clampf(point.y * scale + lift, 0.0, 1.0),
                        ))
    return fake


## Corre `value` entre `low` y `high` (fracciones del eje) hacia un lado al azar, sin salirse del eje.
static func _shift(value: float, low: float, high: float, analyzer: AnalyzerSpec, rng: GameRandom) -> float:
    var span: float = analyzer.span()
    var direction: float = 1.0 if rng.chance(0.5) else -1.0
    var delta: float = rng.range_float(low, high) * span * direction
    return clampf(value + delta, analyzer.axis_min + span * EDGE, analyzer.axis_max - span * EDGE)
