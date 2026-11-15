class_name RockRain
extends Control
## Lluvia de rocas grandes por toda la pantalla cuando hay un derrumbe. Solo adorno: no toca el juego,
## no recibe ratón y se dibuja encima de todo. `intensity()` dice cuánto debe temblar la pantalla.


class BigRock:
    var position: Vector2
    var speed: float
    var radius: float
    var spin: float
    var spin_speed: float
    var delay: float
    var shape_seed: int


const RADIUS := Vector2(70.0, 140.0)
const SPEED := Vector2(650.0, 950.0)
## Las rocas no salen todas a la vez: se reparten en este tiempo.
const SPREAD_TIME := 0.9
const ALPHA := 0.6
const GHOSTS := 3
const GHOST_STEP := 0.025
const SIDE_DRIFT := 60.0

var _rocks: Array[BigRock] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
    _rng.seed = 2024


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


## Lanza `count` rocas grandes desde arriba, repartidas a lo ancho de la pantalla.
func pour(count: int) -> void:
    for i: int in count:
        var rock: BigRock = BigRock.new()
        rock.radius = _rng.randf_range(RADIUS.x, RADIUS.y)
        var lane: float = (float(i) + _rng.randf_range(0.1, 0.9)) / float(count)
        rock.position = Vector2(lane * size.x, -rock.radius - _rng.randf_range(0.0, 80.0))
        rock.speed = _rng.randf_range(SPEED.x, SPEED.y)
        rock.spin = _rng.randf() * TAU
        rock.spin_speed = _rng.randf_range(-3.0, 3.0)
        rock.delay = _rng.randf_range(0.0, SPREAD_TIME)
        rock.shape_seed = _rng.randi_range(1, 9999)
        _rocks.append(rock)


## 0..1: cuántas rocas grandes cruzan ahora la pantalla (para el temblor).
func intensity() -> float:
    var crossing: int = 0
    for rock: BigRock in _rocks:
        if rock.delay <= 0.0 and rock.position.y > 0.0 and rock.position.y < size.y:
            crossing += 1
    return minf(1.0, float(crossing) / 3.0)


func _process(delta: float) -> void:
    for rock: BigRock in _rocks.duplicate():
        if rock.delay > 0.0:
            rock.delay -= delta
            continue
        rock.position.y += rock.speed * delta
        rock.position.x += sin(rock.spin) * SIDE_DRIFT * delta
        rock.spin += rock.spin_speed * delta
        if rock.position.y - rock.radius > size.y:
            _rocks.erase(rock)
    queue_redraw()


func _draw() -> void:
    for rock: BigRock in _rocks:
        if rock.delay > 0.0:
            continue
        # Estela: copias más tenues por detrás, como una roca que cae muy rápido.
        for ghost: int in range(GHOSTS, 0, -1):
            var back: Vector2 = rock.position - Vector2(0, rock.speed * GHOST_STEP * float(ghost))
            RocksDraw.rock(self, back, rock.radius, rock.spin, rock.shape_seed, ALPHA * 0.18 / float(ghost))
        RocksDraw.rock(self, rock.position, rock.radius, rock.spin, rock.shape_seed, ALPHA)
