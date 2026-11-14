class_name FlightHazards
extends RefCounted
## Las piezas que pueblan un tramo espacial. Solo estado y movimiento; `Flight` decide cuándo
## aparecen y qué daño hacen, y la vista las dibuja. Velocidades en píxeles por segundo.


## Borde por el que entra un frente de radiación.
enum Side { TOP, BOTTOM, LEFT, RIGHT }


class Rock:
    const VERTEX_COUNT := 9
    var position: Vector2
    var radius: float
    var speed: float
    var drift: float
    var spin: float = 0.0
    var spin_speed: float
    ## Contorno irregular relativo al centro, sin girar.
    var outline: PackedVector2Array = PackedVector2Array()

    func _init(p_position: Vector2, p_radius: float, p_speed: float, p_drift: float, rng: GameRandom) -> void:
        position = p_position
        radius = p_radius
        speed = p_speed
        drift = p_drift
        spin_speed = rng.range_float(-3.0, 3.0)
        for k: int in VERTEX_COUNT:
            var angle: float = float(k) * TAU / float(VERTEX_COUNT)
            outline.append(Vector2.from_angle(angle) * radius * rng.range_float(0.74, 1.05))

    func hits(center: Vector2, other_radius: float) -> bool:
        return position.distance_squared_to(center) < pow(radius + other_radius, 2.0)


class Orb:
    var position: Vector2
    var res: Catalog.Res
    var quantity: int
    var speed: float

    func _init(p_position: Vector2, p_res: Catalog.Res, p_quantity: int, p_speed: float) -> void:
        position = p_position
        res = p_res
        quantity = p_quantity
        speed = p_speed


## Frente de choque circular que se expande más rápido que la velocidad de crucero.
class Wave:
    const START_RADIUS := 10.0
    const HIT_MARGIN := 14.0
    const MAX_RADIUS := 1700.0
    var center: Vector2
    var radius: float = START_RADIUS
    var speed: float
    var has_hit: bool = false

    func _init(p_center: Vector2, p_speed: float) -> void:
        center = p_center
        speed = p_speed

    func reaches(point: Vector2, other_radius: float) -> bool:
        return absf(point.distance_to(center) - radius) < other_radius + HIT_MARGIN


## Cañón de largo alcance: marca una franja, carga y dispara.
class Laser:
    const CHARGE := 1.7
    const FIRE := 0.55
    const WIDTH := 46.0
    var horizontal: bool
    ## Y de la franja si es horizontal, X si es vertical.
    var line: float
    var elapsed: float = 0.0

    func _init(p_horizontal: bool, p_line: float) -> void:
        horizontal = p_horizontal
        line = p_line

    func is_firing() -> bool:
        return elapsed >= CHARGE

    func is_over() -> bool:
        return elapsed >= CHARGE + FIRE

    func charge_ratio() -> float:
        return clampf(elapsed / CHARGE, 0.0, 1.0)

    func rect(field: Vector2) -> Rect2:
        if horizontal:
            return Rect2(0.0, line - WIDTH / 2.0, field.x, WIDTH)
        return Rect2(line - WIDTH / 2.0, 0.0, WIDTH, field.y)


## Frente de radiación solar: una banda que entra por un borde y barre la pantalla.
class Front:
    var side: FlightHazards.Side
    var thickness: float
    var speed: float
    var offset: float

    func _init(p_side: FlightHazards.Side, p_thickness: float, p_speed: float, field: Vector2) -> void:
        side = p_side
        thickness = p_thickness
        speed = p_speed
        match side:
            FlightHazards.Side.TOP, FlightHazards.Side.LEFT:
                offset = -thickness
            FlightHazards.Side.BOTTOM:
                offset = field.y
            FlightHazards.Side.RIGHT:
                offset = field.x

    func advance(delta: float) -> void:
        match side:
            FlightHazards.Side.TOP, FlightHazards.Side.LEFT:
                offset += speed * delta
            FlightHazards.Side.BOTTOM, FlightHazards.Side.RIGHT:
                offset -= speed * delta

    func is_gone(field: Vector2) -> bool:
        match side:
            FlightHazards.Side.TOP:
                return offset >= field.y
            FlightHazards.Side.LEFT:
                return offset >= field.x
            FlightHazards.Side.BOTTOM, FlightHazards.Side.RIGHT:
                return offset <= -thickness
        return true

    func is_horizontal() -> bool:
        return side == FlightHazards.Side.TOP or side == FlightHazards.Side.BOTTOM

    func rect(field: Vector2) -> Rect2:
        if is_horizontal():
            return Rect2(0.0, offset, field.x, thickness)
        return Rect2(offset, 0.0, thickness, field.y)
