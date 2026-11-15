# AGENTS.md — Reglas de Nova Protocol

Guía para cualquier persona o agente de IA que modifique este repositorio. Es breve a propósito: solo lleva las reglas de arquitectura que protegen la reutilización. Todo lo demás es libre.

## 1. Qué es este proyecto

**Nova Protocol** es un juego en **Godot 4.7+** (GDScript tipado y orientado a objetos), construido a partir de las mecánicas del laboratorio `game-mechanics`. El ciclo de juego está descrito en `GAMELOOP_EXPEDICION.md`. Se prioriza que cada mecánica sea **reutilizable y verificable** sobre que el contenido esté pulido.

| Ruta | Qué es |
|---|---|
| `game/` | Raíz del proyecto Godot (`game/project.godot`). Todo el código vive aquí. Los comandos de Godot se ejecutan desde esta carpeta. |
| `GAMELOOP_EXPEDICION.md` | Ciclo de juego de la expedición (referencia de diseño). |
| `local/` | Trabajo local (planes en `local/specs/`); git lo ignora. |

Referencia externa (solo lectura): `../game-mechanics/` (catálogo de mecánicas, `godot4/ARQUITECTURA.md` y `developers/`). Antes de crear una mecánica, mira si ya existe allí y reutiliza su diseño.

## 2. Reglas de arquitectura (las únicas obligatorias)

1. **Toolkit vs. juego.** Si una pieza serviría tal cual en otro juego, va en `toolkit/`; si nombra algo de un juego concreto (naves, misiones, roles…), va en `features/`. `toolkit/` **nunca** importa `features/` ni `app/`. Una mecánica nueva se escribe primero genérica en `toolkit/` y el juego solo la configura.
2. **Dominio sin pantalla.** Las reglas viven en clases `RefCounted` sin nodos, escenas ni `get_tree()`. Un `Node` solo puede estar en una carpeta `view/` (junto al dominio que dibuja) o en `app/` (composición). Las vistas leen estado y emiten señales; nunca deciden reglas.
3. **Lógica y dibujo separados.** Quien define el comportamiento de una pieza no la dibuja, y el dibujo no cambia su estado.
4. **Determinismo.** Todo azar pasa por un generador con semilla (`GameRandom`). Prohibido `randi()`, `randf()` o `randomize()` sueltos en reglas.
5. **Sin singletons ni autoloads.** Las dependencias se pasan por parámetro; un único punto de composición conoce a todas las piezas. Única excepción: servicios de ventana sin reglas de juego (`FullscreenToggle`, pantalla completa).
6. **Tipos explícitos y enums.** Variables, parámetros y retornos con tipo; nada de `:=` sobre valores que Godot no pueda tipar (diccionarios, `.get()`, `InputEvent`). Los conceptos de juego son enums agrupados en la clase a la que pertenecen, no cadenas; un `match` sobre un enum cubre todos sus valores.
7. **Datos, no números mágicos.** Costos, umbrales y balance son constantes con nombre (o datos) en el objeto que los usa.
8. **Flujo explícito.** Estados y transiciones se declaran en un solo sitio y una transición ilegal es un error visible. El orden de un turno o ciclo está escrito en código, de arriba abajo.
9. **Guardado con datos primitivos.** `snapshot()` / `restore()` sobre `Dictionary`; claves de enum por nombre; todo valor leído de JSON se convierte explícitamente (`int(...)`, `float(...)`, `as Enum`); al cambiar el formato se sube `SAVE_VERSION`.
10. **Toda clase de dominio nueva llega con su prueba.** `game/tests/` replica la carpeta de `game/`: la clase `toolkit/core/state_machine.gd` se prueba en `tests/toolkit/core/test_state_machine.gd` (archivo `test_<clase>.gd`, `extends BaseTest`, métodos `test_*`). Sin prueba, la clase no está terminada. Las vistas no se prueban con este ejecutor.
    **Pocas pruebas, que importen:** solo se escribe una prueba si protege una regla del diseño, un invariante (límites, determinismo, transiciones legales, guardado/carga), una integración entre piezas o una regresión. No se prueban getters, constantes ni cableado trivial; los umbrales y tablas van en una sola prueba dirigida por tabla. Pregunta de control: *¿qué regla se rompe si esta prueba falla?*
