# net

## Propósito
Transportes de mensajes para las partidas: en memoria, ENet local y un decorador que simula pérdida.

## Escenarios
- DADO dos transportes locales CUANDO uno envía ENTONCES el otro recibe el mensaje codificado como en red (`LocalTransport`).
- DADO un transporte con pérdida CUANDO envía ENTONCES puede perder, duplicar o retrasar con semilla (`LossyTransport`).
- DADO un `Dictionary` primitivo CUANDO se codifica ENTONCES se recupera igual y nunca se decodifican objetos (`MessageCodec`).

## Qué reutilizar
- `LocalHub` + `LocalTransport`, `ENetTransport`, `LossyTransport`, `MessageCodec`.

## Depende de
Contrato `SessionTransport` (`toolkit/session`).

## Cubierto por
`tests/toolkit/net/` (LAN con ENet sin probar).
