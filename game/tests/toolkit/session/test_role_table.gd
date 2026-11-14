extends BaseTest
## Capa 2: un rol solo envía los comandos que se le dieron y solo ve las claves que se le dieron.

const ROLE_A: int = 0
const ROLE_B: int = 1
const KIND_X: int = 10
const KIND_Y: int = 11


var _table: RoleTable


func before_each() -> void:
    _table = RoleTable.new()
    _table.allow(ROLE_A, KIND_X)
    _table.show_key(ROLE_A, "one")
    _table.allow(ROLE_B, KIND_Y)
    _table.show_key(ROLE_B, "two")


func test_commands_by_role() -> void:
    var cases: Array = [
        [ROLE_A, KIND_X, true],
        [ROLE_A, KIND_Y, false],
        [ROLE_B, KIND_X, false],
        [ROLE_B, KIND_Y, true],
        [99, KIND_X, false],
    ]
    for case: Array in cases:
        check_equal(_table.can_send(case[0] as int, case[1] as int), case[2] as bool, "rol %s, comando %s" % [str(case[0]), str(case[1])])


func test_filter_hides_other_roles_keys() -> void:
    var snapshot: Dictionary = {"one": 1, "two": 2, "three": 3}
    check_equal(_table.filter(ROLE_A, snapshot), {"one": 1}, "A solo ve 'one'")
    check_equal(_table.filter(ROLE_B, snapshot), {"two": 2}, "B solo ve 'two'")
    check(_table.filter(99, snapshot).is_empty(), "un rol desconocido no ve nada")
    check_equal(snapshot.size(), 3, "filtrar no modifica el original")
