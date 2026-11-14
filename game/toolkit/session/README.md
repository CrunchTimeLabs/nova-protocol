# session

## Propósito
Partida compartida con anfitrión autoritativo: los jugadores envían comandos, el anfitrión los valida por rol y difunde instantáneas.

## Escenarios
- DADO un rol CUANDO envía un comando que no le corresponde ENTONCES el anfitrión lo rechaza con motivo (`RoleTable`, `MatchHost`).
- DADO un comando válido CUANDO llega al anfitrión ENTONCES se aplica a las reglas y los clientes reciben la instantánea (`MatchClient`).
- DADO un estado continuo (acelerador) CUANDO cambia o pasa un intervalo ENTONCES se reenvía (`CommandHeartbeat`).

## Qué reutilizar
- `MatchHost`, `MatchClient`, `MatchProtocol`, contratos `MatchRules` y `SessionTransport`, `RoleTable`, `Command`, `CommandHeartbeat`.

## Depende de
`toolkit/net` (transportes).

## Cubierto por
Lab `Split screen` (`features/mission`); `tests/toolkit/session/`.
