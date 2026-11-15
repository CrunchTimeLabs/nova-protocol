class_name LaunchSmoke
extends RefCounted
## Humo del despegue y chispas al encajar piezas, en bloques cuadrados (estilo píxel). Solo adorno.


class Puff:
    var position: Vector2
    var velocity: Vector2
    var size: float
    var growth: float
    var life: float
    var age: float = 0.0
    var color: Color


const PIXEL := 4.0
const MAX_PUFFS := 500

var _puffs: Array[Puff] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
    _rng.seed = 404


## Nube que sale hacia los lados desde la base del cohete.
func billow(where: Vector2, amount: int, strength: float) -> void:
    for i: int in amount:
        var puff: Puff = Puff.new()
        var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
        puff.position = where + Vector2(_rng.randf_range(-20.0, 20.0), _rng.randf_range(-6.0, 6.0))
        puff.velocity = Vector2(side * _rng.randf_range(60.0, 260.0) * strength, _rng.randf_range(-50.0, -5.0))
        puff.size = _rng.randf_range(10.0, 22.0)
        puff.growth = _rng.randf_range(14.0, 30.0)
        puff.life = _rng.randf_range(1.4, 2.6)
        var grey: float = _rng.randf_range(0.6, 0.85)
        puff.color = Color(grey, grey, grey * 1.04, 0.85)
        _add(puff)


## Chispas al encajar una pieza.
func sparks(where: Vector2, color: Color) -> void:
    for i: int in 14:
        var puff: Puff = Puff.new()
        puff.position = where
        puff.velocity = Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(60.0, 200.0)
        puff.size = PIXEL
        puff.growth = -2.0
        puff.life = _rng.randf_range(0.3, 0.6)
        puff.color = color
        _add(puff)


func update(delta: float) -> void:
    for puff: Puff in _puffs.duplicate():
        puff.age += delta
        if puff.age >= puff.life:
            _puffs.erase(puff)
            continue
        puff.velocity *= maxf(0.0, 1.0 - 1.6 * delta)
        puff.position += puff.velocity * delta
        puff.size = maxf(PIXEL, puff.size + puff.growth * delta)


func draw(canvas: CanvasItem) -> void:
    for puff: Puff in _puffs:
        var fade: float = 1.0 - puff.age / puff.life
        var size: float = snappedf(puff.size, PIXEL)
        var corner: Vector2 = (puff.position - Vector2(size, size) / 2.0).snapped(Vector2(PIXEL, PIXEL))
        canvas.draw_rect(Rect2(corner, Vector2(size, size)), Color(puff.color, puff.color.a * fade))


func _add(puff: Puff) -> void:
    if _puffs.size() >= MAX_PUFFS:
        _puffs.pop_front()
    _puffs.append(puff)
