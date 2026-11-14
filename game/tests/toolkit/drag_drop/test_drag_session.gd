extends BaseTest
## Capa 2 (regla): transiciones legales del arrastre y rechazo cuando la regla lo decide.


var _session: DragSession


func before_each() -> void:
    _session = DragSession.new(func(payload: Variant, from_zone: StringName, to_zone: StringName) -> bool:
        return from_zone != to_zone and int(payload) > 0
    )


func test_drop_without_drag_does_nothing() -> void:
    check_equal(_session.drop(&"ship"), DragSession.Result.NOT_DRAGGING, "soltar sin arrastrar")
    check_equal(_session.cancel(), DragSession.Result.NOT_DRAGGING, "cancelar sin arrastrar")


func test_rule_decides_accept_or_reject_and_ends_the_drag() -> void:
    _session.begin(5, &"ground")
    check(_session.is_dragging(), "arrastrando tras begin")
    check_equal(_session.drop(&"ship"), DragSession.Result.ACCEPTED, "zona distinta y carga válida")
    check(not _session.is_dragging(), "el soltado termina el arrastre")
    _session.begin(5, &"ground")
    check_equal(_session.drop(&"ground"), DragSession.Result.REJECTED, "misma zona: la regla rechaza")
    check(not _session.is_dragging(), "un rechazo también termina el arrastre")


func test_cancel_and_second_begin() -> void:
    _session.begin(1, &"ground")
    check(not _session.begin(2, &"ship"), "no se puede empezar otro arrastre a medias")
    check_equal(_session.payload, 1, "el arrastre original no cambia")
    check_equal(_session.cancel(), DragSession.Result.CANCELLED, "cancelar")
    check(not _session.is_dragging(), "tras cancelar ya no arrastra")


func test_dropped_signal_carries_what_was_released() -> void:
    var seen: Array = []
    _session.dropped.connect(func(result: DragSession.Result, payload: Variant, from_zone: StringName, to_zone: StringName) -> void:
        seen.append([result, payload, from_zone, to_zone])
    )
    _session.begin(7, &"ground")
    _session.drop(&"ship")
    check_equal(seen, [[DragSession.Result.ACCEPTED, 7, &"ground", &"ship"]], "la señal informa resultado, carga y zonas")