11. **Lógica primero, vista y laboratorio mínimos para probarla.** Cuando pidan agregar, implementar, crear, construir o términos similares una feature:
    - **Lógica (dominio):** es lo principal. Debe **reutilizar los elementos básicos ya construidos** (`toolkit/`: `StateMachine`, `ResourceMeter`, `GameRandom`, etc.) en lugar de reescribirlos. Si falta un elemento básico, se crea genérico en `toolkit/` (regla 1) y se reutiliza.
    - **Vista y laboratorio:** se pueden crear en el mismo cambio, para poder **jugar y probar la mecánica**. Deben ser **mínimos y flexibles**: nodos y controles por defecto de Godot, formas simples (círculos, cuadrados, texto, botones), sin temas, shaders, partículas, sonido, animaciones ni arte. Reutilizan las vistas genéricas existentes (`toolkit/<área>/view/`) antes de dibujar algo nuevo (regla 12). Siguen la regla 2: solo leen el dominio, emiten señales y delegan acciones; nunca deciden reglas ni inventan un backend propio.
    - **Estética:** un sistema visual elaborado (estilos, efectos, arte) solo se hace si se pide expresamente. El laboratorio existe para probar la mecánica, no para presentarla.
12. **Premisa: reutilizar primero, crear solo lo diferente.** Antes de escribir una clase, se buscan componentes existentes (`toolkit/*/README.md` y `features/*/README.md`, luego el código) y se reutilizan o se extienden por parámetro, contrato o composición. Solo se crea uno nuevo cuando el comportamiento es realmente distinto, y se anota en su README por qué no servía el existente. No se duplica un componente con otro nombre ni se copia código entre áreas: si dos lo necesitan, sube al `toolkit/`.
13. **Cada área y feature tiene su README.** `toolkit/<área>/README.md` y `features/<feature>/README.md` son obligatorios y van en el mismo cambio que la clase (sin README, la feature no está terminada). Es la forma de que otros la reconozcan y la reutilicen sin catálogo global. Formato fijo y breve, estas secciones en este orden:
    1. **Propósito:** una o dos líneas.
    2. **Escenarios:** los `DADO / CUANDO / ENTONCES` del plan, resumidos.
    3. **Qué reutilizar:** clases públicas y para qué sirven.
    4. **Depende de:** áreas del toolkit que usa.
    5. **Cubierto por:** lab, nivel y pruebas que lo ejercitan.

    Solo lo edita quien toca esa carpeta; si cambia el comportamiento, se actualiza en el mismo cambio. Los labs y niveles de `app/` no lo llevan (solo componen).

### Estructura de carpetas (dentro de `game/`)

```
toolkit/<área>/            dominio genérico (sin nodos) + sus contratos y algoritmos
toolkit/<área>/view/       cómo se dibuja ese elemento (genérico)
features/<feature>/        reglas de un juego concreto (una subcarpeta por misión o modo)
features/<feature>/view/   pantallas completas de esa feature
features/shared/           lo específico del juego que usan dos o más features
app/                       composición: menú y rutas de escenas
app/labs/                  un laboratorio por mecánica: prueba UNA mecánica aislada
app/levels/                un nivel: compone VARIAS mecánicas en una experiencia jugable
scenes/                    escenas .tscn mínimas: un nodo raíz con su script
tests/                     espejo del dominio (las vistas no se prueban con el ejecutor)
```

Dependencias en un solo sentido: `app ──► features/<feature> ──► toolkit`; dentro de cada carpeta `view/ ──► dominio`; `tests ──► dominio`. Una feature no importa de otra: lo común va a `features/shared/` (se crea con el primer caso) o sube al toolkit. Nombre de archivo = clase en `snake_case`, un `class_name` por archivo. Toda escena jugable tiene su ruta en `app/scene_routes.gd` y se enlaza desde `app/menu.gd`.

## 3. Estilo

- **Idioma:** nombres de clases, métodos y enums en inglés; textos que ve el jugador en español; comentarios en el idioma que ya use el archivo.
- **Nombres:** `snake_case` funciones y variables, `PascalCase` clases y enums, `MAYUSCULAS` constantes y valores de enum, booleanos con `is_` / `can_` / `has_`, lo interno con `_`. No sombrear funciones globales (`log`, `print`…).
- **Indentación:** respetar la del archivo (hay tabuladores y espacios); nunca mezclarlos en uno.
- **Argumentos:** una llamada o definición con 4 o más argumentos va en vertical: uno por línea, con coma también tras el último, sangrados dos niveles respecto a la sentencia (el `)` de cierre al mismo nivel que los argumentos) y sin espacios al final de línea. GDScript no admite argumentos con nombre; si un valor no se entiende por sí solo, súbelo a una variable local con nombre descriptivo antes de la llamada.

  ```gdscript
  var ghost: DynamicBody = DynamicBody.new(
          ManualThrustController.new(),
          ThrustEngine.new(0.0),
          _sources,
          _position,
          _velocity,
          )
  ```
