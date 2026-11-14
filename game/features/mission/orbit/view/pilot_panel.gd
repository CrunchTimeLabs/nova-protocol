class_name PilotPanel
extends Node2D
## Vista del piloto: su laboratorio de movimiento (flechas en pantalla dividida; WASD o flechas en LAN). Sus flechas se traducen a una orden relativa al rumbo (OrbitMission.thrust_from_arrows) y se envía
## al anfitrión al cambiar y como latido. Ve el combustible, no la órbita.


const START_POSITION: Vector2 = Vector2(240, 220)
const HEARTBEAT_SECONDS: float = 0.25
const HUD_MARGIN: Vector2 = Vector2(12, 8)

var _client: MatchClient
var _input: InputSource
var _controller: ManualController = ManualController.new()
var _body: MovementBody = MovementBody.new(_controller, MovementProfile.snappy(), START_POSITION)
var _heartbeat: CommandHeartbeat = CommandHeartbeat.new(HEARTBEAT_SECONDS)
var _hud: Label = Label.new()


func setup(client: MatchClient, input: InputSource) -> void:
    _client = client
    _input = input
    var square: SquareView = SquareView.new()
    square.setup(_body)
    add_child(square)
    _hud.position = HUD_MARGIN
    add_child(_hud)


func _physics_process(delta: float) -> void:
    var direction: Vector2 = _input.read_direction()
    _controller.set_direction(direction)
    _body.step(delta)
    var thrust: Vector2 = OrbitMission.thrust_from_arrows(direction)
    var payload: Dictionary = {"x": thrust.x, "y": thrust.y}
    if _heartbeat.should_send(payload, delta):
        _client.send_command(OrbitCommand.Kind.SET_THRUST, payload)
    var fuel: OrbitMatch = _client.replica as OrbitMatch
    _hud.text = "Combustible: %d%%\n→ adelante · ← frenar · ↓ hacia dentro · ↑ hacia fuera" % roundi(fuel.fuel_ratio() * 100.0)
