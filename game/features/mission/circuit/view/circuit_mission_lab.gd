class_name CircuitMissionLab
extends MissionLab
## Misión del circuito: un jugador solo gira piezas y el otro solo las intercambia, sobre el mismo tablero.
## Pantalla dividida por defecto; `-- --lan` para red local.


func _build_session(session_options: SessionOptions) -> MissionSession:
    return MissionSession.build(
            session_options,
            func() -> MatchRules: return CircuitMission.new_match(),
            CircuitMission.roles(),
            CircuitMission.ROLE_ORDER,
            )


func _panel_for(client: MatchClient) -> Node:
    var panel: CircuitPanel = CircuitPanel.new()
    panel.setup(client)
    return panel


func _title_for(role: int) -> String:
    return "Rotador" if role == CircuitRole.Role.ROTATOR else "Intercambiador"
