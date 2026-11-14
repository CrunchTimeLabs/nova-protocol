class_name PipeTile
extends RefCounted
## Una pieza de conducto: forma + rotación. Sabe por qué lados conecta; no sabe de tableros.


enum Shape { STRAIGHT, ELBOW, TEE }
enum Side { NORTH, EAST, SOUTH, WEST }

const SIDE_COUNT: int = 4
const ALL_SIDES_MASK: int = 0b1111
## Lados abiertos de cada forma con rotación 0.
const STRAIGHT_MASK: int = 0b0101   # norte y sur
const ELBOW_MASK: int = 0b0011      # norte y este
const TEE_MASK: int = 0b1011        # norte, este y oeste

## Cuartos de vuelta en sentido horario, siempre 0..3.
var rotation: int
var shape: PipeTile.Shape


func _init(p_shape: PipeTile.Shape, p_rotation: int = 0) -> void:
    shape = p_shape
    rotation = posmod(p_rotation, SIDE_COUNT)


func rotate_by(steps: int) -> void:
    rotation = posmod(rotation + steps, SIDE_COUNT)


func mask() -> int:
    return mask_for(shape, rotation)


func connects(side: PipeTile.Side) -> bool:
    return (mask() & side_bit(side)) != 0


static func side_bit(side: PipeTile.Side) -> int:
    return 1 << side


static func opposite(side: PipeTile.Side) -> PipeTile.Side:
    return ((side + 2) % SIDE_COUNT) as PipeTile.Side


## Desplazamiento de celda al cruzar ese lado.
static func offset(side: PipeTile.Side) -> Vector2i:
    match side:
        Side.NORTH:
            return Vector2i(0, -1)
        Side.EAST:
            return Vector2i(1, 0)
        Side.SOUTH:
            return Vector2i(0, 1)
        Side.WEST:
            return Vector2i(-1, 0)
    return Vector2i.ZERO


static func bit_count(mask_value: int) -> int:
    var count: int = 0
    for side: int in SIDE_COUNT:
        if (mask_value & (1 << side)) != 0:
            count += 1
    return count


static func mask_for(p_shape: PipeTile.Shape, p_rotation: int) -> int:
    var base: int = _base_mask(p_shape)
    var turns: int = posmod(p_rotation, SIDE_COUNT)
    return ((base << turns) | (base >> (SIDE_COUNT - turns))) & ALL_SIDES_MASK


## Una máscara de 2 lados opuestos, 2 adyacentes o 3 lados es una forma real; el resto no.
static func can_form(mask_value: int) -> bool:
    for p_shape: int in Shape.values():
        if rotation_for(p_shape as PipeTile.Shape, mask_value) >= 0:
            return true
    return false


## Forma que produce esa máscara (se asume `can_form`).
static func shape_for(mask_value: int) -> PipeTile.Shape:
    for p_shape: int in Shape.values():
        if rotation_for(p_shape as PipeTile.Shape, mask_value) >= 0:
            return p_shape as PipeTile.Shape
    push_error("PipeTile.shape_for: máscara sin forma (%d)" % mask_value)
    return Shape.STRAIGHT


## Rotación con la que la forma produce la máscara, o -1 si no puede.
static func rotation_for(p_shape: PipeTile.Shape, mask_value: int) -> int:
    for turns: int in SIDE_COUNT:
        if mask_for(p_shape, turns) == mask_value:
            return turns
    return -1


static func _base_mask(p_shape: PipeTile.Shape) -> int:
    match p_shape:
        Shape.STRAIGHT:
            return STRAIGHT_MASK
        Shape.ELBOW:
            return ELBOW_MASK
        Shape.TEE:
            return TEE_MASK
    return 0
