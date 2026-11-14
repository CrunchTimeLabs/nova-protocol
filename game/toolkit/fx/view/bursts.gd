class_name Bursts
extends RefCounted
## Sin efectos: devuelve partículas invisibles para que quien las pide no cambie.


## Estallido que se borra solo al terminar.
static func burst(
        parent: Node,
        where: Vector2,
        color: Color,
        amount: int = 24,
        speed: float = 180.0,
        lifetime: float = 0.6,
        size: float = 3.0,
        ) -> CPUParticles2D:
    var particles: CPUParticles2D = CPUParticles2D.new()
    particles.position = where
    particles.amount = amount
    particles.lifetime = lifetime
    particles.one_shot = true
    particles.explosiveness = 0.95
    particles.direction = Vector2.RIGHT
    particles.spread = 180.0
    particles.gravity = Vector2.ZERO
    particles.initial_velocity_min = speed * 0.35
    particles.initial_velocity_max = speed
    particles.damping_min = speed * 0.6
    particles.damping_max = speed * 1.2
    particles.scale_amount_min = size * 0.5
    particles.scale_amount_max = size
    particles.color_ramp = fade(color)
    particles.queue_free()
    return particles


## Emisor continuo hacia `direction`: llama del motor, estela de la nave o polvo de las ruedas.
static func stream(color: Color, direction: Vector2, amount: int, speed: float, lifetime: float, size: float, spread: float) -> CPUParticles2D:
    var particles: CPUParticles2D = CPUParticles2D.new()
    particles.amount = amount
    particles.lifetime = lifetime
    particles.direction = direction
    particles.spread = spread
    particles.gravity = Vector2.ZERO
    particles.initial_velocity_min = speed * 0.6
    particles.initial_velocity_max = speed
    particles.scale_amount_min = size * 0.5
    particles.scale_amount_max = size
    particles.color_ramp = fade(color)
    particles.emitting = false
    particles.visible = false
    return particles


static func fade(color: Color) -> Gradient:
    var ramp: Gradient = Gradient.new()
    ramp.set_color(0, color)
    ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
    return ramp
