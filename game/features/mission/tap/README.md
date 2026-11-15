# mission/tap

> **Candidato a remover:** no tiene ruta ni entrada en el menú, y el nivel «Fundición dúo» (`app/levels/foundry_duo_level.gd`) cubre una señal entre lados con otras mecánicas. Se deja hasta decidirlo.

## Propósito
Misión mínima para dos jugadores en pantalla dividida: el emisor pide popups y el receptor los pulsa antes de que caduquen. Dura 20 s.

## Escenarios
- DADO el emisor CUANDO pulsa Espacio ENTONCES aparece un popup en un punto aleatorio (con semilla) del lado del receptor, si hay cupo (`TapMatch`).
- DADO un popup vivo CUANDO el receptor le hace clic ENTONCES suma un acierto una sola vez; si caduca, desaparece sin restar.
- DADO un rol CUANDO envía un comando del otro rol ENTONCES se rechaza; el emisor solo ve el tiempo (`TapMission.roles()`).
- DADO que pasan 20 s ENTONCES la partida termina y rechaza todo comando.

## Qué reutilizar
- `TapMatch` (reglas), `TapMission` (roles), `TapCommand`, `TapRole`; vistas `SenderPanel`, `ReceiverPanel`, `TapMissionLab`.
- Patrón para otra misión de dos roles: copiar esta carpeta (`MatchRules` + `RoleTable`).

## Depende de
`toolkit/session`, `toolkit/time` (`ExpiringSet`), `toolkit/core` (`GameRandom`), `features/mission` (`MissionSession`, `MissionLab`, `SplitScreen`).

## Cubierto por
Escena `tap_mission_lab` (botón «Tap» del menú); `tests/features/mission/tap/`.
