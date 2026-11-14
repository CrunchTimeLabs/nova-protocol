class_name OrbitMissionLab
extends MissionLab
## Misión de órbita: el piloto acelera en su laboratorio de movimiento y la estación ve el efecto en la órbita.
## Pantalla dividida por defecto (estación a la izquierda, piloto a la derecha); `-- --lan` para red local.


func _build_session(session_options: SessionOptions) -> MissionSession:
    return MissionSession.build(
            session_options,
            func() -> MatchRules: return OrbitMatch.new(),
            OrbitMission.roles(),
            OrbitMission.ROLE_ORDER,
            )


func _panel_for(client: MatchClient) -> Node:
    if client.role == OrbitRole.Role.PILOT:
        var pilot: PilotPanel = PilotPanel.new()
        # Con un solo teclado (pantalla dividida) el piloto usa las flechas; la estación usa Espacio.
        var scheme: InputSource.Scheme = InputSource.Scheme.ARROWS if options.mode == SessionOptions.Mode.SPLIT_SCREEN else InputSource.Scheme.BOTH
        pilot.setup(client, InputSource.new(scheme))
        return pilot
    var station: StationPanel = StationPanel.new()
    station.setup(client)
    return station


func _title_for(role: int) -> String:
    return "Piloto — laboratorio de movimiento" if role == OrbitRole.Role.PILOT else "Estación — laboratorio de órbitas"
