class_name ShaderBackdrop
extends Control
## Fondo con shaders: nebulosa a pantalla completa y un planeta lejano. Solo asigna parámetros a los shaders; no tiene lógica.


const NEBULA: Shader = preload("res://toolkit/fx/view/nebula.gdshader")
const PLANET: Shader = preload("res://toolkit/fx/view/planet.gdshader")
## Diámetro del planeta como fracción del alto y posición de su centro como fracción del recuadro.
const PLANET_HEIGHT_RATIO: float = 0.7
const PLANET_CENTER: Vector2 = Vector2(0.8, 0.35)

var _nebula: ColorRect = ColorRect.new()
var _planet: ColorRect = ColorRect.new()


func _init() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _nebula.material = _material(NEBULA)
    _planet.material = _material(PLANET)
    for rect: ColorRect in [_nebula, _planet]:
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(rect)
    resized.connect(_layout)


func _material(shader: Shader) -> ShaderMaterial:
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = shader
    return material


func _layout() -> void:
    _nebula.size = size
    var side: float = size.y * PLANET_HEIGHT_RATIO
    _planet.size = Vector2(side, side)
    _planet.position = size * PLANET_CENTER - _planet.size * 0.5