- **Tamaño:** un archivo, una razón de cambio; si una clase pasa de ~200 líneas, buscar qué extraer.
- **Archivos generados:** `.uid` y `.godot/` los genera el editor; no se editan a mano. Al renombrar un `.gd`, se renombra también su `.uid`.
- Leer los archivos vecinos y copiar su estilo.

## 4. Cómo añadir una mecánica: de abajo hacia arriba, por capas

Se construye por capas y **no se pasa a la siguiente con las pruebas de la actual en rojo**.

| Capa | Qué es | Ejemplos | Prueba mínima antes de seguir |
|---|---|---|---|
| 1. Elemento | un valor o recurso con reglas propias | corazones, energía, combustible | cada uso básico: sumar, gastar, límites, vaciarse, guardado |
| 2. Regla o acción | operación pequeña sobre uno o más elementos | escanear, mantener, certificar | costo, requisito, rechazo cuando no se cumple |
| 3. Entidad o minijuego | lógica que combina varios elementos y reglas | tablero de tuberías | comportamiento con semilla fija (determinista) |
| 4. Orquestador | dueño de las capas anteriores, estados y turnos | sesión de misión | secuencia completa y transiciones ilegales |
| 5. Vista | lee el dominio y emite señales | `view/`, `app/` | revisión estática y ejecución manual |

Pasos:
0. **Plan primero.** Siempre que se pida crear, implementar, construir, añadir, desarrollar, agregar, diseñar, reorganizar, migrar, unificar o quitar una feature, mecánica o parte de la estructura (estos verbos y sus sinónimos, con o sin la palabra "plan"), **no se escribe código antes de tener plan**: se escribe (o se lee, si ya existe) su plan en `local/specs/<NNN>_plan_<feature>.md`. Si piden "implementa X" y X no tiene plan, el primer paso es crear el plan y pedir permiso para implementarlo. Quedan fuera: corregir un error o advertencia, ajustar texto o documentación, y cambios pequeños dentro de un comportamiento que ya existe. Ante la duda, se escribe el plan. `NNN` es un número de 3 dígitos correlativo y `<feature>` va en `snake_case` sin acentos (ej. `003_plan_pipe_board.md`). Un plan tiene **exactamente estas secciones**, en este orden:

   1. **Objetivo.** Breve: propósito, cómo funciona y qué resuelve (sin código).
   2. **Diseño y decisiones.**
      - **Archivos y capas:** tabla `capa | archivo`.
      - **Pruebas:** qué regla o invariante protege cada una (regla 10).
      - **Detalles:** lista corta `DADO <estado> CUANDO <acción> ENTONCES <resultado>` que, leída en orden, da el flujo de la mecánica. Opcional: pseudocódigo o diagrama `mermaid` si aclara.
   3. **Decisiones abiertas y riesgos.** Lista de tareas (`- [ ]`) con cada ambigüedad, su pregunta concreta y, si la hay, la opción por defecto propuesta. Al resolverse se marca `- [x]` y se anota la respuesta.
      - **Enumeradas:** identificador estable `D1`, `D2`… (`- [ ] **D3. Título.** …`); el número no se reutiliza ni se renumera.
      - **Ordenadas:** primero las independientes; después las dependientes, con `Depende de: D#`, detrás de aquellas de las que dependen.

   El encabezado del plan lleva su **estado** (`propuesta`, `en curso`, `hecha`) y se mantiene al día.

   **Al resolver las `D#` (en dos tiempos):**
   1. **Mientras se responde:** cada respuesta solo se marca `[x]` y se anota con su motivo en una línea. Si contradice otra decisión, una regla de este documento o algo ya implementado, se avisa y, si no se puede decidir sin el usuario, se abre una `D#` nueva.
   2. **Cuando ya no quedan preguntas bloqueantes:** se hacen **una sola vez** todos los ajustes de coherencia (archivos, pruebas, detalles, diagramas, otras `D#`, estado), citando la `D#` donde se aplicó.
   3. **Después:** se informa, se pide una revisión más del plan y **se pide permiso para implementar**. No se implementa hasta recibirlo.

   **Puerta de implementación:** una `D#` se puede implementar cuando está `[x]` **y** no entra en conflicto con otras. Se implementa solo lo que se apoya en decisiones resueltas y sin conflicto; lo que dependa de una `D#` pendiente **no se implementa** (ni con valor por defecto) y se informa qué `D#` lo bloquean. Si el usuario confirma expresamente un valor por defecto, cuenta como resuelto. Si aparece una duda nueva al implementar, se añade como `D#`, se detiene lo que dependa de ella y se pregunta.
