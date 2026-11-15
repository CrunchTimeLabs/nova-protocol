class_name SceneRoutes
extends RefCounted
## Rutas de las escenas y cambio entre ellas, en un solo sitio.


const MENU := "res://scenes/menu.tscn"
const MISSION_LOBBY := "res://scenes/mission_lobby.tscn"
const ORBIT_MISSION := "res://scenes/orbit_mission_lab.tscn"
const CIRCUIT_MISSION := "res://scenes/circuit_mission_lab.tscn"
const EXPEDITION_LEVEL := "res://scenes/expedition_level.tscn"
const METEOR_MISSION := "res://scenes/meteor_mission.tscn"
const CARGO_HOLD_LAB := "res://scenes/cargo_hold_lab.tscn"
const CIRCUIT_LAB := "res://scenes/circuit_lab.tscn"
const COLLECTION_LAB := "res://scenes/collection_lab.tscn"
const COUNTDOWN_LAB := "res://scenes/countdown_lab.tscn"
const DRAG_DROP_LAB := "res://scenes/drag_drop_lab.tscn"
const FOUNDRY_LAB := "res://scenes/foundry_lab.tscn"
const FOUNDRY_DUO_LEVEL := "res://scenes/foundry_duo.tscn"
const FUNDICION_TEMPERATURA := "res://scenes/fundicion_temperatura.tscn"
const MAZE_LAB := "res://scenes/maze_lab.tscn"
const MOVEMENT_LAB := "res://scenes/movement_lab.tscn"
const ORBIT_LAB := "res://scenes/orbit_lab.tscn"
const PRECISION_LAB := "res://scenes/precision_lab.tscn"
const SHIP_LAB := "res://scenes/ship_lab.tscn"
const RESOURCE_METER_LAB := "res://scenes/resource_meter_lab.tscn"
const TRAFFIC_LIGHT_LAB := "res://scenes/traffic_light_lab.tscn"
const WIRING_LAB := "res://scenes/wiring_lab.tscn"


static func go_to(tree: SceneTree, path: String) -> void:
    tree.change_scene_to_file(path)
