extends BaseTest
## Capa 2: la orden es relativa al rumbo; como empuje extra, adelante acelera, atrás frena y la derecha cierra la órbita.

const ORBIT_RADIUS: float = 0.25
const ORBIT_GM: float = 0.01


var _manual: ManualThrustController
var _heading: HeadingThrustController


func before_each() -> void:
    _manual = ManualThrustController.new()
    _heading = HeadingThrustController.new(_manual)


func test_command_is_rotated_to_the_heading() -> void:
    var velocity: Vector2 = Vector2(0, 1)    # rumbo hacia abajo en pantalla
    var cases: Array = [
        [Vector2(0, -1), Vector2(0, 1)],     # adelante
        [Vector2(0, 1), Vector2(0, -1)],     # atrás
        [Vector2(1, 0), Vector2(-1, 0)],     # derecha del rumbo
        [Vector2(-1, 0), Vector2(1, 0)],     # izquierda del rumbo
    ]
    for case: Array in cases:
        _manual.set_command(case[0] as Vector2)
        var world: Vector2 = _heading.thrust_command(Vector2.ZERO, velocity, 0.1)
        check(world.distance_to(case[1] as Vector2) < 0.0001, "orden %s con rumbo %s da %s" % [str(case[0]), str(velocity), str(world)])


func test_without_heading_the_command_is_unchanged() -> void:
    _manual.set_command(Vector2(1, -1))
    check_equal(_heading.thrust_command(Vector2.ZERO, Vector2.ZERO, 0.1), Vector2(1, -1).limit_length(1.0), "quieto no hay rumbo")


func test_extra_thrust_adds_to_gravity_and_acts_as_described() -> void:
    var coast: Array = _radii_and_speed(Vector2.ZERO)
    # Al principio (0,2 s) la velocidad refleja el empuje; a los 2 s, atrás ya cae hacia dentro y gana velocidad con la gravedad.
    var speed_coast: float = _speed_after(Vector2.ZERO, 12)
    check(_speed_after(Vector2(0, -1), 12) > speed_coast, "adelante aumenta la velocidad")
    check(_speed_after(Vector2(0, 1), 12) < speed_coast, "atrás reduce la velocidad tangencial")
    check(float(_radii_and_speed(Vector2(1, 0))[0]) < float(coast[0]) - 0.01, "la derecha lleva hacia dentro de la órbita")
    check(float(_radii_and_speed(Vector2(-1, 0))[1]) > float(coast[1]) + 0.01, "la izquierda lleva hacia fuera")


## [radio mínimo, radio máximo, velocidad final] tras 2 s empujando con `command` en una órbita circular horaria bajo gravedad central.
func _radii_and_speed(command: Vector2) -> Array:
    _manual.set_command(command)
    var sources: Array[AccelerationSource] = [CentralGravity.new(Vector2.ZERO, ORBIT_GM, 0.0)]
    var body: DynamicBody = DynamicBody.new(
            _heading,
            ThrustEngine.new(0.05),
            sources,
            Vector2(ORBIT_RADIUS, 0),
            Vector2(0, sqrt(ORBIT_GM / ORBIT_RADIUS)),
            )
    var min_radius: float = ORBIT_RADIUS
    var max_radius: float = ORBIT_RADIUS
    for _i: int in range(120):
        body.step(1.0 / 60.0)
        min_radius = minf(min_radius, body.position.length())
        max_radius = maxf(max_radius, body.position.length())
    return [min_radius, max_radius, body.velocity.length()]


func _speed_after(command: Vector2, steps: int) -> float:
    _manual.set_command(command)
    var sources: Array[AccelerationSource] = [CentralGravity.new(Vector2.ZERO, ORBIT_GM, 0.0)]
    var body: DynamicBody = DynamicBody.new(
            _heading,
            ThrustEngine.new(0.05),
            sources,
            Vector2(ORBIT_RADIUS, 0),
            Vector2(0, sqrt(ORBIT_GM / ORBIT_RADIUS)),
            )
    for _i: int in range(steps):
        body.step(1.0 / 60.0)
    return body.velocity.length()
