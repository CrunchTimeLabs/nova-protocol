class_name TapMissionLab
extends MissionLab
## Laboratorio de la misión Tap: el emisor (izquierda, Espacio) crea popups en la pantalla del receptor (derecha, ratón).
## Pantalla dividida por defecto; `-- --lan` para red local.


func _build_session(session_options: SessionOptions) -> MissionSession:
    return MissionSession.build(
            session_options,
            func() -> MatchRules: return TapMatch.new(),
            TapMission.roles(),
            TapMission.ROLE_ORDER,
            )


func _panel_for(client: MatchClient) -> Node:
    if client.role == TapRole.Role.SENDER:
        var sender: SenderPanel = SenderPanel.new()
        sender.setup(client)
        return sender
    var receiver: ReceiverPanel = ReceiverPanel.new()
    receiver.setup(client)
    return receiver


func _title_for(role: int) -> String:
    return "Emisor — Espacio crea popups" if role == TapRole.Role.SENDER else "Receptor — haz clic en los popups"