1. Con las decisiones resueltas, **buscar primero qué existe** (README de `toolkit/*` y `features/*`, regla 12), reutilizarlo y nombrar la mecánica con vocabulario genérico; decidir su capa de código (regla 1) y de construcción (tabla).
2. Modelar con enums y constantes propias; dominio primero, sin nodos.
3. Escribir `tests/<ruta espejo>/test_<clase>.gd` junto con la clase: primero los usos mínimos, luego límites y rechazos.
4. Conectarla desde su dueño de forma explícita (método, estado o señal), sin bus global.
5. Si añade estado, ampliar `snapshot()` / `restore()` y probar el viaje por JSON.
6. Vista y laboratorio mínimos para probar la mecánica (regla 11): pequeños, con controles por defecto, solo leen el dominio. Estética elaborada solo si se pidió.
7. Escribir el README del área o feature (regla 13). Registrar escena y menú si hay vista nueva. **No se actualiza ningún markdown global** (README general, índices, catálogos de features, `DIAGRAMAS.md`): es un proyecto colaborativo y esos archivos compartidos generan conflictos de merge. Escribir el `README.md` de la feature o área (regla 13), que nadie más edita.

**Quitar una mecánica o nivel:** se borra su carpeta (con `view/`), su espejo en `tests/`, su laboratorio o nivel en `app/` y su escena, su ruta y su botón del menú; antes se revisa que nada más la use.

## 5. Verificación y honestidad

- Godot 4.7.2 está en `~/bin/godot` (no en el `PATH` de la shell de los agentes): el dominio y el toolkit se pueden ejecutar con el ejecutor de pruebas; las vistas y escenas no se ven sin el editor. No afirmar "funciona" sobre GDScript que no se ejecutó; decir "no ejecutado" y qué se comprobó de forma estática (inferencia `:=` sobre `Variant`, referencias circulares, `class_name` duplicados, miembros o rutas `res://` inexistentes, `.uid` huérfanos, mezcla de tabuladores y espacios, `match` incompleto).
- Si el usuario pega un error del editor, corregir **ese** error y buscar el mismo patrón en el resto del código.
- Desde `game/`: `~/bin/godot --headless --import` una vez y luego `~/bin/godot --headless -s tests/run_all.gd` (0 si todo pasa; admite una carpeta o archivo tras `--`). Al exportar, excluir `tests/*` en el preset.
- Informar con precisión: qué se cambió, qué se comprobó, qué quedó sin comprobar y qué riesgo conserva.

## 6. Flujo de trabajo

- Cambios pequeños y verificables; no refactorizar lo que no se pidió.
- **Evitar markdown compartido que todos editan:** no mantener catálogos, listas o resúmenes globales de features (README general, índices, tablas de estado). La documentación de una feature vive en su propia carpeta; los documentos globales (`AGENTS.md`, `GAMELOOP_EXPEDICION.md`) solo se tocan cuando cambia una regla o el diseño del ciclo de juego, en un cambio aparte.
- No modificar `../game-mechanics/` (es referencia).
- `local/` es del trabajo local y git lo ignora; lo que deba perdurar va en la documentación versionada.
- No hacer commits ni push salvo que se pida; si se pide, seguir el estilo de `git log`.
- No borrar archivos que no se crearon en la tarea sin avisar; antes de borrar o sobrescribir, mirar qué hay.
- Ante una ambigüedad real (cambia el alcance o hay que descartar trabajo), preguntar una vez; si hay un valor por defecto razonable, usarlo y decirlo.
- Todo trabajo que cree, cambie o quite una feature, mecánica o estructura pasa por plan (sección 4, paso 0), también si el usuario solo dice "hazlo". Las decisiones abiertas de un plan **no** admiten "valor por defecto razonable": se preguntan las que bloquean lo pedido y se implementa solo lo resuelto y sin conflicto, citándolo por su `D#`.
