class_name FoundryDuoLevel
extends Node
## Nivel «Fundición» de «Start», a dos en la misma pantalla (sin dividirla en ventanas): a la izquierda J1 teclea
## el metal puro de cada mena; a la derecha J2 lleva la temperatura al punto de fusión (flechas). Cada uno cumple
## su tutorial por su cuenta; cuando los dos terminan hay una cuenta atrás y empieza el juego, donde dependen uno
## del otro (fuera de rango no se funde). Cada metal por encima del mínimo desbloquea una pieza de cohete.
## Al terminar, ENTER pasa a armar el cohete (con lo desbloqueado en `CampaignState`) o reintenta.
## F5 reinicia y Esc vuelve al menú. Solo compone: las reglas viven en `features/smelter`.


const COUNTDOWN := 3.0

var _layer: CanvasLayer = CanvasLayer.new()
var _root: Control
var _run: SmelterRun
var _duo: SmelterDuo
var _typist: TypistPanel
var _heat: HeatPanel
var _typist_tutorial: HalfTutorial
var _heat_tutorial: HalfTutorial
var _overlay: SmelterOverlay
var _sfx: FoundrySfx
var _typed: String = ""
var _countdown: float = -1.0
var _runs: int = 0
var _last_tick: int = -1


func _ready() -> void:
    add_child(_layer)
    _start()


func _start() -> void:
    _runs += 1
    if _root != null:
        _root.queue_free()
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _layer.add_child(_root)
    _run = SmelterRun.new(GameRandom.new(), CampaignState.ores)
    _duo = SmelterDuo.new(_run, 2026 + _runs)
    _typed = ""
    _countdown = -1.0
    _typist = TypistPanel.new()
    _typist.setup(_run)
    _root.add_child(_typist)
    _heat = HeatPanel.new()
    _heat.position = Vector2(512, 0)
    _heat.setup(_duo.temperature)
    _root.add_child(_heat)
    _typist_tutorial = HalfTutorial.new(HalfTutorial.Mode.TYPIST)
    _root.add_child(_typist_tutorial)
    _heat_tutorial = HalfTutorial.new(HalfTutorial.Mode.HEAT, _duo.temperature)
    _heat_tutorial.position = Vector2(512, 0)
    _root.add_child(_heat_tutorial)
    var strip: UnlockStrip = UnlockStrip.new()
    strip.setup(_run)
    _root.add_child(strip)
    _overlay = SmelterOverlay.new()
    _overlay.run = _run
    _root.add_child(_overlay)
    _sfx = FoundrySfx.new()
    _root.add_child(_sfx)
    _run.group_spawned.connect(func(_added: Array[SmelterRun.Spawn]) -> void: _sfx.play(FoundrySfx.Sound.DROP))
    _run.selected.connect(func(_spawn: SmelterRun.Spawn) -> void: _sfx.play(FoundrySfx.Sound.SELECT, -4.0))
    _run.smelted.connect(func(_spawn: SmelterRun.Spawn) -> void: _sfx.play(FoundrySfx.Sound.COLLECT))
    _run.expired.connect(func(_spawn: SmelterRun.Spawn) -> void: _sfx.play(FoundrySfx.Sound.LOST, -2.0))
    _run.part_unlocked.connect(func(_part: RocketParts.Part) -> void: _sfx.play(FoundrySfx.Sound.GOLD, 2.0))
    _run.finished.connect(_on_finished)


func _process(delta: float) -> void:
    var direction: float = float(Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_DOWN))
    if not _run.is_started:
        if not _heat_tutorial.is_done:
            _duo.practice(delta, direction)
        if _typist_tutorial.is_done and _heat_tutorial.is_done:
            _typist_tutorial.visible = false
            _heat_tutorial.visible = false
            if _countdown < 0.0:
                _countdown = COUNTDOWN
                _sfx.set_furnace(true)
            _countdown -= delta
            var second: int = ceili(_countdown)
            if second != _last_tick and second > 0:
                _last_tick = second
                _sfx.play(FoundrySfx.Sound.TICK)
            if _countdown <= 0.0:
                _run.start()
                _sfx.play(FoundrySfx.Sound.SELECT)
        _overlay.countdown = _countdown
        return
    _overlay.countdown = -1.0
    _duo.step(delta, direction)
    _run.tick(delta)
    _typist.typed = _typed


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
        KEY_F5:
            _start()
        KEY_ENTER, KEY_KP_ENTER:
            if _run.is_finished:
                if _run.has_passed():
                    CampaignState.unlocked_parts.assign(_run.unlocked)
                    SceneRoutes.go_to(get_tree(), Campaign.next_after(SceneRoutes.FOUNDRY_DUO_LEVEL))
                else:
                    _start()
        KEY_BACKSPACE:
            if not _typist_tutorial.is_done:
                _typist_tutorial.backspace()
            else:
                _typed = _typed.left(maxi(0, _typed.length() - 1))
        _:
            if key.keycode >= KEY_A and key.keycode <= KEY_Z:
                _letter(char(key.keycode).to_lower())


func _letter(letter: String) -> void:
    _sfx.play(FoundrySfx.Sound.KEY, -4.0)
    if not _typist_tutorial.is_done:
        var before: String = _typist_tutorial.typed
        _typist_tutorial.type_letter(letter)
        if _typist_tutorial.typed.is_empty() and not _typist_tutorial.is_done and not before.is_empty():
            _sfx.play(FoundrySfx.Sound.WRONG, -4.0)
        return
    if not _run.is_started or _run.is_finished:
        return
    _typed += letter
    if _run.blocked and _run.is_prefix(_typed) and SmelterRun.plain(_typed) in _answers():
        # Palabra correcta pero sin temperatura: se queda escrita hasta que J2 corrija.
        _typist.typed = _typed
        return
    if _run.smelt(_typed):
        _typed = ""
        return
    if _typed.length() > 12 or not _run.is_prefix(_typed):
        _typed = ""
        _typist.wrong = 0.35
        _sfx.play(FoundrySfx.Sound.WRONG, -4.0)


func _answers() -> Array[String]:
    var answers: Array[String] = []
    for spawn: SmelterRun.Spawn in _run.active:
        answers.append(SmelterRun.answer(spawn.ore))
    return answers


func _physics_process(_delta: float) -> void:
    # Si la palabra quedó escrita esperando la temperatura, se funde en cuanto J2 entra en rango.
    if _run.is_started and not _run.is_finished and not _typed.is_empty() and not _run.blocked:
        if _run.smelt(_typed):
            _typed = ""


func _on_finished() -> void:
    _sfx.set_furnace(false)
    _sfx.play(FoundrySfx.Sound.END)
