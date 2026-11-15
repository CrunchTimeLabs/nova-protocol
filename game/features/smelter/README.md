# smelter

Fundición de la campaña a dos, sin pantalla dividida.

**Jugadores:**

- J1 escribe el elemento puro de cada mena. Por ejemplo, de la bauxita sale el aluminio. Las tildes no hacen falta.
- J2 lleva la temperatura al punto de fusión de esa mena con las flechas. Si se mantiene la tecla, la aguja acelera.

**Reglas:**

- Fuera de rango, J1 no puede fundir.
- Las menas salen del inventario del laberinto (`CampaignState.ores`).
- El nivel dura 45 s, que solo empiezan a correr cuando los dos terminan su tutorial.
- Cada metal por encima de `MINIMUM` desbloquea la siguiente pieza de `RocketParts.UNLOCK_ORDER`.

**Archivos:**

- Reglas: `SmelterRun` y `SmelterDuo`. Este último usa `TemperatureState`, con el `player_rate` nuevo.
- Vista: `view/`, que incluye:
  - las dos mitades;
  - los tutoriales;
  - la franja de piezas;
  - el resumen.
- Nivel: `app/levels/foundry_duo_level.gd`.
- Pruebas: `tests/features/smelter/`.
