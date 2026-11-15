class_name CollectionFx
extends RefCounted
## Partículas dibujadas a mano (polvo, chispas, escombros): solo adorno, no tocan el estado del juego.


class Particle:
    var position: Vector2
    var velocity: Vector2
    var color: Color
    var size: float
    var life: float
    var age: float = 0.0
    var gravity: float

    func _init(p_position: Vector2, p_velocity: Vector2, p_color: Color, p_size: float, p_life: float, p_gravity: float) -> void:
        position = p_position
        velocity = p_velocity
        color = p_color
        size = p_size
        life = p_life
        gravity = p_gravity


const DRAG := 3.0
const MAX_PARTICLES := 400

var _particles: Array[Particle] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
    _rng.seed = 77


## Estallido radial (chispas al recoger, polvo al caer rocas).
func burst(
        where: Vector2,
        color: Color,
        amount: int,
        speed: float,
        life: float,
        size: float,
        gravity: float = 0.0,
        ) -> void:
    for i: int in amount:
        var velocity: Vector2 = Vector2.from_angle(_rng.randf() * TAU) * speed * _rng.randf_range(0.3, 1.0)
        _add(Particle.new(where, velocity, color, size * _rng.randf_range(0.5, 1.0), life * _rng.randf_range(0.6, 1.0), gravity))


## Un poco de polvo detrás de las ruedas.
func trail(where: Vector2, backwards: Vector2, color: Color) -> void:
    var velocity: Vector2 = backwards * 40.0 + Vector2(_rng.randf_range(-15.0, 15.0), _rng.randf_range(-15.0, 15.0))
    _add(Particle.new(where, velocity, color, _rng.randf_range(2.0, 4.0), 0.5, 0.0))


func update(delta: float) -> void:
    for particle: Particle in _particles.duplicate():
        particle.age += delta
        if particle.age >= particle.life:
            _particles.erase(particle)
            continue
        particle.velocity *= maxf(0.0, 1.0 - DRAG * delta)
        particle.velocity.y += particle.gravity * delta
        particle.position += particle.velocity * delta


func draw(canvas: CanvasItem) -> void:
    for particle: Particle in _particles:
        var fade: float = 1.0 - particle.age / particle.life
        canvas.draw_circle(particle.position, particle.size * (0.5 + 0.5 * fade), Color(particle.color, particle.color.a * fade))


func _add(particle: Particle) -> void:
    if _particles.size() >= MAX_PARTICLES:
        _particles.pop_front()
    _particles.append(particle)
