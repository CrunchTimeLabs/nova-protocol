class_name SceneRoutes
extends RefCounted
## Rutas de las escenas y cambio entre ellas, en un solo sitio.


const MENU := "res://scenes/menu.tscn"
const CARGO_HOLD_LAB := "res://scenes/cargo_hold_lab.tscn"
const CIRCUIT_LAB := "res://scenes/circuit_lab.tscn"
const COUNTDOWN_LAB := "res://scenes/countdown_lab.tscn"
const DRAG_DROP_LAB := "res://scenes/drag_drop_lab.tscn"
const MAZE_LAB := "res://scenes/maze_lab.tscn"
const MOVEMENT_LAB := "res://scenes/movement_lab.tscn"
const ORBIT_LAB := "res://scenes/orbit_lab.tscn"
const PRECISION_LAB := "res://scenes/precision_lab.tscn"
const RESOURCE_METER_LAB := "res://scenes/resource_meter_lab.tscn"
const TRAFFIC_LIGHT_LAB := "res://scenes/traffic_light_lab.tscn"
const WIRING_LAB := "res://scenes/wiring_lab.tscn"


static func go_to(tree: SceneTree, path: String) -> void:
    tree.change_scene_to_file(path)
